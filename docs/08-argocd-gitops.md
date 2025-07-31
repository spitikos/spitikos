# Documentation: GitOps with Argo CD

This document provides a step-by-step guide to implementing a GitOps workflow using Argo CD. This will automate the deployment of applications whenever their underlying Helm charts are updated in the Git repository.

## 1. Core Concept: From CI-driven to Git-driven Deployments

Currently, the CI/CD pipeline is responsible for both building the Docker image and updating the Helm chart's `values.yaml` file. The deployment itself, however, is still a manual step (e.g., running `helm install` or `helm upgrade`).

By implementing GitOps with Argo CD, we shift the deployment responsibility to an in-cluster operator. The new workflow will be:

1.  A developer pushes code to an application submodule (e.g., `apps/homepage`).
2.  The submodule's CI pipeline builds and pushes a new Docker image.
3.  The CI pipeline updates the image `tag` in the corresponding Helm chart's `values.yaml` file in the parent `pi` repository and commits the change.
4.  **Argo CD**, which constantly monitors the `pi` repository, detects the change to `values.yaml`.
5.  Argo CD automatically "syncs" the application, applying the updated Helm chart to the cluster. The new version is now live.

The Git repository becomes the single source of truth for the desired state of the cluster.

---

## 2. Implementation Plan

### Step 1: Add Argo CD Helm Repository

First, we add the official Argo Project Helm repository to Helm. This only needs to be done once.

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### Step 2: Configure Argo CD for Traefik Ingress

To integrate with our Traefik and Cloudflare setup, we need to configure the Argo CD Helm chart. We will create a dedicated values file to manage this configuration.

Create the file `argocd/values.yaml` with the following content:

```yaml
# argocd/values.yaml
server:
  # Allow the server to accept insecure, plain HTTP traffic
  # This is safe because TLS is terminated at our ingress (Traefik/Cloudflare)
  insecure: true

  # Ingress configuration
  ingress:
    enabled: true
    # We use IngressRoute, so we must specify the ingressClassName
    ingressClassName: traefik
    hosts:
      # The public URL for the Argo CD UI
      - pi.taehoonlee.dev
    paths:
      # The path for the Argo CD UI
      - /argocd
    # Required to make IngressRoute work instead of the default Ingress object
    annotations:
      kubernetes.io/ingress.class: traefik
```

### Step 3: Install Argo CD via Helm

Now, install Argo CD using the Helm chart, applying our custom configuration from the `values.yaml` file.

```bash
# Create the namespace for Argo CD if it doesn't exist
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install the chart
helm install argocd argo/argo-cd \
  --namespace argocd \
  -f argocd/values.yaml \
  --wait
```

### Step 4: Access the Argo CD UI

With the ingress configured, you can now access the Argo CD UI directly from its public URL:

**https://pi.taehoonlee.dev/argocd**

### Step 5: Get the Initial Admin Password

The initial password is automatically generated and stored in a Kubernetes secret. Retrieve it with this command:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
Log in to the UI with the username `admin` and this password.

### Step 6: Create the "App of Apps" Structure

We will use the "App of Apps" pattern to manage our applications. This means we will have one "root" Argo CD application that is responsible for managing all our other application definitions. This allows our entire application landscape to be managed from Git.

Create the following directory and files:

1.  **`argocd/apps/`**
2.  **`argocd/apps/homepage.yaml`**
3.  **`argocd/apps/api-stats.yaml`**
4.  **`argocd/apps/api-whoami.yaml`**
5.  **`argocd/root-app.yaml`** (This should be in the `argocd` directory, not `argocd/apps`)

*(The content for these files remains the same as previously defined)*

### Step 7: Commit and Bootstrap Argo CD

1.  **Commit the new files:**
    Add the `argocd` directory and all its contents to Git, commit, and push.

    ```bash
    git add argocd/
    git commit -m "feat: Add ArgoCD application manifests"
    git push
    ```

2.  **Apply the root application:**
    Now, we manually apply the `root-app.yaml` file to the cluster. This is the **only manual apply** we will do. It bootstraps the entire process.

    ```bash
    kubectl apply -f argocd/root-app.yaml -n argocd
    ```

Once applied, go to the Argo CD UI. You will see the `root` application, which will in turn create the `pi-homepage`, `pi-api-stats`, and `pi-api-whoami` applications. They will automatically sync and deploy the current versions of your charts from the repository.

### Step 8: Update the CI/CD Workflow

The final step is to adjust the CI workflow. The `update-chart` job in `.github/workflows/release.yaml` is already doing the correct thing by updating `values.yaml` and pushing to the repo. We just need to ensure the commit message is clear and that developers understand this push is what triggers the deployment.

The existing `update-chart` job is sufficient. No changes are needed, but it's critical to understand its new role: it is now a **trigger for Argo CD**, not just a file update.

Your GitOps pipeline is now complete.
