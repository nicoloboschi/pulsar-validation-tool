#!/bin/bash
PVT_HOME="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

grep '.pvtool/bin' $HOME/.bashrc ||  echo "export PATH=\$PATH:$HOME/.pvtool/bin" >> "$HOME/.bashrc"
grep 'PVT_HOME=' $HOME/.bashrc ||  echo "export PVT_HOME=$PVT_HOME"  >> "$HOME/.bashrc"
grep 'source $PVT_HOME' $HOME/.bashrc ||  echo "source \$PVT_HOME/minikube/utils.sh"  >> "$HOME/.bashrc"
source $PVTHO

mkdir -p $HOME/.pvtool
mkdir -p $HOME/.pvtool/bin
cd $HOME/.pvtool

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

helm repo add datastax-pulsar https://datastax.github.io/pulsar-helm-chart
helm repo update

curl -LO https://github.com/derailed/k9s/releases/download/v0.25.15/k9s_Linux_x86_64.tar.gz
tar xzvf k9s_Linux_x86_64.tar.gz
mv k9s bin/k9s


sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl


