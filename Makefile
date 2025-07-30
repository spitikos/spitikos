.PHONY: help helm-deps dashboard-token drain-node uncordon-node

help:
	@echo "Available targets:"
	@echo "  helm-deps         - Update Helm dependencies for all charts in the 'charts/' directory."
	@echo "  helm-install-all  - Install all Helm charts based on their directory name as the namespace."
	@echo "  dashboard-token   - Generate token for Kubernetes dashboard."
	@echo "  drain-node        - Safely drain the Kubernetes node before shutdown."
	@echo "  uncordon-node     - Mark the Kubernetes node as schedulable to resume workloads."

helm-deps:
	@echo "--- Updating Helm dependencies for all charts ---"
	@find ./charts -name "Chart.yaml" -execdir helm dependency update . \;

dash-token:
	@echo "--- Generating token for Kubernetes dashboard ---"
	@kubectl create token -n kube-dashboard admin-user

drain-node:
	@echo "--- Draining node 'pi' ---"
	@kubectl drain pi --ignore-daemonsets --delete-emptydir-data

uncordon-node:
	@echo "--- Uncordoning node 'pi' ---"
	@kubectl uncordon pi

sync-modules:
	@echo "--- Syncing submodules to latest commit ---"
	@git submodule update --init --recursive --remote
	@git add .
	@git commit -m "bump submodules to latest"
	@git push
