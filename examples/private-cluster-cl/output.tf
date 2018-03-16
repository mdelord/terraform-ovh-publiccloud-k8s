locals {
  ssh_proxy_command = "-o ProxyCommand='ssh core@${module.network.bastion_public_ip} ncat %h %p'"
}

output "helper" {
  description = "This output is a human friendly helper on how to interact with the k8s cluster"

  value = <<HELP
Your kubernetes cluster is up.

Retrieve k8s configuration locally:

    $ mkdir -p ~/.kube/${var.name}
    $ ssh ${local.ssh_proxy_command} core@${module.k8s.private_ipv4_addrs[0]} sudo cat /etc/kubernetes/admin.conf > ~/.kube/${var.name}/config

As your cluster is not exposed to the Internet, you'll have to be on the same network as your masters
to have kubectl work (eg.: connect through a vpn, access from an edge node):

    $ kubectl --kubeconfig ~/.kube/${var.name}/config get nodes

Or you can ssh into one of your instances:

    ${indent(4, join( "\n", formatlist("$ ssh %s core@%s", local.ssh_proxy_command, module.k8s.private_ipv4_addrs)))}

And run commands from there:

    $ sudo /opt/k8s/bin/kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes

Enjoy!
HELP
}
