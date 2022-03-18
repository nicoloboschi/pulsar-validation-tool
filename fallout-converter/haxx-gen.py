#!/usr/bin/python3

import argparse, yaml, os, re


home_dir = os.path.abspath(os.path.dirname(__file__))
scripts_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "scripts"))

def file_to_str(filename):
    path = os.path.join(os.path.dirname(__file__), filename)
    with open(path, "r") as stream:
        return stream.read()


def replaces_files_refs_in_text(files_map, text): 
    
    pattern = re.compile('.*?\${(.+)}.*?')
    matches = pattern.findall(text)
    for m in matches:
        if m.startswith("script:"):
            filename = m[7:]
            mapped = files_map.get(filename, "")
            if not mapped:
                raise Exception("script %s not found" % filename) 
            text = text.replace(
                    f'${{{m}}}', mapped
                )
    return text



def replace_placeholders(value, placeholders = {}): 
    
    pattern = re.compile('.*?\${(\w+)}.*?')
    result_list = []
    for l in value.split("\n"):
        to_append = l
        matches = pattern.findall(l)
        if matches:
            match = matches[0]
            if match in ["phases", "local_files", "remote_files", "pulsar_values"]:
                new_value = placeholders.get(match, "")
                if not new_value:
                    raise Exception("Variable %s not found. Aborting" % match)
            else:
                new_value = os.environ.get(match, None)
                if not new_value:
                    raise Exception("Variable %s not found. Aborting" % match)
            if "\n" in new_value:
                prev_chars_count = len(l.split(match)[0])    
                new_value_multiline = ""
                prev = " " * (prev_chars_count - 2)
                first_subline = True
                for vline in new_value.split("\n"):
                    if not first_subline:
                        new_value_multiline += "\n" + prev + vline
                    else:
                        first_subline = False
                        new_value_multiline += vline
            else:
                new_value_multiline = new_value

            
            to_append = l.replace(
                f'${{{match}}}', new_value_multiline
            )
            
            
            
        result_list.append(to_append)
    return "\n".join(result_list)

def build_service_phase(container_def, mapped_files, common_env):
    name = container_def["name"]
    image = container_def["image"]
    command = container_def.get("command")
    env = container_def.get("env", [])
    mounts = container_def.get("mounts", [])
    ports = container_def.get("ports", [])
    
    if len(ports) > 0:
        type = "deployment"
    else:
        type = "job"

    local_files = []
    phases = []
    remote_files = []

    local_file_name = "%s_setup_file.yaml" % name
    if type == "job":
        phase = {}
        phase[name] = {

                "module": "kubernetes_job", 
                "properties": { 
                    "capture_container_logs": True,
                    "namespace": "{{helmchart.namespace}}", 
                    "manifest": "<<file:%s>>" % local_file_name
                }
        }
        phases.append(phase)
        
        local_file = {
            "path": local_file_name,
            "yaml": {
                "apiVersion": "batch/v1",
                "kind": "Job",
                "metadata": {
                    "name": name
                },
                "spec": {
                    "template": {
                        "spec": {
                            "containers": [
                                {
                                "name": name,
                                "image": replace_placeholders(image),
                                "command": replace_placeholders(command).split(" ")
                                }
                            ],
                            "restartPolicy": "Never"
                        }
                        
                    }
                }
                
            }

        }

        if len(env) > 0:
            local_file["yaml"]["spec"]["template"]["spec"]["containers"][0]["env"] = env

        if len(mounts) > 0:
            mounts_arr = []
            volumes = []
            index = 0
            
            for m in mounts:
                # name must be a valid config-map filename
                hash_str = "mount-%s-%d" % (name, index)
                mounts_arr.append({
                    "name": hash_str,
                    "mountPath": "/" + hash_str
                })
                volumes.append({
                    "name": hash_str,
                    "configMap": {
                        "name": hash_str
                    }
                })
                real_path = os.path.join(scripts_dir, m)
                
                remote_files.append({
                    "path": hash_str,
                    "namespace": "{{helmchart.namespace}}",
                    "data": file_to_str(real_path)
                })

                mapped_files[m] = "/%s/%s" % (hash_str, hash_str)
                index += 1



            local_file["yaml"]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"] = mounts_arr
            local_file["yaml"]["spec"]["template"]["spec"]["volumes"] = volumes

        local_files.append(local_file)
    else:
        service_file_name = "%s-%s" % ("service", local_file_name)
        depl_file_name = "%s-%s" % ("depl", local_file_name)
        service_phase = {}
        service_phase["service-%s" % name] = {
                "module": "kubectl", 
                "properties": { 
                    "namespace": "{{helmchart.namespace}}", 
                    "command": "create -f <<file:%s>>" % service_file_name
                }
        }
        depl_phase = {}
        depl_phase["deploy-%s" % name] = {
                "module": "kubectl", 
                "properties": { 
                    "namespace": "{{helmchart.namespace}}", 
                    "command": "create -f <<file:%s>>" % depl_file_name
                }
        }
        phases.append(service_phase)
        phases.append(depl_phase)


        hostname = "service-%s" % name
        common_env.append({"name": "HOSTNAME_%s" % name.upper(), "value": hostname})

        service_local_file = {
            "path": service_file_name,
            "yaml": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "name": hostname
                },
                "spec": {
                    "selector": {
                        "app": name,
                    },
                    "type" : "LoadBalancer"               
                }
            }
        }

        ports_arr = []
        for p in ports: 
            port_str = str(p)
            ports_arr.append({
                "name": "p" + port_str,
                "port": p,
                "targetPort": p,
            })
        service_local_file["yaml"]["spec"]["ports"] = ports_arr

        local_files.append(service_local_file)


        depl_local_file = {
            "path": depl_file_name,
            "yaml": {
                "apiVersion": "apps/v1",
                "kind": "Deployment",
                "metadata": {
                    "name": "deploy-%s" % name
                },
                "spec": {
                    "selector": {
                        "matchLabels": {
                            "app": name
                        }
                    },
                    "replicas" : 1,
                    "template" : {
                        "metadata": {
                            "labels": {
                                "app": name
                            }
                        },
                        "spec": {
                            "containers": [{
                                "name": name,
                                "image": replace_placeholders(image),
                            }]
                        }

                    }
                }
            }
        }
        if len(env) > 0:
            depl_local_file["yaml"]["spec"]["template"]["spec"]["containers"][0]["env"] = env

        ports_arr = []
        for port in ports:
            ports_arr.append({
                "containerPort": port
            })
        depl_local_file["yaml"]["spec"]["template"]["spec"]["containers"][0]["ports"] = ports_arr
        local_files.append(depl_local_file)


    return local_files, remote_files, phases


def str_presenter(dumper, data):
    if len(data.splitlines()) > 1:  # check for multiline string
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')

    return dumper.represent_scalar('tag:yaml.org,2002:str', data)


def run(test_file):
    test = yaml.safe_load(file_to_str(test_file))
    template_file = os.path.join(home_dir, test["template"])
    values_file = os.path.join(home_dir, test["pulsar_values"])

    local_files = []
    remote_files = []
    phases = []
    containers = test["setup"]["containers"]

    files_map = {}
    common_env = []
    for c in containers:

        container_local_files, container_remote_files, container_phases = build_service_phase(c, files_map, common_env)
        local_files.extend(container_local_files)
        remote_files.extend(container_remote_files)
        phases.extend(container_phases)


    for remote_file in remote_files:
        remote_file["data"] = replaces_files_refs_in_text(files_map, remote_file["data"])

    for local_file in local_files:
        index = 0
        if local_file["yaml"]["kind"] == "Job":
            containers_spec = local_file["yaml"]["spec"]["template"]["spec"]["containers"]
            for c in containers_spec:
                # replace command file refs
                if containers_spec[index].get("command", None):
                    command_arr = containers_spec[index]["command"]
                    new_command_arr = []
                    for command in command_arr:
                        new_command_arr.append(replaces_files_refs_in_text(files_map, command))
                    c["command"] = new_command_arr
                # inject common env
                env_vars = containers_spec[index].get("env", [])
                env_vars.extend(common_env)
                containers_spec[index]["env"] = env_vars
            
                index += 1


    yaml.add_representer(str, str_presenter)

    template = file_to_str(template_file)
    pulsar_values = file_to_str(values_file)
    res = replace_placeholders(template, {
        "local_files": yaml.dump(local_files), 
        "remote_files": yaml.dump(remote_files),
        "phases": yaml.dump(phases),
        "pulsar_values": pulsar_values
        })

    return res

if __name__ == "__main__":


    parser = argparse.ArgumentParser()
    parser.add_argument("test", help="Test file")
    cwd = os.getcwd()
    
    args = parser.parse_args()
    result = run(os.path.join(cwd, args.test))
    print(result)
