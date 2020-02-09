#!/bin/bash

set -euCo pipefail

function configureTillerServiceAccount() {
    kubectl -n kube-system create serviceaccount tiller
    kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
}

configureTillerServiceAccount

helm init --service-account tiller
