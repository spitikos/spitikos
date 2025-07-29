.PHONY: help helm-deps dashboard-token

help:
	@echo "Available targets:"
	@echo "  helm-deps         - Update Helm dependencies for all charts in the 'charts/' directory."
	@echo "  helm-install-all  - Install all Helm charts based on their directory name as the namespace."
	@echo "  dashboard-token   - Generate token for Kubernetes dashboard."

helm-deps:
	@echo "--- Updating Helm dependencies for all charts ---"
	@find ./charts -name "Chart.yaml" -execdir helm dependency update . \;

dash-token:
	@echo "--- Generating token for Kubernetes dashboard ---"
	@kubectl create token -n kube-dashboard admin-user

sync-modules:
	@echo "--- Syncing submodules to latest commit ---"
	@git submodule update --init --recursive --remote
