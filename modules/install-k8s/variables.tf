variable "count" {
  description = "The number of resource to post provision"
  default     = 1
}

variable "ipv4_addrs" {
  type        = "list"
  description = "The list of IPv4 addrs to provision"
}

variable "triggers" {
  type        = "list"
  description = "The list of values which can trigger a provisionning"
}

variable "ssh_user" {
  description = "The ssh username of the image used to boot the k8s cluster."
  default     = "core"
}

variable "install_dir" {
  description = "Directory where to install k8s"
  default     = "/opt/k8s"
}

variable "ssh_bastion_host" {
  description = "The address of the bastion host used to post provision the k8s cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "ssh_bastion_user" {
  description = "The ssh username of the bastion host used to post provision the k8s cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "k8s_version" {
  description = "The version of k8s to install with the post installation script if `post_install_module` is set to true"
  default     = "1.9.6"
}

variable "calico_node_version" {
  description = "The version of calico_node to install with the post installation script if `post_install_module` is set to true"
  default     = "2.6.8"
}

variable "calico_cni_version" {
  description = "The version of calico_cni to install with the post installation script if `post_install_module` is set to true"
  default     = "1.11.2"
}

variable "flannel_version" {
  description = "The version of flannel to install with the post installation script if `post_install_module` is set to true"
  default     = "0.9.1"
}

variable "kubedns_version" {
  description = "The version of kubedns to install with the post installation script if `post_install_module` is set to true"
  default     = "1.14.7"
}

variable "pause_version" {
  description = "The version of pause to install with the post installation script if `post_install_module` is set to true"
  default     = "3.0"
}

variable "k8s_cni_plugins_version" {
  description = "The version of the cni plugins to install with the post installation script if `post_install_module` is set to true"
  default     = "0.7.0"
}

variable "k8s_sha1sum_cni_plugins" {
  description = "The sha1 checksum of the container cni plugins release to install with the post installation script if `post_install_module` is set to true"
  default     = "379c54de9c973f3a5323ae44ce664ac1175eede2"
}

variable "k8s_sha1sum_kubelet" {
  description = "The sha1 checksum of the k8s binary kubelet to install with the post installation script if `post_install_module` is set to true"
  default     = "32b1234e68d4d576c3fe0b62e608e361e09408a1"
}

variable "k8s_sha1sum_kubectl" {
  description = "The sha1 checksum of the k8s binary kubectl to install with the post installation script if `post_install_module` is set to true"
  default     = "04d344ac9b2a6514f0d94c2df79073e42d6c1182"
}

variable "k8s_sha1sum_kubeadm" {
  description = "The sha1 checksum of the k8s binary kubeadm to install with the post installation script if `post_install_module` is set to true"
  default     = "3eba73297aac155bcebc9d006eb1ca0cf7ff86f0"
}
