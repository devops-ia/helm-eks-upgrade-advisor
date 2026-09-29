# helm eks-upgrade-advisor

Helm chart for [eks-upgrade-advisor](https://github.com/devops-ia/eks-upgrade-advisor) — auto-discovers EKS addons and ArgoCD-managed Helm charts and generates an upgrade compatibility report.

## Usage

Charts are available in:

* [Chart Repository](https://helm.sh/docs/topics/chart_repository/)
* [OCI Artifacts](https://helm.sh/docs/topics/registries/)

## TL;DR

```bash
helm repo add eks-upgrade-advisor https://devops-ia.github.io/helm-eks-upgrade-advisor
helm repo update
helm install [RELEASE_NAME] eks-upgrade-advisor/eks-upgrade-advisor \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32
```

## Introduction

`eks-upgrade-advisor` inventories an EKS cluster's addons and ArgoCD-deployed Helm charts,
cross-checks their compatibility against a target EKS/Kubernetes version, flags deprecated
Kubernetes APIs, and summarizes the official changelog — all in one Markdown report. It runs
as a **one-shot `Job`**, not a long-running service: the report is meant for a human to read
before performing the actual upgrade, which this tool does not do.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.x
- ArgoCD installed, with the `applications.argoproj.io` CRD present
- An IAM role (IRSA) granting `eks:DescribeCluster`, `eks:ListAddons`, `eks:DescribeAddon`,
  `eks:DescribeAddonVersions` — read-only, nothing else
- A GitHub token with a Copilot license assigned, for the `copilot-cli` LLM provider

## Installing the chart

```bash
helm install eks-upgrade-advisor devops-ia/eks-upgrade-advisor \
  --namespace eks-upgrade-advisor \
  --create-namespace \
  --set config.clusterName=prod-eu \
  --set config.targetEksVersion=1.32 \
  --set config.awsRegion=eu-west-1 \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::123456789012:role/eks-upgrade-advisor-ro \
  --set secrets.copilotCli.existingSecret=eks-upgrade-advisor-copilot-token
```

### Following the run

```bash
kubectl wait --for=condition=complete job/eks-upgrade-advisor -n eks-upgrade-advisor --timeout=1800s
kubectl logs job/eks-upgrade-advisor -n eks-upgrade-advisor
```

The full Markdown report is printed to stdout at the end of the run — no need to `kubectl cp`
anything out.

## Values

See [`charts/eks-upgrade-advisor/values.yaml`](charts/eks-upgrade-advisor/values.yaml) for
the full list of configurable values, and
[`values.schema.json`](charts/eks-upgrade-advisor/values.schema.json) for validation.

## License

MIT — see [LICENSE](LICENSE).
