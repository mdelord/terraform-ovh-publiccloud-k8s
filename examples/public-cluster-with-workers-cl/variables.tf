variable "region" {
  description = "The Openstack region name"
}

variable "masters_flavor_name" {
  description = "Flavor to use for master nodes"
  default     = "s1-8"
}

variable "workers_flavor_name" {
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
