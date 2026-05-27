# Makefile — Azure Production Infrastructure
# Usage: make <target> ENV=dev|staging|prod

ENV ?= dev
TFVARS := environments/$(ENV)/terraform.tfvars
PLAN_FILE := /tmp/tfplan-$(ENV)

.DEFAULT_GOAL := help

.PHONY: help bootstrap init validate fmt lint plan apply destroy output clean

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Create Azure remote state backend (run once)
	@bash scripts/bootstrap.sh

init: ## Initialize Terraform for ENV
	terraform init -reconfigure -backend-config="key=$(ENV)/infrastructure.tfstate"

validate: init ## Validate Terraform configuration
	terraform validate

fmt: ## Format all Terraform files
	terraform fmt -recursive

lint: ## Run tfsec security scan
	@command -v tfsec >/dev/null || (echo "Installing tfsec..." && brew install tfsec)
	tfsec . --tfvars-file $(TFVARS)

plan: init ## Plan infrastructure changes for ENV
	terraform plan \
		-var-file=$(TFVARS) \
		-var="subscription_id=$(ARM_SUBSCRIPTION_ID)" \
		-var="tenant_id=$(ARM_TENANT_ID)" \
		-out=$(PLAN_FILE) \
		-detailed-exitcode

apply: ## Apply planned changes for ENV (requires prior plan)
	terraform apply $(PLAN_FILE)

apply-auto: init ## Plan + Apply without confirmation (CI use only)
	terraform apply \
		-var-file=$(TFVARS) \
		-var="subscription_id=$(ARM_SUBSCRIPTION_ID)" \
		-var="tenant_id=$(ARM_TENANT_ID)" \
		-auto-approve

destroy: ## Destroy all resources for ENV (DANGEROUS)
	@echo "⚠️  About to DESTROY $(ENV) infrastructure. Type 'yes' to confirm:"
	@read CONFIRM && [ "$$CONFIRM" = "yes" ] || (echo "Aborted." && exit 1)
	terraform destroy \
		-var-file=$(TFVARS) \
		-var="subscription_id=$(ARM_SUBSCRIPTION_ID)" \
		-var="tenant_id=$(ARM_TENANT_ID)" \
		-auto-approve

output: ## Show Terraform outputs for ENV
	terraform output -json | jq .

kubeconfig: ## Get AKS kubeconfig
	@eval $$(terraform output -raw kubeconfig_command)
	kubectl get nodes

clean: ## Remove local Terraform files
	rm -rf .terraform .terraform.lock.hcl $(PLAN_FILE) terraform.tfstate*
