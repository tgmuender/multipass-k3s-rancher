#!/usr/bin/env bash

set -euo pipefail

function createVM() {
    local id="$1"

    echo "Creating VM $id"

    multipass launch \
        --name "cluster-node-${id}" \
        --mem 2G \
        --cpus 4
}

function removeVMs() {
    echo "Removing ${nodeCount} VMs"

    for id in ${vmIds[@]}
    do
        multipass --purge delete cluster-node-${id}
    done
    
}

function createVMs() {
    echo "Creating ${nodeCount} VMs"
    for id in ${vmIds[@]}
    do
        createVM ${id}
    done
}

function startVMs() {
    echo "Starting ${nodeCount} VMs"
    for id in ${vmIds[@]}
    do
        multipass start cluster-node-${id}
    done
}

function showUsage() {
    cat <<EOF
    Usage:
        $0 create -- to create the VMs
        $0 delete -- to delete the VMs
        $0 start  -- to start the previously configured VMs
EOF
    exit 1
}

function updateHostsFile() {
    for i in ${vmIds[@]}
    do
        local nodeIP=$(multipass list | grep cluster-node-${i} | awk '{ print $3}')
        echo "Updating hosts file for cluster-node-${i} with IP ${nodeIP}"

        local matches=$(grep cluster-node-$i /etc/hosts | cut -f1 -d:)

        if [[ -z ${matches} ]]
        then
            echo "Inserting entry"
            echo "${nodeIP}  cluster-node-${i}" >> /etc/hosts
        else
            while read -r line
            do
                echo "Found existing match for cluster-node-$i - updating entry"

                sed -i "s/${line}/${nodeIP} cluster-node-${i}/" /etc/hosts
            done <<< "${matches}"
        fi
    done
}

declare -r nodeCount=4
declare -a vmIds=$(seq 1 ${nodeCount})

if [[ $# -ne 1 ]]
then
    showUsage
fi

case $1 in
    "create")
        createVMs
        ./k3s.sh ${vmIds[@]}
        ;;
    "delete")
        removeVMs
        ;;
    "hosts")
        updateHostsFile
        ;;
    "start")
        startVMs
        ;;
    *)
        showUsage
        ;;
esac
