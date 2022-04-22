#!/usr/bin/python3

import subprocess, os, time, argparse, shutil, json, sys
import urllib.request
import tarfile

def run_bash(command_list, **params): 
    capture_output = params.get("capture_output", False)
    cwd = params.get("cwd", None)
    print("Running following commands from %s:" % cwd)
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

def print_info(dir, url, version, project):
  
    value = json.dumps({"url": url,"version": version, "project": project })
    with open(os.path.join(dir, "info"), "w") as s:
        s.write(value)

def read_info(dir, if_empty):
    path = os.path.join(dir, "info")
    if not os.path.isfile(path):
        return if_empty
    with open(path, "r") as s:
        return json.loads(s.read())

def update_status(dir, status):
    print("update status: %s" % status)
    with open(os.path.join(dir, "status"), "w") as s:
        s.write(status)

def read_status(dir, if_empty):
    path = os.path.join(dir, "status")
    if not os.path.isfile(path):
        return if_empty
    with open(path, "r") as s:
        return s.read()
        

def download_file(url, output_filename):
    print("downloading %s to %s" % (url, output_filename))
    urllib.request.urlretrieve(url, output_filename)
    urllib.request.urlretrieve(url + ".sha512", output_filename + ".sha512")
    urllib.request.urlretrieve(url + ".asc", output_filename+ ".asc")


def check_sha(file):
    print("checking sha for %s" % (file))
    actual_sha = run_bash(["shasum",  "-a" , "512",  file], capture_output = True).stdout.split(" ")[0]
    with open(file + ".sha512") as f:
            file_sha = f.read().split(" ")[0]

    if actual_sha != file_sha:
        raise Exception("sha is different; expected %s, found %s" % (actual_sha, file_sha))

def check_signature(file):
    print("checking signature for %s" % (file))
    cmd_result = run_bash(["gpg", "--verify", file + ".asc", file], capture_output = True)
    text = cmd_result.stdout if cmd_result.stdout else cmd_result.stderr 
    if "Good signature from" not in text:
        raise Exception("Signature is not valid:\n%s" % text)
        

def check_file(work_dir, file_url):
    output_filename = os.path.basename(file_url)
    abs_filename = os.path.join(work_dir, output_filename)
    download_file(file_url, abs_filename)
    check_sha(abs_filename)
    check_signature(abs_filename)

def extract_tar_gz(file, to_file):
    ext = tarfile.open(file)
    ext.extractall(to_file)
    ext.close()

def build_mvn(dir, project, version):
    if project == "bookkeeper":
        run_bash(["mvn", "clean", "install",  "-DskipTests"], cwd=dir)
    else:
        if not version.startswith("2.7."):
            run_bash(["mvn", "apache-rat:check"], cwd=dir)
        # the build works only from the root dir
        run_bash(["mvn", "clean", "install", "-DskipTests"], cwd=dir)

def build_docker_image(dir):  
    run_bash(["chmod", "+x", "./build.sh"], cwd=os.path.join(dir, "docker"))
    run_bash(["./build.sh"], cwd=os.path.join(dir, "docker"))


parser = argparse.ArgumentParser()
parser.add_argument("-u", help="URL for artifacts")
parser.add_argument("-v", help="Version of the artifacts")
parser.add_argument("-p", help="Project")
parser.add_argument("--skip-build", help="Skip build", default=False, action='store_true')
parser.add_argument("--skip-docker", help="Skip docker", default=False, action='store_true')
parser.add_argument("--resume-from-dir", help="Resume from directory")
parser.add_argument("--force-status", help="Force status")

args = parser.parse_args()





working_dir = "/tmp/validate-rc/validate-rc-%s" % (time.time())
if args.resume_from_dir:
    working_dir = args.resume_from_dir
else:
    if not os.path.exists("/tmp/validate-rc"):
        os.mkdir("/tmp/validate-rc/")
    os.mkdir(working_dir)


print("Working directory: %s" % working_dir)


url = args.u
version = args.v
project = args.p

info = read_info(working_dir, None)
if not info:
    if not project or not url or not version:
        raise Exception("-p, -u, -v are required")
    
else:
    url = info["url"]
    version = info["version"]
    project = info["project"]


if not project in ["pulsar", "bookkeeper"]:
    raise "project not valid %s" % project


skip_build = args.skip_build
skip_docker = args.skip_docker
force_status = args.force_status



files_to_check = []
source_file = None

if project == "bookkeeper":
    files_to_check.append("bkctl-%s-bin.tar.gz" % version)
    files_to_check.append("bookkeeper-all-%s-bin.tar.gz" % version)
    files_to_check.append("bookkeeper-server-%s-bin.tar.gz" % version)
    files_to_check.append("bookkeeper-%s-src.tar.gz" % version)

    source_file = os.path.join(working_dir, "bookkeeper-%s-src.tar.gz" % version)
    
else:
    files_to_check.append("apache-pulsar-%s-bin.tar.gz" % version)
    files_to_check.append("apache-pulsar-%s-src.tar.gz" % version)
    files_to_check.append("apache-pulsar-offloaders-%s-bin.tar.gz" % version)

    source_file = os.path.join(working_dir, "apache-pulsar-%s-src.tar.gz" % version)


files_to_check = map(lambda local_name: os.path.join(url, local_name), files_to_check)



status = force_status if force_status else read_status(working_dir, "")
status = status.strip()
while True:
    if not status:
        print_info(working_dir, url, version, project)
        for file in files_to_check:
            check_file(working_dir, file)

        update_status(working_dir, "sha")
    elif status == "sha":
        if not skip_build:
            extract_dir = os.path.join(working_dir, "source-extracted")
            if os.path.exists(extract_dir):
                shutil.rmtree(extract_dir)
            os.mkdir(extract_dir)
            extract_tar_gz(source_file, extract_dir)
            src_dir = os.path.join(extract_dir, os.listdir(extract_dir)[0])
            
            build_mvn(src_dir, project, version)
        update_status(working_dir, "build")
    elif status == "build":
        if project == "pulsar":
            if not skip_docker:
                extract_dir = os.path.join(working_dir, "source-extracted")
                src_dir = os.path.join(extract_dir, os.listdir(os.path.join(working_dir, extract_dir))[0])
                print("Build docker image")
                build_docker_image(src_dir)
        update_status(working_dir, "docker")
    elif status == "docker":
        if project == "pulsar":
            if not skip_docker:
                container_id = run_bash(["docker", "images", "apachepulsar/pulsar:%s" % version, "-q"], capture_output=True).stdout.split("\n")[0]
                os.environ.setdefault("PULSAR_IMAGE", container_id)
                run_bash(["rm", "-rf", "pulsar-validation-tool"], cwd=working_dir)
                run_bash(["git", "clone", "https://github.com/nicoloboschi/pulsar-validation-tool"], cwd=working_dir)
                run_bash(["python3.9", "./local-docker-integration-tests-framework/runner.py", "run", "-f", "./local-docker-integration-tests-framework/tests/simple.yaml"], cwd=os.path.join(working_dir, "pulsar-validation-tool"))
                run_bash(["python3.9", "./local-docker-integration-tests-framework/runner.py", "run", "-f", "./local-docker-integration-tests-framework/tests/elastic.yaml"], cwd=os.path.join(working_dir, "pulsar-validation-tool"))
                update_status(working_dir, "done")
            else:
                update_status(working_dir, "done")
        else:
            # manual testing
            print("""
            Manual testing required:
            cd %s
            tar xzvf bookkeeper-all-%s-bin.tar.gz
            cd bookkeeper-all-%s-bin
            ./bin/bookkeeper localbookie 3
            -- other shell 
            ./bin/bookkeeper shell simpletest
            ./bin/bookkeeper shell readledger -ledgerid 0        
            
            """ % (working_dir, version, version))
            update_status(working_dir, "done")

    elif status == "done":  
        print("Done!")
        break
    else:
        raise Exception("Unknown status: %s" % status)
    
    status = read_status(working_dir, "")










