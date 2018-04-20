# Simple Kubernetes Cluster with workers

This examples shows how to use the `terraform-ovh-publiccloud-k8s` module to 
launch a simple Kubernetes cluster on OVH Public Cloud, based on a `CoreOS Stable`
image, by post-provisionning the kubernetes setup through ssh.

- [Simple kubernetes cluster with workers](#simple-kubernetes-cluster-with-workers)
    - [Pre-Requisites](#pre-requisites)
    - [Configuration](#configuration)
    - [Launch the cluster](#launch-the-cluster)
    - [Get started with Kubernetes](#get-started-with-kubernetes)

## Pre-requisites

- a proper terraform installation

  You can find information on how to install terraform [here](https://www.terraform.io/intro/getting-started/install.html).

- an OVH Public Cloud project
  
  Create a public cloud project on OVH following the [official documentation](https://docs.ovh.com/gb/en/public-cloud/getting_started_with_public_cloud_logging_in_and_creating_a_project/).

  Create an Openstack user ([official documentation](https://docs.ovh.com/gb/en/public-cloud/configure_user_access_to_horizon/)).
  Then download the Openstack configuration file. You can get it from [OVH Manager](https://www.ovh.com/manager/cloud/), or from [Horizon interface](https://horizon.cloud.ovh.net/project/api_access/openrc/).

  Source the configuration file:

  ```bash
  $ source openrc.sh
  Please enter your OpenStack Password:
  ```
  
- (Optional) Install the openstack cli

  ```bash
  $ sudo pip install python-openstackclient==3.15.0
  ```

- an ssh public key or openstack keypair

  The module allows you to either use an ssh public key file or a predefined openstack keypair

  Example: 

   ```bash
   # Generate a new keypair without passphrase
   $ ssh-keygen -f terraform_ssh_key -q
   # Add it to the ssh-agent 
   $ eval $(ssh-agent)
   $ ssh-add terraform_ssh_key
   ```
   
   Or:
   
   ```bash
   $ openstack keypair create -f value k8s > ssh_key
   $ openstack keypair show --public-key -f value k8s > ssh_key.pub
   $ chmod 0600 ./ssh_key
   # Add it to the ssh-agent
   $ eval $(ssh-agent)
   $ ssh-add ./ssh_key
   ```

## Configuration

1. You have to init terraform (run once):

```bash
$ terraform init
Initializing modules...
- module.network
- module.kube
[...]
Terraform has been successfully initialized!
```

1. (Optional) Customize default values file, then edit it if needed.
   This allow terraform to autoload those variables

   ```bash
   cp terraform.tfvars.sample terraform.tfvars
   ```

## Launch the cluster

You have to choose an openstack region to launch the cluster in, and a keypair name and/or ssh public key according to your preferences. You can either setup these variables in the customized `.tfvars` file (see [previous paragraph](#configuration)) or pass them in the command line:

Using an openstack keypair:

```bash
$ terraform apply -var region=GRA3 -var key_pair=k8s
[...]
```

Or using an ssh public key:

```bash
$ terraform apply -var region=GRA3 -var public_sshkey=./ssh_key.pub
[...]
```


This should give you an infra with:

* 3 kubernetes masters in a public network with:
  * Canal (Flannel + Calico) CNI
  * kube-proxy for services
* 2 kubernetes workers in a public network

## Get Started with Kubernetes

Get help with following command:

```bash
$ terraform output helper
 Your kubernetes cluster is up.

Retrieve k8s configuration locally:

    $ mkdir -p ~/.kube/myk8s
    $ ssh core@A.B.C.D sudo cat /etc/kubernetes/admin.conf > ~/.kube/myk8s/config
    $ kubectl --kubeconfig ~/.kube/myk8s/config get nodes

You can also ssh into one of your master instances:

    $ ssh core@A.B.C.D
    $ ssh core@A.B.C.E
    $ ssh core@A.B.C.F

or worker nodes:

    $ ssh core@B.C.D.E
    $ ssh core@B.C.D.F

Enjoy!
```
