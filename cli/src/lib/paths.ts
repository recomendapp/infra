import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));

/** infra/ — the git repo root (this file lives at cli/src/lib/). */
export const repoRoot = path.resolve(here, "..", "..", "..");

export const hetznerDir = path.join(repoRoot, "hetzner");
export const clusterConfigPath = path.join(hetznerDir, "cluster_config.yaml");
export const kubeconfigPath = path.join(repoRoot, "kubeconfig");

const bootstrap = path.join(repoRoot, "bootstrap");
export const argocdBootstrapValuesPath = path.join(bootstrap, "argocd", "values.yaml");
export const externalSecretsValuesPath = path.join(bootstrap, "external-secrets", "values.yaml");
export const clusterSecretStorePath = path.join(bootstrap, "infisical", "secretstore.yaml");
export const argocdRepoSecretPath = path.join(bootstrap, "argocd", "github-repo.yaml");
export const argocdWebhookSecretPath = path.join(bootstrap, "argocd", "webhook-secret.yaml");

export const coreRootAppPath = path.join(repoRoot, "kubernetes", "core", "root.yaml");
