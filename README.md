# Kubernetes OVH Public Cloud Module

This repo contains a Module for how to deploy a [Kubernetes](https://kubernetes.io/) cluster on [OVH Public Cloud](https://ovhcloud.com/) using [Terraform](https://www.terraform.io/). Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications.

# Usage

```hcl
module "k8s_secgroups" {
  source = "bovh/publiccloud-k8s/ovh//modules/k8s-secgroups"
  name   = "myk8s"
  etcd   = true
  cfssl  = true
}

module "k8s" {
  source                    = "ovh/publiccloud-k8s/ovh"
  region                    = "BHS3"
  name                      = "myk8s"
  count                     = 3
  master_mode               = true
  worker_mode               = true
  cfssl                     = true
  etcd                      = true
  image_name                = "CoreOS Stable K8S"
  flavor_name               = "b2-7"
  security_group_ids        = ["${module.k8s_secgroups.master_group_id}", "${module.k8s_secgroups.worker_group_id}"]
  associate_public_ipv4     = true
  associate_private_ipv4    = false
}
```

## Examples

This module has the following folder structure:

* [root](.): This folder shows an example of Terraform code which deploys a [K8s](https://kubernetes.io/) cluster in [OVH Public Cloud](https://ovhcloud.com/).
* [modules](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/modules): This folder contains the reusable code for this Module, broken down into one or more modules.
* [examples](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/examples): This folder contains examples of how to use the modules.

To deploy K8s servers using this Module:

1. (Optional) Create a K8s Glance Image using a Packer template that references the [install-k8s module](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/modules/install-k8s).
   Here is an [example Packer template](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/examples/k8s-glance-image#quick-start).
1. Deploy that Image using one of the Terraform cluster example: [private cluster](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/examples/private-cluster-cl) or [public cluster](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/examples/public-cluster-cl). If you prebuilt a k8s glance image with packer, you can comment the post provisionning modules arguments.

## Flavors

kube-dns will not work (OutOfCpu) if only one VCPU is present (see kubernetes/kubernetes#38806), so it is not recommanded to use sandbox instances `s1-2` and `s1-4`.

## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/CONTRIBUTING.md) for instructions.

## Authors

Module managed by
- [Yann Degat](https://github.com/yanndegat).
- [Joris Bonnefoy](https://github.com/Devatoria).
- [Loïc PORTE](https://github.com/bewiwi).
- Nicolas_NATIVEL.
- [Timothé GERMAIN](https://github.com/tgermain).

## License

The 3-Clause BSD License. See [LICENSE](https://github.com/ovh/terraform-ovh-publiccloud-k8s/tree/master/LICENSE) for full details.
