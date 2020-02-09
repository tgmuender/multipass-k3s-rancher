#!/bin/bash

set -euCo pipefail

function installCertManager() {
    kubectl apply \
        --validate=false \
        -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml

    helm repo add jetstack https://charts.jetstack.io

    helm install \
        --name certificate-manager \
        --namespace cert-manager \
        jetstack/cert-manager

    kubectl -n cert-manager rollout status deploy/certificate-manager-cert-manager
    kubectl -n cert-manager rollout status deploy/certificate-manager-cert-manager-webhook
}

function installRancherDashboard() {
    # See https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/

    helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

    #kubectl create ns cattle-system

    local hostname='rancher.sandbox'

    helm install \
        --name rancher \
        rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=${hostname}  \
        --set ingress.tls.source=rancher

    kubectl -n cattle-system rollout status deploy/rancher
}


installCertManager
sleep 30
installRancherDashboard


