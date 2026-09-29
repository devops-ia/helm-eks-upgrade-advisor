# Testing guide for eks-upgrade-advisor Helm Chart

## Prerequisites

```bash
helm repo add devops-ia https://devops-ia.github.io/helm-eks-upgrade-advisor
helm repo update
```

## Configuration testing

### 1. Dry-run with inline Copilot token (dev/test only)

```bash
helm install eks-upgrade-advisor devops-ia/eks-upgrade-advisor \
  --namespace eks-upgrade-advisor-test \
  --create-namespace \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32 \
  --set secrets.copilotCli.token=ghp_yourtoken \
  --dry-run
```

### 2. Using an existing Kubernetes Secret (recommended for production)

```bash
kubectl create secret generic eks-upgrade-advisor-copilot \
  --from-literal=gh-token=ghp_yourtoken \
  -n eks-upgrade-advisor

helm install eks-upgrade-advisor devops-ia/eks-upgrade-advisor \
  --namespace eks-upgrade-advisor \
  --create-namespace \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32 \
  --set secrets.copilotCli.existingSecret=eks-upgrade-advisor-copilot
```

### 3. IRSA role for AWS access

```bash
helm install eks-upgrade-advisor devops-ia/eks-upgrade-advisor \
  --namespace eks-upgrade-advisor-test \
  --create-namespace \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32 \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::123456789012:role/eks-upgrade-advisor-ro
```

### 4. Restricting ArgoCD discovery to one namespace

```bash
helm install eks-upgrade-advisor devops-ia/eks-upgrade-advisor \
  --namespace eks-upgrade-advisor-test \
  --create-namespace \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32 \
  --set config.argocdNamespace=argocd \
  --set rbac.namespaced=true
```

## Validation tests

### 1. Job completion

```bash
kubectl wait --for=condition=complete job/eks-upgrade-advisor -n eks-upgrade-advisor-test --timeout=1800s
```

### 2. Report output

```bash
kubectl logs job/eks-upgrade-advisor -n eks-upgrade-advisor-test
```

### 3. RBAC verification

```bash
kubectl auth can-i list applications.argoproj.io \
  --as=system:serviceaccount:eks-upgrade-advisor-test:eks-upgrade-advisor
```

## Template rendering (local)

```bash
helm template eks-upgrade-advisor charts/eks-upgrade-advisor/ \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32 \
  --set secrets.copilotCli.token=dummy
```

## Clean-up

```bash
helm uninstall eks-upgrade-advisor -n eks-upgrade-advisor-test
kubectl delete namespace eks-upgrade-advisor-test
```
