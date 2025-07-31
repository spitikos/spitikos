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

### Step 1: Install Argo CD

First, we'll install Argo CD into its own namespace in the cluster.

```bash
# Create the namespace for Argo CD
kubectl create namespace argocd

# Install the latest stable version of Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2: Access the Argo CD Server

For security, the Argo CD API server is not exposed via an Ingress by default. We will use `kubectl port-forward` to access it from our local machine.

1.  **Get the Initial Admin Password:**
    The initial password is automatically generated and stored in a Kubernetes secret. Retrieve it with this command:

    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```
    **Save this password.**

2.  **Access the UI:**
    Open a new terminal and run the port-forward command. This will block the terminal while it's running.

    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```
    You can now access the Argo CD UI by navigating to **https://localhost:8080** in your browser. Log in with the username `admin` and the password you retrieved.

### Step 3: Create the "App of Apps" Structure

We will use the "App of Apps" pattern to manage our applications. This means we will have one "root" Argo CD application that is responsible for managing all our other application definitions. This allows our entire application landscape to be managed from Git.

Create the following directory and files:

1.  **`argocd/`**
2.  **`argocd/root-app.yaml`**
3.  **`argocd/apps/`**
4.  **`argocd/apps/homepage.yaml`**
5.  **`argocd/apps/api-stats.yaml`**
6.  **`argocd/apps/api-whoami.yaml`**

#### `argocd/root-app.yaml`
This is the parent application. It tells Argo CD to look in the `argocd/apps` directory and create an application for every `.yaml` file it finds there.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/ethn1ee/pi.git' # Change this to your repo URL
    targetRevision: HEAD
    path: argocd/apps
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### `argocd/apps/homepage.yaml`
This manifest defines the `pi-homepage` application.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pi-homepage
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: 'https://github.com/ethn1ee/pi.git' # Change this to your repo URL
    targetRevision: HEAD
    path: charts/homepage
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: pi-homepage
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### `argocd/apps/api-stats.yaml`
This manifest defines the `pi-api-stats` application.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pi-api-stats
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: 'https://github.com/ethn1ee/pi.git' # Change this to your repo URL
    targetRevision: HEAD
    path: charts/api/stats
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: pi-api-stats
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### `argocd/apps/api-whoami.yaml`
This manifest defines the `pi-api-whoami` application.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pi-api-whoami
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: 'https://github.com/ethn1ee/pi.git' # Change this to your repo URL
    targetRevision: HEAD
    path: charts/api/whoami
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: pi-api-whoami
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Step 4: Commit and Bootstrap Argo CD

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

### Step 5: Update the CI/CD Workflow

The final step is to adjust the CI workflow. The `update-chart` job in `.github/workflows/release.yaml` is already doing the correct thing by updating `values.yaml` and pushing to the repo. We just need to ensure the commit message is clear and that developers understand this push is what triggers the deployment.

The existing `update-chart` job is sufficient. No changes are needed, but it's critical to understand its new role: it is now a **trigger for Argo CD**, not just a file update.

```yaml
# .github/workflows/release.yaml

# ... (docker-publish job remains the same) ...

  update-chart:
    name: Update Chart
    runs-on: ubuntu-latest
    needs: docker-publish
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Update image tag in values.yaml
        run: |
          # This sed command is correct. It updates the image tag.
          sed -i "s/tag: .*/tag: ${{ inputs.image_tag }}/" ${{ inputs.chart_path }}/values.yaml

      - name: Commit and Push Changes
        run: |
          git config --global user.email "github-actions@github.com"
          git config --global user.name "GitHub Actions"
          git add ${{ inputs.chart_path }}/values.yaml
          # The commit message clearly indicates a new version is being deployed.
          git commit -m "ci: deploy ${{ inputs.image_name }} version ${{ inputs.image_tag }}"
          git push
```

Your GitOps pipeline is now complete.
