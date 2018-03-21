resource "null_resource" "post_install_k8s" {
  count = "${var.count}"

  triggers {
    trigger = "${element(var.triggers, count.index)}"
  }

  connection {
    host                = "${element(var.ipv4_addrs, count.index)}"
    user                = "${var.ssh_user}"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /tmp/install-k8s"]
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/install-k8s"
  }

  provisioner "remote-exec" {
    inline = <<EOF
/bin/sh /tmp/install-k8s/install-k8s \
  --k8s-version ${var.k8s_version} \
  --calico-node-version ${var.calico_node_version} \
  --calico-cni-version ${var.calico_cni_version} \
  --flannel-version ${var.flannel_version} \
  --kubedns-version ${var.kubedns_version} \
  --pause-version ${var.pause_version} \
  --cni-plugins-version ${var.k8s_cni_plugins_version} \
  --sha1sum-cni-plugins ${var.k8s_sha1sum_cni_plugins} \
  --sha1sum-kubeadm ${var.k8s_sha1sum_kubeadm} \
  --sha1sum-kubelet ${var.k8s_sha1sum_kubelet} \
  --sha1sum-kubectl ${var.k8s_sha1sum_kubectl}
EOF
  }
}

output "install_ids" {
  value = ["${null_resource.post_install_k8s.*.id}"]
}
