locals{
  test_ssh_prefix = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ProxyCommand='ssh -o StrictHostKeyChecking=no core@${module.network.bastion_public_ip} ncat %h %p' core@${module.k8s.private_ipv4_addrs[0]} --"
}
