variable "security_group_id" {
  description = "The security group id to which k8s ingress rules will be added"
}

variable "remote_group_id" {
  description = "The remote security group id from which ingress k8s traffic will be allowed"
}

variable "ping" {
  description = "allow ping (icmp)"
  default     = true
}

variable "flannel_udp" {
  description = "allow flannel with udp backend"
  default     = false
}

variable "flannel_vxlan" {
  description = "allow flannel with vxlan backend"
  default     = false
}

variable "calico_bgp" {
  description = "allow calico with bgp backend"
  default     = false
}

variable "canal" {
  description = "allow canal networking (calico+flannel). Defaults to `true`"
  default     = true
}

variable "etcd_peer" {
  description = "allow etcd peer communication"
  default     = false
}

variable "etcd_client" {
  description = "allow etcd client communication"
  default     = false
}

variable "cfssl" {
  description = "allow cfssl communication"
  default     = false
}

variable "cfssl_port" {
  description = "cfssl communication tcp port"
  default     = 8888
}

variable "master_to_master" {
  description = "allow masters k8s inter communication"
  default     = false
}

variable "worker_to_master" {
  description = "allow workers to masters k8s inter communication"
  default     = false
}

variable "master_to_worker" {
  description = "allow masters to workers k8s inter communication"
  default     = false
}

variable "worker_to_worker" {
  description = "allow workers k8s inter communication"
  default     = false
}
