# Challenge 1: Provision Azure VNET Infrastructure with Terraform

## Objective

Build a reusable Terraform module to deploy an Azure Virtual Network (VNET), use it to create multiple environments (dev/prod), and add additional resources (VM + Key Vault).

## Approach

The solution is split into two layers:

1. **Reusable Module** ([terraform-azurerm-vnet](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet)) — a generic, versioned VNET module published as a separate repo. It provisions networking resources (VNET, subnets, NSGs) with enforced security defaults, and is consumed via git source with a pinned tag (`v1.0.0`).

2. **Deployment Code** (this folder) — environment-specific configuration that calls the module with per-environment tfvars. It adds additional resources (Linux VM, Key Vault) and manages state in isolated Azure Storage backends per environment.

The key principle is **separation of concerns** — the module knows nothing about environments; the deployment code knows nothing about how networking is implemented internally.

## Architecture

```
terraform-azurerm-vnet (reusable module, v1.0.0)
  │
  └── azure-challenges/challenge-1/ (deployment code)
        ├── envs/dev.tfvars     → eastus       (rg-demo-dev-eus)
        ├── envs/prod.tfvars    → westeurope   (rg-demo-prod-weu)
        ├── backends/dev.hcl    → rg-tfstate-dev-ci36432  / sttfstatedevci36432
        └── backends/prod.hcl   → rg-tfstate-prod-ci36432 / sttfstateprodci36432
```

### Resources Deployed Per Environment

| Resource | Details |
|---|---|
| Resource Group | `rg-demo-{env}-{region}` |
| Virtual Network | 3 subnets (default, compute, storage) + privateendpoints (dev) |
| Network Security Groups | Per-subnet NSGs with inbound SSH + outbound rules + auto-appended DenyAllInbound |
| Linux Virtual Machine | Ubuntu 22.04 LTS Gen2, SSH-key auth, conditional public IP |
| Key Vault | RBAC-enabled, soft delete, conditional purge protection |

## Design Decisions

### Why Resource Groups over Subscriptions?

Resource Groups provide environment isolation at lower cost and complexity. Each environment gets its own RG (`rg-demo-dev-eus`, `rg-demo-prod-weu`) with clear naming and tagging. Subscriptions are better when you need hard billing boundaries or IAM separation — overkill for this use case but recommended for large enterprises.

### Reusable Module Design

The [terraform-azurerm-vnet](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet) module is designed for flexibility:

- **Configurable subnets** — map variable with optional service endpoints and private endpoint policies
- **Per-subnet NSGs** — configurable inbound/outbound rules passed as a map of lists
- **Auto-appended DenyAllInbound** — default-deny posture, toggleable via `enforce_deny_all_inbound`
- **Optional DDoS protection** — plan association via optional variable
- **Enforced tags** — `ManagedBy=terraform` is always applied and cannot be overridden by consumers
- **Input validation** — VNET name format and address space validated at plan time
- **Automated documentation** — terraform-docs generates input/output tables via pre-commit hook
- **Tested** — 7 native Terraform test cases (`terraform test`), run in CI without credentials

### Naming Convention

`{resource_type}-{project}-{environment}-{region_short}`

Examples: `rg-demo-dev-eus`, `vnet-demo-prod-weu`, `kv-demo-prod-weu-ci36432`

Region abbreviations are mapped in `locals.tf` (eastus → eus, westeurope → weu, etc.) for consistent, readable resource names.

### Tag Strategy

All resources receive 5 tags via `common_tags` in locals:

| Tag | Source | Purpose |
|---|---|---|
| `Environment` | `var.environment` | Identify dev/prod for cost filtering |
| `Project` | `var.project` | Group resources by project |
| `ApplicationId` | `var.application_id` | Link to CMDB/service catalog |
| `ManagedBy` | Hardcoded `terraform` | Prevent manual modification confusion |
| `Region` | `var.location` | Explicit region tag for cross-region queries |

The module additionally enforces `ManagedBy=terraform` at the module level — consumers cannot override it.

### Feature Flags

Resources are toggled per environment via boolean variables in tfvars:

- `enable_vm` — create/skip the Linux VM
- `enable_keyvault` — create/skip the Key Vault
- `create_public_ip` — public IP for VM (dev only)

### Per-Environment NSG Rules

Base inbound rules (SSH) are defined in `locals.tf`. Environment-specific outbound rules are injected via `extra_nsg_rules` in tfvars and merged with the base rules:

- **Dev** — Allow outbound HTTPS (443) + HTTP (80) + DenyAllOutbound
- **Prod** — Allow outbound HTTPS (443) only + DenyAllOutbound (no unencrypted traffic)

### State Management

Each environment has its own Azure Storage backend — separate resource groups and storage accounts:

| Environment | Resource Group | Storage Account | State Key |
|---|---|---|---|
| Dev | `rg-tfstate-dev-ci36432` | `sttfstatedevci36432` | `vnet-dev.terraform.tfstate` |
| Prod | `rg-tfstate-prod-ci36432` | `sttfstateprodci36432` | `vnet-prod.terraform.tfstate` |

Bootstrap script (`scripts/bootstrap-state.sh`) creates these idempotently with `Environment` tags.

### Provider Versioning

| Component | Constraint | Rationale |
|---|---|---|
| Terraform | `>= 1.9.0` | Required for azurerm 4.x |
| azurerm (module) | `~> 4.0` | Flexible for consumers |
| azurerm (deployment) | `~> 4.79` | Pinned to minor for reproducible builds |

## Environments

| | Dev | Prod |
|---|---|---|
| **Region** | eastus | westeurope |
| **VM Size** | Standard_D2ds_v7 | Standard_D2as_v6 |
| **VM Image** | Ubuntu 22.04 LTS (Jammy) | Ubuntu 22.04 LTS (Jammy) |
| **Public IP** | Yes | No |
| **SSH Access** | Any (`*`) | VNET only (`10.0.0.0/8`) |
| **Outbound Rules** | HTTPS + HTTP + DenyAll | HTTPS only + DenyAll |
| **Key Vault Purge Protection** | Disabled (7-day retention) | Enabled (90-day retention) |
| **OS Disk** | Standard_LRS | Standard_LRS |

## Code Quality

| Tool | Purpose |
|---|---|
| **pre-commit** | Runs terraform fmt, validate, tflint, terraform-docs on every commit |
| **tflint** | Azure RM plugin enforcing naming conventions, documented variables/outputs, type safety |
| **terraform test** | 7 plan-mode test cases in the VNET module (no credentials needed) |
| **GitHub Actions** | Lint + validate on every PR, plan posted as PR comment |

## CI/CD Pipeline

Separate workflows per environment — only the relevant environment's pipeline triggers:

| Event | Workflow | Action |
|---|---|---|
| PR → `dev` | `challenge-1-dev.yml` | Lint + Plan (posted as PR comment, saved as artifact) |
| Merge → `dev` | `challenge-1-dev.yml` | Plan + Apply to dev |
| PR → `main` | `challenge-1-prod.yml` | Lint + Plan (posted as PR comment, saved as artifact) |
| Merge → `main` | `challenge-1-prod.yml` | Plan + Apply to prod (environment approval required) |

### Release Flow

```
feature branch ── PR → dev ── review plan ── squash merge ── apply to dev
                                                                │
                                              PR → main ── review plan ── merge commit ── apply to prod
```

- **Feature → dev**: squash and merge (clean up feature commits)
- **Dev → main**: merge commit (preserve shared history, avoid duplicate commits)
- **Prod apply**: gated by GitHub environment protection (required reviewer approval)

## Usage

```bash
# Set Azure credentials
az login
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
export TF_VAR_vm_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)

# Bootstrap state storage (first time only)
./scripts/bootstrap-state.sh dev
./scripts/bootstrap-state.sh prod

# Deploy dev
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# Deploy prod
terraform init -reconfigure -backend-config=backends/prod.backend.hcl
terraform plan -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

## Outputs

| Output | Purpose |
|---|---|
| `resource_group_name` | Reference for dependent resources |
| `vnet_id` / `vnet_name` | VNET identification for peering or linking |
| `subnet_ids` | Map of subnet names to IDs for VM/service placement |
| `vm_private_ip` | Internal connectivity |
| `vm_public_ip` | SSH access (dev only, null in prod) |
| `key_vault_name` / `key_vault_uri` | Secret management integration |
