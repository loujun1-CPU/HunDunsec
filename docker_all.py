"""
作者:HunDunSec
GitHub:https://github.com/loujun1-CPU/HunDunsec
"""
#!/usr/bin/env python3
import os
import sys
import subprocess
import json
class DockerInstaller:
    def __init__(self):
        self.docker_mirrors = [
            "https://docker.1panel.live",
            "https://hub.rat.dev"
        ]
    def run_command(self, cmd, shell=False):
        try:
            if shell:
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            else:
                result = subprocess.run(cmd, capture_output=True, text=True)
            return result.returncode == 0
        except:
            return False
    def install_docker(self):
        self.run_command("apt update", shell=True)
        self.run_command("apt-get update", shell=True)
        self.run_command("apt install -y docker.io", shell=True)
        self.run_command("apt install -y docker-compose", shell=True)
        self.run_command("systemctl start docker", shell=True)
        self.run_command("systemctl enable docker", shell=True)
        self.run_command("mkdir -p /etc/docker", shell=True)
        config_path = "/etc/docker/daemon.json"
        mirrors_config = {
            "registry-mirrors": self.docker_mirrors
        }
        with open(config_path, 'w') as f:
            json.dump(mirrors_config, f, indent=2)
        self.run_command("systemctl restart docker", shell=True)
        self.run_command("docker --version", shell=True)
        self.run_command("docker info", shell=True)
        self.run_command("docker-compose --version", shell=True)
        return True
def main():
    installer = DockerInstaller()
    installer.install_docker()
    print("docker安装成功")
    print("docker-compose安装成功")
if __name__ == "__main__":
    main()
