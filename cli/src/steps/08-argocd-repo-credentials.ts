import type { ListrTask } from "listr2";
import { execa } from "execa";
import type { InstallCtx } from "../lib/context.js";
import {
  argocdRepoSecretPath,
  argocdWebhookSecretPath,
  kubeconfigPath,
} from "../lib/paths.js";
import { externalSecretReady } from "../lib/kubectl.js";
import { retry } from "../lib/retry.js";

/**
 * Doc: this is the step pave does not have, because its repo is public and
 * ArgoCD needs no credentials to read it. Here the repo may be flipped to
 * private at any time, and ArgoCD would then be unable to clone it - so the
 * repository credential has to exist before the root app is applied, and it
 * has to come from outside ArgoCD. Hence ESO and the ClusterSecretStore being
 * installed in the steps above rather than by ArgoCD itself.
 *
 * Waits on the ExternalSecret reporting Ready, not on the Secret existing: a
 * leftover Secret from an earlier run would otherwise read as success while
 * ESO was in fact failing to authenticate.
 */
export const argocdBootstrapSecretsStep: ListrTask<InstallCtx> = {
  title: "Create ArgoCD repository and webhook credentials",
  task: async (_ctx, task) => {
    const env = { KUBECONFIG: kubeconfigPath };

    for (const [label, manifest, name] of [
      ["repository", argocdRepoSecretPath, "github-repo"],
      ["webhook", argocdWebhookSecretPath, "argocd-webhook-secret"],
    ] as const) {
      task.output = `applying ${label} ExternalSecret`;
      await execa("kubectl", ["apply", "-f", manifest], { env });

      await retry(
        async () => {
          if (!(await externalSecretReady("argocd", name))) {
            throw new Error(`ExternalSecret ${name} not Ready yet`);
          }
          task.output = `${name} synced`;
        },
        { attempts: 24, delayMs: 5000 },
      );
    }

    task.title = "ArgoCD can read the repo (works whether it is public or private)";
  },
};
