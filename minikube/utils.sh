
pvt_minikube_start() {
    minikube delete || true
    minikube start --kubernetes-version='1.19.0'
}

pvt_clean() {    
    kubectl delete --all all || true
    helm delete pvtpulsar || true
}

pvt_install() {
    pvt_clean
    helm install --wait --debug --timeout 1200s pvtpulsar datastax-pulsar/pulsar --version=2.0.9  -f $1 
}

pvt_render() {
    mkdir -p $PVT_HOME/tmp
    default_filename=$PVT_HOME/tmp/$1-$(uuidgen).yaml
    local filename=${2:-$default_filename}
    envsubst < "$1" > "$filename"
}

pvt_render_install() {
    local filename=${PVT_HOME}/tmp/$(basename $1)-$(uuidgen).yaml
    pvt_render $1 "$filename"
    pvt_install "$filename"
}
