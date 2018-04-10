locals {
  test_ssh_prefix = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no core@${module.k8s.public_ipv4_addrs[0]} --"
}

resource "null_resource" "test" {
  connection {
    host                = "${module.k8s.public_ipv4_addrs[0]}"
    user                = "core"
  }

  provisioner "file" {
    content = "${data.template_file.test_script.rendered}"
    destination = "/tmp/test.sh"
  }
}
