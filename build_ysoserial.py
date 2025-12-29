"""
作者:HunDunSec
GitHub:https://github.com/loujun1-CPU/HunDunsec
"""
#!/usr/bin/env python3
import os, sys, subprocess, shutil, urllib.request, tarfile, pathlib
JDK_URL = "http://www.joaomatosf.com/rnp/java_files/jdk-8u20-linux-x64.tar.gz"
OPT_DIR = "/opt"
JDK_DIR = f"{OPT_DIR}/jdk1.8.0_20"
ARCHIVE = f"{OPT_DIR}/jdk-8u20-linux-x64.tar.gz"
YSO_REPO = "https://github.com/frohoff/ysoserial.git"
def run(cmd, check=True):
    print("+", cmd)
    subprocess.run(cmd, shell=True, check=check)
def install_jdk8():
    if os.path.exists(JDK_DIR):
        shutil.rmtree(JDK_DIR)
    print("下载JDK8u20")
    urllib.request.urlretrieve(JDK_URL, ARCHIVE)
    with tarfile.open(ARCHIVE, "r:gz") as tf:
        tf.extractall(OPT_DIR)
    os.remove(ARCHIVE)
    run(f"update-alternatives --install /usr/bin/java  java  {JDK_DIR}/bin/java  1800")
    run(f"update-alternatives --install /usr/bin/javac javac {JDK_DIR}/bin/javac 1800")
    run("java -version", check=False)
def install_maven():
    run("apt-get update")
    run("apt install -y maven")
def write_mirror():
    m2 = pathlib.Path.home() / ".m2"
    m2.mkdir(exist_ok=True)
    settings = m2 / "settings.xml"
    settings.write_text("""<settings>
  <mirrors>
    <mirror>
      <id>aliyun-http</id>
      <mirrorOf>*</mirrorOf>
      <name>Aliyun HTTP</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror>
  </mirrors>
</settings>""")
def clone_yso():
    if not pathlib.Path("pom.xml").exists():
        if pathlib.Path("ysoserial").exists():
            shutil.rmtree("ysoserial")
        run("git clone --depth 1 " + YSO_REPO)
        os.chdir("ysoserial")
def build():
    print("开始编译ysoserial")
    run("mvn clean package -DskipTests -U")
def show_jar():
    jar = next(pathlib.Path("target").glob("ysoserial-*.jar"))
    print("编译完成，jar 路径：", jar.resolve())
def main():
    if os.geteuid() != 0:
        os.execvp("sudo", ["sudo", sys.executable] + sys.argv)
    install_jdk8()
    install_maven()
    write_mirror()
    clone_yso()
    build()
    show_jar()
if __name__ == "__main__":
    main()
