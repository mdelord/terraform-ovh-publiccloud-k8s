variable "name" {
  description  = "Prefix name that will be used for security groups"
}

variable "apply_module" {
  description = "If set to false, no resource within this module will be created"
  default     = true
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

variable "etcd" {
  description = "allow etcd communication"
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

variable "worker_egress_ip_prefix" {
  description = "ip prefix to which global traffic will be allowed."
  default     = "0.0.0.0/0"
}

variable "master_egress_ip_prefix" {
  description = "ip prefix to which global traffic will be allowed."
  default     = "0.0.0.0/0"
}
