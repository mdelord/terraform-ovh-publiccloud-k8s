output "rendered" {
  description = "The representation of the userdata according to `var.ignition_mode`"
  value = ["${data.ignition_config.coreos.*.rendered}"]
}

output "etcd_initial_cluster" {
  description = "The etcd initial cluster that can be used to join the cluster"
  value = "${module.etcd.etcd_initial_cluster}"
}

output "etcd_endpoints" {
  description = "The etcd client endpoints that can be used to interact with the cluster"
  value = "${module.etcd.etcd_endpoints}"
}
