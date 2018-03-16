locals {
  test_ssh_prefix = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@${module.k8s.public_ipv4_addrs[0]} --"
}
