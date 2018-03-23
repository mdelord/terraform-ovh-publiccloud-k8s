data "ignition_systemd_unit" "docker_service" {
  name = "docker.service"
  enabled = true
}

data "ignition_systemd_unit" "kubelet_service" {
  name = "kubelet.service"
  enabled = true
  content = <<CONTENT
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]

ExecStart=/opt/k8s/bin/kubelet --address=0.0.0.0 \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf \
  --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true \
  --network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin \
  --cluster-dns=${cidrhost(var.service_cidr, 10)} --cluster-domain=${var.datacenter}.${var.domain} \
  --authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt \
  --rotate-certificates=true
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
CONTENT
}

data "ignition_file" "kubeconfig" {
  count = "${var.ignition_mode ? var.count : 0 }"
  path = "/etc/kubernetes/kubeadm/config.yaml"
  filesystem = "root"
  content {
    content = <<CONTENT
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
etcd:
  endpoints:
  - https://127.0.0.1:2379
  caFile: /opt/etcd/certs/ca.pem
  certFile: /opt/etcd/certs/cert.pem
  keyFile: /opt/etcd/certs/cert-key.pem
kubeProxy:
  config:
    mode: iptables
networking:
  dnsDomain: ${var.datacenter}.${var.domain}
  serviceSubnet: ${var.service_cidr}
  podSubnet: ${var.pod_cidr}
kubernetesVersion: 1.9.2
#DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.'
nodeName: ${replace(lower(var.name), "/[^0-9a-z.-]/", "-")}-${count.index}
authorizationModes:
- Node
- RBAC
selfHosted: false
apiServerCertSANs:
${join("\n", formatlist("- %s", var.ipv4_addrs))}
certificatesDir: "/etc/kubernetes/pki"
CONTENT
  }
}

data "ignition_systemd_unit" "k8s-init-service" {
  name = "k8s-init.service"
  content = <<CONTENT
[Unit]
Description=Bootstrap a Kubernetes cluster with kubeadm
${var.master_mode ? "Wants=etcd.service" : "Wants=etcd-get-certs.service"}
ConditionPathExists=!/opt/k8s/init.done

[Service]
RemainAfterExit=true
Restart=on-failure
StartLimitInterval=0
RestartSec=10
Environment=MASTER_MODE=${var.master_mode}
Environment=WORKER_MODE=${var.worker_mode}
Environment=ETCD_ENDPOINTS=${var.etcd_endpoints}
Environment=API_ENDPOINT=${var.api_endpoint}
${var.master_mode ? "ExecStartPre=/usr/bin/systemctl is-active etcd.service" : ""}
ExecStart=/opt/k8s/k8s-init

[Install]
WantedBy=multi-user.target
CONTENT
}

data "template_file" "cni-rbac" {
  template = "${file("${path.module}/cni-rbac.yaml.tpl")}"
}

data "ignition_file" "cni-rbac" {
  path = "/etc/kubernetes/cni/cni-rbac.yaml"
  filesystem = "root"
  content {
    content = "${data.template_file.cni-rbac.rendered}"
  }
}

data "template_file" "cni-manifest" {
  template = "${file("${path.module}/cni-manifest.yaml.tpl")}"
  vars {
    pod_cidr = "${var.pod_cidr}"
  }
}

data "ignition_file" "cni-manifest" {
  filesystem = "root"
  path = "/etc/kubernetes/cni/cni-manifest.yaml"
  content {
    content = "${data.template_file.cni-manifest.rendered}"
  }
}

data "ignition_systemd_unit" "etcd-get-certs-dropin" {
  name = "etcd-get-certs.service"
  dropin {
    name = "cfssl.conf"
    content = <<CONTENT
[Service]
Environment=CFSSL_ENDPOINT=${var.cfssl_endpoint}
CONTENT
  }
}
