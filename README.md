# infra

GitOps for Recomend: a Hetzner k3s cluster, ArgoCD watching this repo, and
everything else deployed as ArgoCD `Application`s from `kubernetes/`.

```bash
cd cli && bun install && bun start
```

See `cli/README.md` for what each install step does and why the bootstrap layer
is deliberately not GitOps.

## Layout

```
bootstrap/     one-shot manifests and Helm values for the bootstrap layer
               (ArgoCD, External Secrets Operator, the infisical store)
hetzner/       hetzner-k3s cluster config - the shape of the cluster
kubernetes/
  core/        the cluster's own infra: cert-manager, external-dns, ArgoCD
               config, Traefik and hcloud patches, monitoring, CI runners,
               the GHCR pull secret
  apps/        the Recomend services: backend, web-app, umami, martin, prefect
cli/           the bootstrap/status CLI
runner-images/ Dockerfile for the self-hosted Android CI runner
```

`core` and `apps` are each their own ArgoCD app-of-apps (`core/root.yaml`, and
`core/applications/apps-root.yaml` nesting into `apps/applications`), so the
services can be added or removed without touching the layer underneath them.

## Secrets

Infisical is the single source of truth. In-cluster, External Secrets Operator
pulls from it through a `ClusterSecretStore` named `infisical`, authenticated
with a Machine Identity. Each service declares an `ExternalSecret` listing which
Infisical keys map to which local Secret keys — no ciphertext is committed here.

## Backups

Three CronJobs dump straight to Cloudflare R2: `backend/main-postgres-backup`,
`backend/rustfs-backup` and `default/umami-postgres-backup`. There is no Velero;
it only ever captured manifests, which this repo already holds.
