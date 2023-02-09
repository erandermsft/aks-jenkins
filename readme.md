Set up cluster in Sandboxed subscription with Kubenet networking and autscaling configured.
Use two node pools with different node sizes
Install Cloudbees CI in its own namespace (if, for some reason, this does not work, fall back to installing Jenkins on a VM)
Set up team namespaces (Team A/B)
Set up Jenkins Kubernetes Plugin, deploy to namespace TEAM A
Import your build container images to ACR
Test out builds + cluster autoscaler
Target different node pools based on workload type 






Persistent storage, share between containers in the same build (read/write-many 100s of thousands of small files). Using NFS share today and not PVC:s bceause of reasons.
Billing per namespace (or team, really) is important
https://github.com/Azure/kubernetes-hackfest/tree/master/labs/monitoring-logging/kubecost