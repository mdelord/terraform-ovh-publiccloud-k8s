variable "os_region_name" {
  description = "The Openstack region name"
}

variable "os_tenant_id" {
  description = "The id of the openstack project"
  default     = ""
}

variable "os_auth_url" {
  description = "The OpenStack auth url"
  default     = "https://auth.cloud.ovh.net/v2.0/"
}

variable "os_flavor_name_masters" {
  description = "Flavor to use for master nodes"
  default     = "s1-8"
}

variable "os_flavor_name_workers" {
  description = "Flavor to use for worker nodes"
  default     = "s1-8"
}

variable "name" {
  description = "The name of the cluster. This attribute will be used to name openstack resources"
  default     = "myk8s"
}

variable "master_count" {
  description = "Number of master nodes in the k8s cluster"
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes in the k8s cluster"
  default     = 2
}

variable "public_sshkey" {
  description = "Key to use to ssh connect"
  default     = "~/.ssh/id_rsa.pub"
}

variable "key_pair" {
  description = "Predefined keypair to use"
  default     = ""
}
