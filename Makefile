.PHONY: help helm-deps dashboard-token drain-node uncordon-node

help: ## Print help
	@awk 'BEGIN {FS=":.*##";printf"Makefile\n\nUsage:\n  make [command]\n\nAvailable Commands:\n"}/^[a-zA-Z_0-9-]+:.*?##/{printf"  %-40s%s\n",$$1,$$2}/^##@/{printf"\n%s\n",substr($$0,5)}' $(MAKEFILE_LIST)

helm-deps: ## Update Helm dependencies for all charts
	@echo "--- Updating Helm dependencies for all charts ---"
	@find ./charts -name "Chart.yaml" -execdir helm dependency update . \;

dash-token: ## Generate token for Kubernetes dashboard
	@echo "--- Generating token for Kubernetes dashboard ---"
	@kubectl create token -n kube-dashboard admin-user
