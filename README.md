## Azure + AAP Project for HCP Terraform / Terraform Cloud

This project provisions an Azure demo environment and then optionally triggers an Ansible Automation Platform (AAP) Job Template.

The Terraform workflow:

* Creates an Azure Resource Group
* Creates networking components (VNet, Subnet, NSG, Public IP, NIC)
* Creates an Ubuntu 22.04 Linux VM
* Waits for SSH connectivity
* Registers the host in AAP inventory
* Launches an AAP Job Template

## Target architecture

```text
Git Repository
  ↓
HCP Terraform Workspace (VCS-driven)
  ↓
Azure Provider provisions infrastructure
  ↓
AAP API registers host and launches job
  ↓
Ansible Automation Platform configures the VM
```

## What changed for HCP Terraform support

This project is designed for remote execution using Terraform Cloud / Terraform Enterprise.

Key characteristics:

* No local `az login` required
* No local `terraform.tfstate` required
* Azure authentication provided through workspace environment variables
* Terraform variables managed through workspace variables
* VCS-driven workflow supported
* Infrastructure automatically created and destroyed from Terraform Cloud

## Infrastructure created

Terraform creates the following Azure resources:

```text
Azure Subscription
└── Resource Group
    ├── Virtual Network
    ├── Subnet
    ├── Network Security Group
    ├── Public IP
    ├── Network Interface
    └── Ubuntu 22.04 Linux VM
```

All resources are managed by Terraform and can be removed using:

```bash
terraform destroy
```

## Project structure

```text
.
├── ansible/
│   └── install_nginx.yml
├── docs/
│   └── cloud_block.example.tf
├── tests/
│   └── aap_connect.sh
├── main.tf
├── outputs.tf
├── variables.tf
└── versions.tf
```

## HCP Terraform Setup

### 1. Push project to Git

Store the repository in:

* GitHub
* GitLab
* Bitbucket
* Azure DevOps

### 2. Create HCP Terraform Workspace

Create a new workspace:

```text
Create New Workspace
  → Version Control Workflow
  → Select Repository
```

For Terraform Enterprise installations, configure GitHub OAuth access if required.

Workspace settings:

```text
Working Directory:
(blank if Terraform files are at repository root)
```

### 3. Configure workspace variables

Configure the workspace using the two variable categories below.

#### Environment Variables

Set these as **Environment Variables** in the HCP Terraform workspace.

| Variable | Sensitive | Example |
| --- | ---: | --- |
| `ARM_CLIENT_ID` | No | `13b1c257-c5e9-4f9b-acc1-288db157b69c` |
| `ARM_CLIENT_SECRET` | Yes | app registration client secret |
| `ARM_SUBSCRIPTION_ID` | No | `196fbf40-3a13-4c14-8c46-96188cdc0ada` |
| `ARM_TENANT_ID` | No | `374d40ba-539d-4650-a7f2-fc7858617efe` |
| `TF_VAR_aap_host` | No | `https://aap26.nurul-islam.my.id` |
| `TF_VAR_aap_username` | No | `admin` |
| `TF_VAR_aap_password` | Yes | AAP bearer token or password |
| `TF_VAR_aap_job_template_id` | No | `20` |
| `TF_VAR_cf_access_client_id` | No | Cloudflare Access service token Client ID |
| `TF_VAR_cf_access_client_secret` | Yes | Cloudflare Access service token Client Secret |

Azure authentication values come from an Azure App Registration:

```text
Azure Portal
  → Microsoft Entra ID
  → App registrations
  → Create app registration
  → Copy Tenant ID, Subscription ID, Client ID, and Client Secret
```

The `TF_VAR_*` environment variables are automatically mapped to Terraform input variables with the same name without the `TF_VAR_` prefix.

If AAP is protected by Cloudflare Access, create a **Service Auth** token in Cloudflare Zero Trust and set `TF_VAR_cf_access_client_id` and `TF_VAR_cf_access_client_secret`. Terraform sends these values on every AAP API request as:

```text
CF-Access-Client-Id: <client-id>
CF-Access-Client-Secret: <client-secret>
```

#### Terraform Variables

Set these as **Terraform Variables** in the HCP Terraform workspace.

| Variable | Sensitive | Example |
| --- | ---: | --- |
| `prefix` | No | `demo` |
| `location` | No | `indonesiacentral` |
| `vm_admin_username` | No | `azureuser` |
| `vm_size` | No | `Standard_D2s_v3` |
| `ssh_public_key` | No | `ssh-ed25519 AAAA... user@example.com` |
| `enable_aap` | No | `true` |
| `aap_inventory_id` | No | `7` |
| `ssh_port` | No | `2200` |

Notes:

* `enable_aap = true` enables host registration and AAP job launch after the VM is reachable over SSH.
* `ssh_port` is optional and defaults to `2200`.
* `ssh_public_key` must be the full public key text.
* The SSH private key should remain stored in AAP credentials, not in HCP Terraform.

Example workspace configuration:

```text
prefix = demo
location = indonesiacentral
vm_admin_username = azureuser
vm_size = Standard_D2s_v3
ssh_public_key = ssh-ed25519 AAAA...
enable_aap = true
aap_inventory_id = 7
```

### 4. Queue Plan / Apply

After variables are configured:

```text
Queue Run
```

Terraform Cloud will:

```text
Create Resource Group
Create Networking
Create Security Group
Create Linux VM
Wait for SSH
Register Host in AAP
Launch Job Template
```

## Optional: CLI-driven remote runs

If desired, Terraform can still be executed locally while using Terraform Cloud for:

* State management
* Remote execution
* Variable storage

Use the example in `docs/cloud_block.example.tf` for CLI-driven remote runs.

For most enterprise deployments, VCS-driven workspaces are recommended.

## AAP Requirements

This project assumes:

* Ansible Automation Platform is already installed
* Inventory exists in AAP
* Job Template exists in AAP
* SSH credentials are configured inside AAP
* Job Template is launchable via API
* If AAP is behind Cloudflare Access, a service token is configured and allowed for the AAP application

Terraform only registers the host and launches the job.

The SSH private key should remain stored inside AAP credentials.

## Outputs

After successful apply Terraform returns:

```text
resource_group_name
vm_name
public_ip
ssh_port
```

Example:

```text
resource_group_name = demo-abcd-rg
vm_name             = demo-abcd-vm
public_ip           = 20.x.x.x
ssh_port            = 2200
```

SSH example:

```text
ssh -p 2200 azureuser@20.x.x.x
```

## Destroying the Environment

To remove all Azure resources:

```bash
terraform destroy
```

Terraform removes:

```text
Linux VM
Network Interface
Public IP
Network Security Group
Subnet
Virtual Network
Resource Group
```

This provides a clean demo environment similar to deleting an Azure Resource Group.
