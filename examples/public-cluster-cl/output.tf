locals {
  k8s_config_path = "~/.kube/config"
  ssh_prefix      = "ssh core@${module.k8s.public_ipv4_addrs[0]} --"

  test_ssh_prefix = <<CMD
ssh -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    core@${module.k8s.public_ipv4_addrs[0]} -- \
  CMD
}

output "tf_test" {
  description = "Used by module tests"

  # Inline `tf_test` output so we do not flood `tf apply` helper
  # Warns user that he probably should not use this output
  # the regex will match all new line ended by a backslash
  value = <<CMD

`# This output is only for test purpose!` \
${replace("${local.test_ssh_prefix} sh -c \"'${module.k8s.etcd_status}'\"", "/\\s*\\\\\\s+/", " ")} \
`# This output is only for test purpose!`
CMD
}

output "helper" {
  description = "This output is a human friendly helper on how to interact with the k8s cluster"

  value = <<HELP
Your kubernetes cluster is up.

Check if cluster is running:

    $ ${indent(6, local.ssh_prefix)} sh -c \"'${indent(6, module.k8s.etcd_status)}'\" && echo 'etcd cluster is running'

    $ ${indent(6, local.ssh_prefix)} sh -c \"'${indent(6, module.k8s.k8s_status)}'\" && echo 'k8s cluster is running'

Configure the client:

    $ ${indent(6, local.ssh_prefix)} ${indent(6, module.k8s.k8s_get_config)} > ${local.k8s_config_path}

To connect to one of the instances:

    ${join( "\n    ", formatlist("$ ssh core@%s", module.k8s.public_ipv4_addrs))}

Run a pod:

    $ ...

Enjoy!
HELP
}