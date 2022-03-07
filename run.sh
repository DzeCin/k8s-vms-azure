#!/bin/bash

set -e

echo -n "Checking dependencies... "
for name in python "python -m venv" ansible-playbook terraform az
do
  [[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name needs to be installed.";deps=1; }
done
[[ $deps -ne 1 ]] && echo "OK" || { echo -en "\nInstall the above and rerun this script\n";exit 1; }

az login

script_dir=$(dirname "$0")
rm=0

for var in "$@"
do
    if [ "$var" == "--rm" ]; then
      rm=1
    fi
done

cd "$script_dir"


if [ $rm == 1 ]; then
  terraform -chdir=applications/k8s-vms-azure destroy -auto-approve
  exit 0
fi


terraform -chdir=applications/k8s-vms-azure init
terraform -chdir=applications/k8s-vms-azure refresh
terraform -chdir=applications/k8s-vms-azure apply -auto-approve

sleep 4


res=$(python format-to-hosts.py "$(terraform -chdir=applications/k8s-vms-azure output -json vmip)")


python -m venv venv
source venv/bin/activate
cd ansible/kubespray

pip install -r requirements.txt

cp -rfp inventory/sample inventory/mycluster

CONFIG_FILE=inventory/mycluster/hosts.yaml python contrib/inventory_builder/inventory.py ${res} ## Must not be quoted


ansible-playbook -u "bob" -i inventory/mycluster/hosts.yaml --ssh-common-args='-o StrictHostKeyChecking=no' --become --become-user=root cluster.yml

rm -rf inventory/mycluster

cd "$script_dir"

terraform -chdir=applications/k8s-vms-azure output -json vmip

echo "You can now connect to the nodes using bob as ssh user (ssh bob@node_ip)"

exit 0