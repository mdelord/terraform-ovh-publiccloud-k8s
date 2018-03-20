output "master_group_id" {
  description = "The security group id for master nodes"
  value       = "${openstack_networking_secgroup_v2.master.id}"
}

output "worker_group_id" {
  description = "The security group id for worker nodes"
  value       = "${openstack_networking_secgroup_v2.worker.id}"
}
