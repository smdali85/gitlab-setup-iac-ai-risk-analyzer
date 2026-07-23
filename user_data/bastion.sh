#!/bin/bash
sudo yum update -y
sudo yum install git -y
sudo yum install docker -y
sudo systemctl start docker.service
sudo systemctl status docker.service
sudo systemctl enable docker.service
sudo chown -R ec2-user:ec2-user /var/run/docker.sock
sudo usermod -aG docker ec2-user
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.16/2024-12-12/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
kubectl version --short --client
sudo yum -y install mariadb-server
sudo service mariadb start
sudo amazon-linux-extras install redis6