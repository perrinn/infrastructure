#!/bin/bash
#
#resize2fs /dev/xvda1
#
sudo mkdir /opt/apache
wget -P /tmp http://apache.mirror.serversaustralia.com.au/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
wget -P /tmp https://services.gradle.org/distributions/gradle-3.1-bin.zip
wget -P /tmp https://services.gradle.org/distributions/gradle-2.14-bin.zip
wget -O /tmp/packer.zip https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
wget -O /tmp/ROOT.war http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war
sudo tar -xf /tmp/apache-maven-3.3.9-bin.tar.gz -C /opt/apache
sudo ln -s /opt/apache/apache-maven-3.3.9 /opt/apache/maven
sudo yum erase -y java-1.7.0-openjdk
sudo rpm -Uvh http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
sudo yum install -y newrelic-sysmond git gcc java-1.8.0-openjdk tomcat8 tomcat8-webapps tomcat8-docs-webapp tomcat8-admin-webapps
sudo yum groupinstall -y "Development Tools"
sudo rpm -i /tmp/jdk.rpm
sudo yum update -y 
unzip /tmp/packer.zip
sudo mv packer /usr/local/bin
sudo rm /tmp/packer.zip
unzip /tmp/gradle-3.1-bin.zip
unzip /tmp/gradle-2.14-bin.zip
sudo mv gradle-3.1 /opt/gradle
sudo mv gradle 2.14 /opt/gradle2
sudo rm /tmp/gradle-3.1-bin.zip
sudo rm /tmp/gradle-2.14-bin.zip
sudo rm /tmp/apache-maven-3.3.9-bin.tar.gz
sudo service tomcat8 stop
sudo rm -rf /var/lib/tomcat8/webapps/ROOT
sudo mv /tmp/ROOT.war /var/lib/tomcat8/webapps
sudo chkconfig tomcat8 off
sudo chkconfig newrelic-sysmond off
wget -O /tmp/android-sdk.tar.gz https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
sudo tar -xf /tmp/android-sdk.tar.gz -C /opt
sudo rm /tmp/android-sdk.tar.gz
sudo mv /tmp/devenv.sh /etc/profile.d/devenv.sh
# Doing the sdk update inside packer takes to long, and times out
#echo "y" | /opt/android-sdk-linux/tools/android update sdk --all --no-ui
