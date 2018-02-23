variable "region" {
  type        = "string"
  description = "The target openstack region"
}

variable "count" {
  description = "Specifies the number of nodes in the cluster"
  default     = 1
}

variable "ignition_mode" {
  description = "Defines if main output is in ignition or cloudinit format"
  default     = true
}

variable "name" {
  type        = "string"
  description = "Cluster name"
}

variable "domain" {
  description = "The domain of the cluster."
  default     = "local"
}

variable "datacenter" {
  description = "The datacenter of the cluster."
  default     = "dc1"
}

variable "k8s_version" {
  description = "Kubernetes version. If left empty, will chose last stable version according to 'https://dl.k8s.io/release/stable.txt'"
  default     = ""
}

variable "ipv4_addrs" {
  description = "list of nodes ipv4 addrs. Required if `master_mode` is true."
  type = "list"
  default = []
}

variable "etcd" {
  description = <<DESC
Defines if node shall be started as an etcd cluster member. If set to `true`
and no `etcd_initial_cluster` is given as argument, etcd will
bootstrap a new cluster.
DESC

  default     = false
}

variable "etcd_initial_cluster" {
  description = "etcd initial cluster. Useful to join an existing cluster. Useful if `master_mode` is true."
  default = ""
}

variable "master_mode" {
  description = "Determines if nodes are k8s master nodes or simple workers"
  default     = false
}

variable "ssh_authorized_keys" {
  type        = "list"
  description = "SSH public keys"
  default     = []
}

variable "host_cidr" {
  description = "CIDR IPv4 range to assign to openstack instances"
  type        = "string"
}

variable "pod_cidr" {
  description = "CIDR IPv4 range to assign Kubernetes pods"
  type        = "string"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for kube-dns.
EOD

  type    = "string"
  default = "10.3.0.0/16"
}

variable "cacert" {
  description = "Optional ca certificate to add to the server nodes."
  default     = ""
}

variable "cacert_key" {
  description = "Optional ca certificate to use in conjunction with `cacert` for generating certs with cfssl."
  default     = ""
}

variable "cfssl" {
  description = "Defines if cfssl shall be started and used a pki. If no cacert with associated private key is given as argument, cfssl will generate its own self signed ca cert."
  default     = false
}

variable "cfssl_endpoint" {
  description = "If `cfssl` is set to `true`, this argument can be used to specify a target cfssl endpoint. Otherwise the first ipv4 given as argument in `ipv4_addrs` will be used as the cfssl endpoint in instances userdata."
  default     = ""
}

variable "cfssl_ca_validity_period" {
  description = "validity period for generated CA"
  default     = "43800h"
}

variable "cfssl_cert_validity_period" {
  description = "default validity period for generated certs"
  default     = "8760h"
}

variable "cfssl_key_algo" {
  description = "generated certs key algo"
  default     = "rsa"
}

variable "cfssl_key_size" {
  description = "generated certs key size"
  default     = "2048"
}

variable "cfssl_bind" {
  description = "cfssl service bind addr"
  default     = "0.0.0.0"
}

variable "cfssl_port" {
  description = "cfssl service bind port"
  default     = "8888"
}
