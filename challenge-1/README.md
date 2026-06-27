# Challenge 1: Provision Azure VNET Infrastructure with Terraform

## Requirements

Build a reusable Terraform module to deploy an Azure Virtual Network (VNET), use it to create multiple environments (dev/prod), and add additional resources (VM + Storage Account).

## Solution Architecture

```
terraform-azurerm-vnet (reusable module, v1.0.0)
  └── challenge-1/ (this folder — deployment code)
        ├── envs/dev.tfvars    → eastus
        └── envs/prod.tfvars   → westeurope
```

### Repos

| Repo | Purpose |
|---|---|
| [terraform-azurerm-vnet](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet) | Reusable VNET module with subnets, NSGs, DDoS protection, enforced tags |

## Design Decisions

### Why Resource Groups over Subscriptions?
Resource Groups provide environment isolation at lower cost and complexity. Subscriptions are better when you need hard billing boundaries or IAM separation — overkill for this use case.

### Reusable Module Features
- **Flexible subnets** via map variable with optional service endpoints and private endpoint policies
- **Per-subnet NSGs** with configurable rules and auto-appended DenyAllInbound rule
- **Optional DDoS protection** plan association
- **Input validation** on VNET name format and address space
- **Enforced tags** — `ManagedBy=terraform` always applied
- **Automated documentation** via terraform-docs in pre-commit hooks
- **Tested** — 7 native Terraform test cases (plan-mode, no credentials needed)

### Naming Convention
`{resource_type}-{project}-{environment}-{region_short}` — e.g., `rg-demo-dev-eus`, `vnet-demo-prod-weu`

### Tag Enforcement
- `ManagedBy=terraform` enforced at module level (can't be overridden)
- `Environment`, `Project`, `ApplicationId`, `Region` set via locals

### Feature Flags
Resources can be toggled per environment via tfvars:
- `enable_vm` — create/skip the Linux VM
- `enable_storage` — create/skip the Storage Account
- `create_public_ip` — public IP for VM (dev: true, prod: false)

### Code Quality Tools
- **pre-commit**: terraform fmt, validate, tflint, terraform-docs
- **tflint**: Azure RM ruleset with naming convention, documented variables/outputs enforcement

## Usage

```bash
# Set Azure credentials
az login
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
export TF_VAR_vm_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)

# Bootstrap state storage (first time only)
./scripts/bootstrap-state.sh

# Deploy dev
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# Deploy prod
terraform init -reconfigure -backend-config=backends/prod.backend.hcl
terraform plan -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

## CI/CD Pipeline

| Event | Branch | Action |
|---|---|---|
| PR → `dev` | dev | Lint + Plan dev |
| Push → `dev` | dev | Apply dev |
| PR → `main` | main | Lint + Plan prod |
| Push → `main` | main | Apply prod (with approval) |

Plan output is saved as artifact and posted as PR comment.
