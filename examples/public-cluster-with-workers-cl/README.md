# Simple k8s cluster with workers


- [Simple k8s cluster](#simple-k8s-cluster)
    - [Configuration](#configuration)
    - [Run it](#run-it)
    - [Get started](#get-started)
    
## Install terraform

You can information on how to install terraform [here](https://www.terraform.io/intro/getting-started/install.html).

## Configuration

1. Copy variable file, then edit it if needed.
   This allow terraform to autoload those variables

   ```bash
   cp terraform.tfvars.sample terraform.tfvars
   ```

2. Create a public cloud project on OVH following the [official documentation](https://docs.ovh.com/gb/en/public-cloud/getting_started_with_public_cloud_logging_in_and_creating_a_project/).

   Create an Openstack user ([official documentation](https://docs.ovh.com/gb/en/public-cloud/configure_user_access_to_horizon/)).
   Then download the Openstack configuration file. You can get it from [OVH Manager](https://www.ovh.com/manager/cloud/), or from [Horizon interface](https://horizon.cloud.ovh.net/project/api_access/openrc/).

   Source the configuration file:

   ```bash
   $ source openrc.sh
   Please enter your OpenStack Password:

   ```

3. Create or reuse ssh key pair. Careful this keypair should not be using passphrase!

   ```bash
   # Generate a new keypair without passphrase
   $ ssh-keygen -f terraform_ssh_key -q -N ""
   # Add it to the ssh-agent
   $ ssh-add terraform_ssh_key
   ```

   If you generated a new keypair, set `public_sshkey` with its path in `terraform.tfvars`.

## Run it

```bash
$ terraform init
Initializing modules...
- module.network
- module.kube
[...]
Terraform has been successfully initialized!

$ terraform apply
[...]

```

This should give you an infra with:

* 3 kubernetes masters in a public network with:
  * Canal (Flannel + Calico) CNI
  * kube-proxy for services
* 2 kubernetes workers

## Get Started

Get help with following command:

```bash
$ terraform output helper
Your kubernetes cluster is up.

Check if cluster is running:

    $ [...]

Configure the client:

    $ [...]

To connect to one of the instances:

    $ [...]

Run a pod:

    $ [...]

Enjoy!
```
