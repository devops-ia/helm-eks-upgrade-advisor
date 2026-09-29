# Copilot Instructions

## Repository overview

This is a Helm chart repository for [eks-upgrade-advisor](https://github.com/devops-ia/eks-upgrade-advisor) — a one-shot tool that auto-discovers EKS addons and ArgoCD-managed Helm charts, checks their compatibility against a target EKS version, and generates a Markdown upgrade report.

The chart lives at `charts/eks-upgrade-advisor/`. There is no application source code here.

## Commands

### Local template rendering (primary dev workflow)
```bash
helm template eks-upgrade-advisor charts/eks-upgrade-advisor/ \
  --set config.clusterName=my-cluster \
  --set config.targetEksVersion=1.32 \
  --set secrets.copilotCli.token=dummy
```

### Helm dry-run (validates against a cluster)
```bash
helm install eks-upgrade-advisor charts/eks-upgrade-advisor/ --dry-run --namespace test --create-namespace [--set ...]
```

### Lint
```bash
helm lint charts/eks-upgrade-advisor/
```

### Pre-commit (runs helmlint, helm-docs, trailing-whitespace, markdown-toc)
```bash
pre-commit run --all-files
```

## Architecture

### Job, not Deployment
This chart deploys a `batch/v1 Job` (`templates/job.yaml`), not a `Deployment` — the tool
runs to completion once and exits. There is no Service, ServiceMonitor, PodDisruptionBudget
or liveness/readiness probe, unlike a typical devops-ia application chart. Re-running means
`helm upgrade --install` again (a Job's pod template is immutable, so in-place `kubectl edit`
won't work) or `helm uninstall` + `helm install`.

### Report retrieval via stdout, not a volume mount contract
`job.yaml` overrides the image's `ENTRYPOINT` with a shell command that runs the
`eks-upgrade-advisor` console script and then `cat`s `$OUTPUT_PATH` to stdout. This means
`kubectl logs job/<name>` alone returns the full report — no PVC, no `kubectl cp`, no
external storage needed for a tool that runs twice a year. `OUTPUT_PATH` still points at an
`emptyDir` volume mounted at `/output` so the Python code has somewhere durable-within-the-pod
to write before the `cat`.

### RBAC is always-on, not opt-in
Unlike `pr-generator`'s `annotationDiscovery.enabled` gate, this chart's `ClusterRole`/`Role`
granting `get`/`list` on `applications.argoproj.io` (`templates/rbac.yaml`) is created
whenever `rbac.create` and `serviceAccount.create` are both true (the default). Reading
ArgoCD Applications is this tool's core discovery mechanism, not an optional add-on — there
is no meaningful "disabled" state.

`rbac.namespaced: true` switches from a cluster-wide `ClusterRole`/`ClusterRoleBinding` to a
namespace-scoped `Role`/`RoleBinding`; pair it with `config.argocdNamespace` so discovery and
RBAC scope match.

### IRSA, not a chart-managed AWS credential
AWS access is expected via IRSA — `serviceAccount.annotations["eks.amazonaws.com/role-arn"]`.
The chart has no field for inline AWS keys; that IAM role must be provisioned by Terraform
(see the eks-upgrade-advisor README for the minimal read-only policy:
`eks:DescribeCluster`, `eks:ListAddons`, `eks:DescribeAddon`, `eks:DescribeAddonVersions`).

### Copilot CLI token — single Secret, same pattern as pr-generator's provider secrets
`secrets.copilotCli.existingSecret` (production) or `secrets.copilotCli.token` (dev/test,
chart creates `<fullname>-copilot-cli`) — see `templates/secret.yaml`. The key name inside the
Secret is configurable via `secrets.copilotCli.existingSecretKey` (default `gh-token`) and is
injected into the container as `GH_TOKEN`, which the Copilot CLI reads for auth. Only rendered
when `config.llmProvider` is `copilot-cli`.

### Schema validation
`values.schema.json` requires `config.clusterName` and `config.targetEksVersion` — the chart
also enforces both at render time via `required` in `job.yaml` so a missing value fails
`helm template`/`helm install` immediately with a clear error, not a crashing Pod.

## Key conventions

- **Chart version** (`Chart.yaml`) must be bumped on every change to `charts/eks-upgrade-advisor/`. CI releases are triggered by pushes to `main` when chart files change.
- **`helm-docs`** is run via pre-commit. Keep `values.yaml` comments in sync with what `helm-docs` would generate.
- **`extra-manifests.yaml`** renders `extraObjects` — use this to deploy any additional Kubernetes resources alongside the chart without modifying core templates.
- **CI** uses reusable workflows from `devops-ia/.github`. Chart testing (`ct`) is configured in `.github/ct.yaml`; chart releasing (`cr`) in `.github/cr.yaml`.
