locals{
  test_ssh_prefix = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ProxyCommand='ssh -o StrictHostKeyChecking=no core@${module.network.bastion_public_ip} ncat %h %p' core@${module.k8s.private_ipv4_addrs[0]} --"
}

resource "null_resource" "test" {
  connection {
    host                = "${module.k8s.private_ipv4_addrs[0]}"
    user                = "core"
    bastion_host        = "${module.network.bastion_public_ip}"
    bastion_user        = "core"
  }

  provisioner "file" {
    content = "${data.template_file.test_script.rendered}"
    destination = "/tmp/test.sh"
  }
}
