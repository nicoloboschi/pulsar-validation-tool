
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