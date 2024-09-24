# karpenter-eks-example

This is an example of how to deploy Karpenter on EKS using Terraform.

## Prerequisites

1. Install terraform.
2. Install kubectl.
3. Install helm & helmfile.

## Steps

1. Deploy EKS cluster using terraform inside `01-eks-cluster` directory.
2. `aws eks --region eu-west-1 update-kubeconfig --name example-cluster`
3. Install CRDs for AWS Load Balancer Controller. `kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"`
4. Deploy AWS Load Balancer Controller, using helmfile inside `02-helmfile-installations` directory; `helmfile apply -f helmfile.yaml`
5. Deploy karpenter manifest `kubectl apply -f 03-manifests/karpenter/nodepool.yaml`

## All done!

After following the steps above, you should have a working EKS cluster with Karpenter running on it. You can deploy workloads to the cluster and Karpenter will automatically scale the nodes based on the workload.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
          resources:
            requests:
              cpu: 1
          securityContext:
            allowPrivilegeEscalation: false
```
