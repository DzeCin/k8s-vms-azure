### Introduction
With this project, you can deploy a kubernetes cluster on Azure's VMs. This is not to be used in production but only for testing purpose.

### How can I run it ?
This is made for Linux systems supporting bash. 

Prerequisites:
- an Azure account
- terraform
- ansible-playbook
- python
- python -m venv
- az (Azure CLI)

To run it use ```./run.sh```.

Args:
- ```--rm``` to remvove the Azure cluster when you are done testing.

### Infos
The SSH public key deployed on the VMs will be your ```~/.ssh/id_rsa.pub```.

Used CNI is Calico.

The Ansible script is a modified version of Kubespray.