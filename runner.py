#!/usr/bin/python3

import argparse, yaml, os, time, re, sys, shutil, subprocess

def run_bash(command_list, **params): 
    capture_output = params.get("capture_output", False)
    cwd = params.get("cwd", None)
    print(*command_list, sep=" ")
    result = subprocess.run(command_list,
        capture_output=capture_output, text=True, cwd=cwd)
    
    if result.returncode != 0:
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr)
        fail = params.get("fail_if_error", True)
        if fail: 
            raise Exception("Bash command failed, rc: %s\nstderr: %s " % (str(result.returncode), result.stderr))
        else:
            return None
    if capture_output:
        return result
    return None


tmp_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "tmp"))
scripts_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "scripts"))

def file_to_str(filename):
    path = os.path.join(os.path.dirname(__file__), filename)
    with open(path, "r") as stream:
        return stream.read()

def print_phase(phase):
    print("\n\n============================================================================\n %s \n============================================================================\n" % phase)

def convert_yaml(file): 
    with open(file, "r") as stream:
        value = stream.read()
        #conf =  yaml.safe_load(stream)
    pattern = re.compile('.*?\${(\w+)}.*?')
    match = pattern.findall(value)
    if match:
        full_value = value
        for g in match:
            new_value = os.environ.get(g, None)
            if not new_value:
                raise Exception("Variable %s not found. Aborting" % g)
            full_value = full_value.replace(
                f'${{{g}}}', new_value
            )
        return yaml.safe_load(full_value)
    return yaml.safe_load(value)


def get_mounted_path_for_file(file):
    return "/%s" % os.path.basename(file)

def resolve_script_file_ref(filename):
    path = os.path.join(scripts_dir, filename)
    if not os.path.exists(path):
        raise Exception("Script path not found: %s" % path)
    return path

def resolve_refs_in_text(text, resolver): 
    
    pattern = re.compile('.*?\${(.+)}.*?')
    matches = pattern.findall(text)
    for m in matches:
        if m.startswith("script:"):
            filename = m[7:]
            text = text.replace(
                    f'${{{m}}}', resolver(filename)
                )
    return text

def compose_docker_run_command(name, image, **params):
    ports = params.get("ports", [])
    network = params.get("network", "bridge")
    hostname = params.get("hostname", name)
    env = params.get("env", [])
    bash_command = params.get("command")
    mounts = params.get("mounts", [])

    cmd = [
        "docker",
        "run",
        "--rm",
        "-d",
        "-t",
        "--name",
        name,
        "--network",
        network,
        "--hostname",
        hostname,
        "-v",
        "%s/.m2/repository:/maven_home" % (os.environ.get("HOME")),
        "-e",
        "M2_HOME_HOST=/maven_home",
    ]
    if ports: 
        for p in ports:
            cmd.append("-p")
            cmd.append("%s:%s" % (p, p))

    for e in env:
        cmd.append("-e")
        cmd.append("%s=%s" % (e["name"], e["value"]))
    
    for mount in mounts: 
        path = resolve_refs_in_text(mount, resolve_script_file_ref)
        cmd.append("-v")
        cmd.append("%s:%s" % (path, get_mounted_path_for_file(path)))

    cmd.append(image)
    if bash_command:
        cmd.append("/bin/bash")
        cmd.append("-c")
        cmd.append(bash_command)
    return cmd

def cleanup_docker(containers, networks):
    for c in containers:
        if c:
            run_bash(["docker", "rm", "-f", c], fail_if_error=False)
    
    for network in networks:
        if not network or network == "bridge":
            continue
        run_bash(["docker", "network", "rm", network], fail_if_error=False)


def execute_tests_in_container(container_name, tests):
    
    if not tests or len(tests) == 0:
        return

    to_run = []
    for testname in tests:
        # absolute path: */scripts/testfilename
        t = resolve_refs_in_text(testname, resolve_script_file_ref)

        content = file_to_str(t)
        content = resolve_refs_in_text(content, get_mounted_path_for_file)
        

        copied_path = resolve_refs_in_text(testname, lambda path: os.path.join(tmp_dir, path))
        
        print("writing to copied path: %s" % copied_path)
        os.makedirs(os.path.dirname(copied_path), exist_ok=True)
        with open(os.open(copied_path, os.O_CREAT | os.O_WRONLY, 0o777), "w") as text_file:
            text_file.write(content)
        mount_path = get_mounted_path_for_file(t)
        
        cmd_copy = ["docker", "cp", copied_path, "%s:%s" % (container_name, mount_path)]
        run_bash(cmd_copy)

        to_run.append(mount_path)
   

    cmd_entrypoint = " && ".join(to_run)
    
    cmd_exec = ["docker", "exec", "-it", container_name, "/bin/bash", "-ec", cmd_entrypoint]
    print_phase("Executing tests for container %s" % container_name)
    run_bash(cmd_exec)

def run_local_mode(containers, tests, cleanup, print_logs):
    seed = round(time.time())
    network_name = "piv-net-%s" % seed
    running_containers = {}
    try:
        network = "bridge"
        if containers and len(containers) > 0:
            run_bash(["docker", "network", "create", network_name])
            network = network_name

        common_env = []
        
        if containers:
            for container in containers:
                
                if not container["name"]:
                    raise Exception("container 'name' is required")
                hostname = container["name"]
                common_env.append({"name": "HOSTNAME_%s" % (hostname.upper()), "value": hostname})

            for container in containers:
                name = "piv-%s-%s" % (container["name"], seed)
                all_env = container.get("env", [])
                all_env.extend(common_env)
                cmd = compose_docker_run_command(name, 
                    container["image"], 
                    hostname=container["name"], 
                    ports=container.get("ports", []), 
                    network=network, 
                    env=all_env, 
                    mounts=container.get("mounts", []),
                    command=container.get("command"))
                print_phase("Setup container %s" % container["name"])
                run_bash(cmd)
                running_containers[container["name"]] = name
            
        for name, tests in tests.items():
            actual_name = running_containers[name]

            execute_tests_in_container(actual_name, tests)
                
        print_phase("Tests passed!")
        if cleanup: 
            cleanup_docker(running_containers.values(), [network])
    except Exception as e:
        print_phase("Tests stopped!")
        if print_logs:
            for container in running_containers.values():
                logs = run_bash(["docker", "logs", container], fail_if_error=False, capture_output = True)
                if logs:
                    print_phase("Docker logs for container %s" % container)
                    print("\n".join(logs.stdout.split("\n")[20:]))
        
        if cleanup:
            cleanup_docker(running_containers.values(), [network])
        raise e
        
 

def do_hard_cleanup():
    print_phase("Cleanup - All")
    containers = []
    networks = []
    containers_str = run_bash(["docker", "container", "ls", "-q", "--filter", "name=piv"], capture_output = True).stdout
    if containers_str:
        containers = containers_str.split("\n")

    networks_str = run_bash(["docker", "network", "ls", "-q", "--filter", "name=piv"], capture_output = True).stdout
    if networks_str:
        networks = networks_str.split("\n")
    
    cleanup_docker(containers, networks)

    if os.path.exists(tmp_dir):
        shutil.rmtree(tmp_dir)
    os.mkdir(tmp_dir)
       


def run_from_file(file, cleanup, print_logs):
    definition = convert_yaml(file)
    print(definition)

    target = definition["target"]
    if target == "local-docker":
        run_local_mode(definition["setup"].get("containers", []), definition["tests"], cleanup, print_logs)
    elif target == "fallout":
        pass

if __name__ == "__main__":


    parser = argparse.ArgumentParser()
    parser.add_argument("cmd", help="What to do", choices=["run", "cleanup"])
    parser.add_argument("-f", help="Input file", required=True)
    parser.add_argument("-d", type=bool, default = False, nargs='?', help="Debug. Do not cleanup docker and networks")
    parser.add_argument("-l", type=bool, default = False, nargs='?', help="Print logs on failure")

    args = parser.parse_args()


    do_hard_cleanup()

    if args.cmd == "cleanup":
        exit(0)

    run_from_file(args.f, not args.d, args.l)
  


    # target: docker,k8s,fallout
    # setup-pulsar: docker-run, yaml for fallout
    # setup-altro: docker-run
    # tests: files to run in a container, K8s Job









