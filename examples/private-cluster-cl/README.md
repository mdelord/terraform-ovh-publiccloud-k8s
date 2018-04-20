# Simple Kubernetes Private Cluster 

This examples shows how to use the `terraform-ovh-publiccloud-k8s` module to 
launch a simple Kubernetes cluster on OVH Public Cloud, based on a `CoreOS Stable`
image, in a private network, by post-provisionning the kubernetes setup through an
ssh bastion.

- [Simple Kubernetes Private Cluster](#simple-kubernetes-private-cluster)
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

- A VRack product attached to your Openstack project
  
  This product is required in order to create openstack private networks.

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

* 1 public instance acting as an ssh bastion host and an Internet NAT Gateway for the 
    instances launched on the private subnet
* 3 kubernetes masters in a private network with:
   * Canal (Flannel + Calico) CNI
   * Untainted nodes (pods can run on masters)
   * kube-proxy for services

## Get Started with Kubernetes

Get help with following command:

```bash
$ terraform output helper
Your kubernetes cluster is up.

Retrieve k8s configuration locally:

    $ mkdir -p ~/.kube/myk8s
    $ ssh -o ProxyCommand='ssh core@A.B.C.D ncat %h %p' core@10.0.16.5 sudo cat /etc/kubernetes/admin.conf > ~/.kube/myk8s/config

As your cluster is not exposed to the Internet, you'll have to be on the same network as your masters
to have kubectl work (eg.: connect through a vpn, access from an edge node):

    $ kubectl --kubeconfig ~/.kube/myk8s/config get nodes

Or you can ssh into one of your instances:

    $ ssh -o ProxyCommand='ssh core@A.B.C.D ncat %h %p' core@10.0.16.5
    $ ssh -o ProxyCommand='ssh core@A.B.C.D ncat %h %p' core@10.0.16.4
    $ ssh -o ProxyCommand='ssh core@A.B.C.D ncat %h %p' core@10.0.16.3

And run commands from there:

    $ sudo /opt/k8s/bin/kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes

Enjoy!
```
