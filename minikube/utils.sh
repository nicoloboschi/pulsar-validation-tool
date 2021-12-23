
pvt_minikube_start() {
    minikube delete
    minikube start --kubernetes-version='1.19.0'
}

pvt_clean() {    
    kubectl delete --all all
    helm delete pvtpulsar
}

pvt_install() {
    pvt_clean
    helm install --wait --debug --timeout 1200s pvtpulsar datastax-pulsar/pulsar --version=2.0.9  -f $1 
}

pvt_render() {
    mkdir -p $PVT_HOME/tmp
    local filename=$(2:-$PVT_HOME/tmp/$1-$(uuidgen).yaml)
    envsubst < $1 > "$filename"
}

pvt_render_install() {
    set -ex
    local filename=${PVT_HOME}/tmp/$1-$(uuidgen).yaml
    pvt_render $1 "$filename"
    pvt_install "$filename"
}
