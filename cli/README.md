# infra-cli

Bootstraps and inspects Recomend's tenant cluster. Everything the CLI does
is idempotent — re-running it reconciles rather than recreating.

It does **not** create a cluster: `./kubeconfig` must already point at the
recomend vcluster declared in [lxup/platform](https://github.com/lxup/platform)
(`bun run src/index.ts tenant` there writes it).

```bash
cd cli
bun install
bun start          # interactive menu
bun start install  # install / reconcile the bootstrap layer
bun start status   # check health, offer fixes
```

## Environment

Bun loads `cli/.env` automatically (gitignored). Copy `cli/.env.example` and
fill it in; if you are coming from the old Makefile, this replaces the repo-root
`.env.local` it used to source:

```bash
cp .env.example .env   # then fill in the three values
```

`INFISICAL_PROJECT_ID` is not needed — the project is pinned by `projectSlug`
in `bootstrap/infisical/secretstore.yaml`.

## What `install` does

Steps run in dependency order and stop at the first failure.

| Step | What it does |
|---|---|
| 00 | Check whether ArgoCD is already installed — bootstrap or reconcile |
| 01 | Check `helm` and `kubectl` |
| 02 | Verify `./kubeconfig`: present, API answering, and pointing at the **tenant** rather than the host cluster — it refuses otherwise |
| 03 | Wait for the vcluster's API server to report `/readyz` |
| 04 | Install External Secrets Operator (Helm) |
| 05 | Create the `infisical-auth` Secret |
| 06 | Apply the `infisical` ClusterSecretStore |
| 07 | Install ArgoCD (Helm) |
| 08 | Apply ArgoCD's repository and webhook credentials |
| 09 | Apply `kubernetes/core/root.yaml` — GitOps takes over |

## Why steps 04-06 and 08 are not GitOps

ESO, its ClusterSecretStore and ArgoCD's repository credential form the
bootstrap layer, and it cannot be managed by the tool it installs.

The repository credential is an `ExternalSecret`. If this repo is ever flipped
to private, ArgoCD needs that credential to clone the repo at all — so ArgoCD
cannot be what deploys the operator that resolves it. A root of trust cannot
bootstrap itself from something that depends on it.

Everything downstream of step 09 is GitOps: Traefik, cloudflared,
external-dns, the GHCR pull secret, and every app.
