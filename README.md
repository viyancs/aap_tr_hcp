# Azure + AAP Provider Project for HCP Terraform / Terraform Cloud

It provisions an Azure VM and then uses the **official `ansible/aap` Terraform provider** to:
- look up an existing AAP / Automation Controller Job Template
- create an AAP inventory
- register the new VM as a host
- launch the AAP job

## Target architecture

```text
Git repo
  ↓
HCP Terraform workspace (VCS-driven)
  ↓
Azure provider provisions infrastructure
  ↓
AAP provider creates inventory + host + launches job
  ↓
Ansible Automation Platform configures the VM
```

## What changed for HCP Terraform support

This conversion removes local-only assumptions and is designed for **remote runs**:

- no required `az login` workflow
- no Terraform Cloud `cloud {}` block by default, because VCS-driven workspaces do not need it
- Azure authentication is expected from **workspace environment variables** or **dynamic credentials**
- application and AAP values are expected from **workspace Terraform variables**
- `terraform.tfvars.example` is kept only as a local reference

## Project structure

```text
.
├── ansible/
│   └── playbooks/
│       └── install_nginx.yml
├── docs/
│   └── cloud_block.example.tf
├── modules/
│   ├── compute/
│   └── network/
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
└── versions.tf
```

## HCP Terraform setup

### 1. Push this project to Git

Put the project in GitHub, GitLab, Bitbucket, or Azure DevOps.

### 2. Create an HCP Terraform workspace

Create a **VCS-backed workspace** and connect it to the repository. HCP Terraform supports VCS-backed workspaces and lets you choose the tracked branch and working directory in workspace settings. 

For this repository:
- **Working Directory**: leave blank if this project is at repo root
- if you place it under a subfolder such as `terraform/`, set that subfolder as the workspace working directory

Note: a new VCS workspace needs an initial manually queued run before later VCS webhook-triggered runs are accepted. 

### 3. Configure Azure authentication

Use one of these patterns:

#### Option A — Preferred: HCP Terraform dynamic credentials for Azure

HCP Terraform supports **dynamic credentials** for the Azure provider using OIDC. HashiCorp documents this as the recommended modern approach for remote runs. 

This avoids storing long-lived Azure client secrets in the workspace.

#### Option B — Static Azure environment variables

Set Azure credentials as **environment variables** in the workspace, for example:
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`

Variables and variable sets in HCP Terraform can be managed at the workspace or project level.

### 4. Configure Terraform variables in the workspace

Add these as **Terraform Variables** in HCP Terraform:

| Variable | Sensitive | Example |
|---|---:|---|
| `location` | No | `eastus` |
| `prefix` | No | `demo` |
| `vm_admin_username` | No | `azureuser` |
| `vm_size` | No | `Standard_B2s` |
| `ssh_public_key` | No | full public key text |
| `my_ip_cidr` | No | `203.0.113.10/32` |
| `aap_host` | No | `https://controller.example.com` |
| `aap_username` | No | `svc_terraform` |
| `aap_password` | Yes | AAP password |
| `aap_insecure_skip_verify` | No | `false` |
| `aap_organization_name` | No | `Default` |
| `aap_job_template_name` | No | `linux-install-nginx` |
| `aap_inventory_name` | No | optional |
| `aap_job_extra_vars` | No | map/object |

Mark secrets like `aap_password` as **sensitive**. HCP Terraform variables support sensitive values and reusable variable sets. 

### 5. Queue a plan/apply

Once the workspace variables are configured, queue a run. HCP Terraform performs remote operations in the context of a workspace, which provides configuration, state, and variables for the run. citeturn373202search13

## Example `aap_job_extra_vars`

Use HCL map syntax in a Terraform variable:

```hcl
{
  web_server = "nginx"
  app_env    = "dev"
}
```

If you enter it in the HCP Terraform UI, make sure the variable is stored as an HCL value, not a plain quoted string.

## Optional: CLI-driven remote runs

If you want to run from your workstation but keep execution/state in HCP Terraform, use the **CLI-driven remote workflow** and add the example shown in `docs/cloud_block.example.tf`. HCP Terraform supports UI/VCS-driven, API-driven, and CLI-driven remote run workflows. 

For most enterprise use cases, **VCS-driven** is the cleaner approach.

## Important AAP expectations

This project assumes the following already exist in AAP / Automation Controller:
- the organization named by `aap_organization_name`
- the job template named by `aap_job_template_name`
- credentials attached to that job template so it can SSH to the target VM
- the job template is configured to allow **inventory prompt on launch**

Because the Terraform provider launches the job, the SSH private key should live in **AAP credentials**, not in HCP Terraform.

## Outputs

After apply, Terraform returns:
- Azure resource group name
- VM name
- public IP
- private IP
- created AAP inventory ID/name
- AAP job launch resource ID

## Recommended enterprise model

For your environment, the clean split is:

- **HCP Terraform / Terraform Enterprise** = provisioning, state, policy, workspace variables
- **Ansible Automation Platform / Tower** = configuration management and operational workflows

That keeps Terraform as the orchestrator and AAP as the configuration engine.
