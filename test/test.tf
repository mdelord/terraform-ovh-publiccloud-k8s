### add remote state backend in case tests is partially applied & breaks.
### allows further manual destroy or investigation
terraform {
  backend "swift" {
    container = "%%TESTNAME%%"
  }
}

data "template_file" "test_script" {
  template = <<TPL
#!/bin/bash
ETCD_CMD="/opt/etcd/bin/etcdctl --ca-file /opt/etcd/certs/ca.pem --cert-file /opt/etcd/certs/cert.pem --key-file /opt/etcd/certs/cert-key.pem --endpoints https://localhost:2379"
K8S_CMD="sudo /opt/k8s/bin/kubectl --kubeconfig /etc/kubernetes/admin.conf"

# test etcd
if [ $($ETCD_CMD member list | wc -l) == ${var.count} ] && $ETCD_CMD member list | grep -q "isLeader=true"; then
   echo "etcd is up" >&2
else
   echo "etcd is not ready. retry later" >&2
   exit 1
fi

# test k8s cluster
if [ $($K8S_CMD get nodes | grep master | grep -iw ready | wc -l) == ${var.count} ]; then
   echo "k8s is up" >&2
else
   echo "k8s is not ready. retry later" >&2
   exit 1
fi

# create test daemonset
if ($K8S_CMD get daemonsets test >/dev/null); then
   echo test daemonset already exists >&2
else
   echo creating test daemonset >&2
   cat <<EOF | $K8S_CMD create -f -
apiVersion: apps/v1beta2
kind: DaemonSet
metadata:
  name: test
spec:
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
        - name: busybox
          image: busybox
          args:
             - sleep
             - "1000000"
EOF
fi

PODS=$($K8S_CMD get pods --field-selector=status.phase=Running -o json | jq -r '.items[].metadata.name')
# test running pods
if [ "$(echo $PODS | wc -w)" == ${var.count} ]; then
   echo "test daemonset pods are up" >&2
else
   echo "test daemonset pods arent ready. retry later" >&2
   exit 1
fi

IPS=$($K8S_CMD get pods -o json | jq -r '.items[].status.podIP')
# ping all containers from first one
for i in $IPS; do
   if ! ($K8S_CMD exec $(echo $PODS | awk '{print $1}') -- ping -c 1 $i >/dev/null); then
     echo pods cannot ping one another. networking maybe down. >&2
   fi
done
TPL
}

### this is the tests run by the CI
output "tf_test" {
  description = "This output is used by module tests to check if cluster is up & running"
  value       = "${local.test_ssh_prefix} sh /tmp/test.sh"
}
