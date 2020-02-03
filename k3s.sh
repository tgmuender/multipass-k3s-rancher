#!/usr/bin/env bash

set -euo pipefail

declare -ra NODES="($@)"
declare -r MASTER_NODE_NAME="cluster-node-${NODES[0]}"
declare -r IP_REGEX='([0-9]{1,3}[\.]){3}[0-9]{1,3}'
declare -r MASTER_NODE_IP=$(multipass info ${MASTER_NODE_NAME} | grep -E -o "$IP_REGEX")
declare -r K3S_URL="https://${MASTER_NODE_IP}:6443"

function setupMasterNode() {
    # See https://rancher.com/docs/k3s/latest/en/installation/install-options/
    multipass exec ${MASTER_NODE_NAME} -- /bin/bash -c "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"server\" sh -"
}

function getMasterToken() {
    echo "$(multipass exec ${MASTER_NODE_NAME} -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
}

function setupWorkerNodes() {
    local workerNodes=("$@")

    for i in ${workerNodes[@]}
    do
        echo "Provisioning worker node: ${i}"

        # See https://rancher.com/docs/k3s/latest/en/installation/install-options/
        # Installation defaults to 'agent' if 'K3S_URL' is present
        multipass exec "cluster-node-${i}" -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_URL} sh -"
    done
}

function downloadKubeConfig() {
    multipass exec ${MASTER_NODE_NAME} -- bash -c "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-sandbox.yaml
    sed -i 's/127.0.0.1/cluster-node-1/g' k3s-sandbox.yaml
}

echo "Number of nodes to provision: ${#NODES[@]}"
setupMasterNode "cluster-node-${NODES[0]}"
declare -r K3S_TOKEN=$(getMasterToken)

setupWorkerNodes "${NODES[@]:1}"

downloadKubeConfig
