
pvt_clean() {
    helm delete pvtpulsar
    kubectl delete --all all
}

pvt_install() {
    pvt_clean
    helm install --wait --debug --timeout 1200s pvtpulsar datastax-pulsar/pulsar --version=2.0.9  -f $1 
}