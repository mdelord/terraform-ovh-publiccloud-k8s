output "helper" {
  description = "This output is a human friendly helper on how to interact with the k8s cluster"

  value = <<HELP
Your kubernetes cluster is up.

Retrieve k8s configuration locally:

    $ mkdir -p ~/.kube/${var.name}
    $ ssh core@${module.k8s.public_ipv4_addrs[0]} sudo cat /etc/kubernetes/admin.conf > ~/.kube/${var.name}/config
    $ kubectl --kubeconfig ~/.kube/${var.name}/config get nodes

You can also ssh into one of your instances:

    ${indent(4, join( "\n", formatlist("$ ssh core@%s", module.k8s.public_ipv4_addrs)))}

Enjoy!
HELP
}
