#!/usr/bin/env bash

declare -r ISTIO_INSTALL_DIR=$(cd $(dirname $(which istioctl)) && cd ../ && pwd)

helm install "${ISTIO_INSTALL_DIR}/install/kubernetes/helm/istio-init" --name istio-init --namespace istio-system

kubectl -n istio-system wait --for=condition=complete job --all

helm install "${ISTIO_INSTALL_DIR}/install/kubernetes/helm/istio" --name istio --namespace istio-system
