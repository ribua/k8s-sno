# Automated Single Node Openshift

This repo contains playbooks that can be used to create a SNO instance in your home workstation running VirtualMachines using **libvirtd**. This is done using a single playbook and there are few user configurations that are required to complete the installation

## Playbooks/Steps

This section details the steps 

1. Creates the cluster instance in [console.redhat.com](https://console.redhat.com) and registers it.
2. Downloads the iso and loads it into an existing VirtualMachine that is created.
3. Boots the VM of the discovery iso attached.
4. The cluster status changes from **pending** to **Ready** and proceeds with the installation.
5. Runs the installation to completion.


## User Inputs

To avoid over complicating the repo and playbooks we require some user inputs as part of this deployment. 

- Create the virtual machine and attach 2 disks and primary of size 150GB (thin or thick) as part of minimum installation for coreOS. 

