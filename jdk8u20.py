#!/usr/bin/env python3
import os, sys, subprocess, shutil, urllib.request, tarfile
JDK_URL   = "http://www.joaomatosf.com/rnp/java_files/jdk-8u20-linux-x64.tar.gz"
OPT_DIR   = "/opt"
JDK_DIR   = f"{OPT_DIR}/jdk1.8.0_20"
ARCHIVE   = f"{OPT_DIR}/jdk-8u20-linux-x64.tar.gz"
def run(cmd, check=True):
    print("+", cmd)
    subprocess.run(cmd, shell=True, check=check)
def main():
    if os.geteuid() != 0:
        os.execvp("sudo", ["sudo", sys.executable] + sys.argv)
    if os.path.exists(JDK_DIR):
        shutil.rmtree(JDK_DIR)
    urllib.request.urlretrieve(JDK_URL, ARCHIVE)
    with tarfile.open(ARCHIVE, "r:gz") as tf:
        tf.extractall(OPT_DIR)
    os.remove(ARCHIVE)
    run(f"update-alternatives --install /usr/bin/java  java  {JDK_DIR}/bin/java  1800")
    run(f"update-alternatives --install /usr/bin/javac javac {JDK_DIR}/bin/javac 1800")
    print("当前默认版本：")
    run("java -version", check=False)
    run("javac -version", check=False)
    print("\n安装完成！切换版本请执行：")
    print(f"  sudo update-alternatives --config java")
    print("卸载请执行：")
    print(f"  sudo update-alternatives --remove java {JDK_DIR}/bin/java && sudo rm -rf {JDK_DIR}")
if __name__ == "__main__":
    main()