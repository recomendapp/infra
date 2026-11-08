# infra

GitOps for Recomend: ArgoCD watching this repo, and everything else deployed
as ArgoCD `Application`s from `kubernetes/`.

This repo does not create its cluster. It runs as a tenant in a virtual
cluster declared in [lxup/platform](https://github.com/lxup/platform), and the
only thing crossing that boundary is a kubeconfig — see `cli/src/lib/paths.ts`.

Reachable from the internet through a Cloudflare tunnel, not an inbound port:
the cluster has no public address of its own. See
`kubernetes/core/services/cloudflared/secret.yaml` for the one piece of setup
that lives in Cloudflare's dashboard rather than here.

```bash
cd cli && bun install && bun start
```

See `cli/README.md` for what each install step does and why the bootstrap layer
is deliberately not GitOps.

## Layout

```
bootstrap/     one-shot manifests and Helm values for the bootstrap layer
               (ArgoCD, External Secrets Operator, the infisical store)
kubernetes/
  core/        the cluster's own infra: ArgoCD config, Traefik, cloudflared,
               external-dns, the GHCR pull secret
  apps/        the Recomend services: backend, web-app, umami, martin, prefect
cli/           the bootstrap/status CLI
runner-images/ Dockerfile for the self-hosted Android CI runner - kept, but
               no longer deployed: one runner asks for 12 Gi and 6 CPU and the
               platform's nodes have 14.7 Gi each, so CI runs on GitHub-hosted
               runners for now
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
