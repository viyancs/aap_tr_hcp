# AWS + AAP Project for HCP Terraform / Terraform Cloud

This project provisions a complete AWS demo environment and then optionally triggers an Ansible Automation Platform (AAP) Job Template.

The Terraform workflow:

* Creates a dedicated AWS VPC
* Creates networking components (Subnet, Route Table, Internet Gateway, Security Group)
* Creates an EC2 instance running Ubuntu 22.04
* Waits for SSH connectivity
* Registers the host in AAP inventory
* Launches an AAP Job Template

## Target architecture

```text
Git Repository
  ↓
HCP Terraform Workspace (VCS-driven)
  ↓
AWS Provider provisions infrastructure
  ↓
AAP API registers host and launches job
  ↓
Ansible Automation Platform configures the EC2 instance
```

## What changed for HCP Terraform support

This project is designed for remote execution using Terraform Cloud / Terraform Enterprise.

Key characteristics:

* No local AWS CLI credentials required
* No local terraform.tfstate required
* AWS authentication provided through workspace environment variables
* Terraform variables managed through workspace variables
* VCS-driven workflow supported
* Infrastructure automatically created and destroyed from Terraform Cloud

## Infrastructure created

Terraform creates the following AWS resources:

```text
AWS Account
└── VPC
    ├── Internet Gateway
    ├── Route Table
    ├── Public Subnet
    ├── Security Group
    ├── EC2 Key Pair
    └── Ubuntu 22.04 EC2 Instance
```

All resources are managed by Terraform and can be removed using:

```bash
terraform destroy
```

## Project structure

```text
.
├── main.tf
├── outputs.tf
├── variables.tf
└── version.tf
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

### 3. Configure AWS Authentication

Create an IAM User in AWS with permissions to manage:

* EC2
* VPC
* Subnets
* Route Tables
* Internet Gateways
* Security Groups
* Key Pairs

Generate:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Add the following as Workspace Environment Variables:

| Variable              | Sensitive |
| --------------------- | --------- |
| AWS_ACCESS_KEY_ID     | No        |
| AWS_SECRET_ACCESS_KEY | Yes       |

Terraform automatically uses these credentials.

### 4. Configure AAP Environment Variables

Add the following Environment Variables:

| Variable                   | Sensitive |
| -------------------------- | --------- |
| TF_VAR_aap_host            | No        |
| TF_VAR_aap_username        | No        |
| TF_VAR_aap_password        | Yes       |
| TF_VAR_aap_job_template_id | No        |

Example:

```text
TF_VAR_aap_host=https://aap.example.com
TF_VAR_aap_username=admin
TF_VAR_aap_password=********
TF_VAR_aap_job_template_id=38
```

### 5. Configure Terraform Variables

Add the following Terraform Variables:

| Variable         | Sensitive | Example             |
| ---------------- | --------- | ------------------- |
| aws_account_id   | No        | 212385701071        |
| prefix           | No        | demo                |
| instance_type    | No        | t3.micro            |
| ssh_port         | No        | 2222                |
| ssh_public_key   | No        | ssh-ed25519 AAAA... |
| enable_aap       | No        | true                |
| aap_inventory_id | No        | 11                  |

Example workspace configuration:

```text
aws_account_id = 212385701071
enable_aap = true
aap_inventory_id = 11
ssh_public_key = ssh-ed25519 AAAA...
```

### 6. Queue Plan / Apply

After variables are configured:

```text
Queue Run
```

Terraform Cloud will:

```text
Create VPC
Create Networking
Create Security Group
Create Key Pair
Create EC2 Instance
Wait for SSH
Register Host in AAP
Launch Job Template
```

## AWS Account Safety Validation

This project supports validation of the AWS Account ID to help prevent accidental deployment into the wrong AWS account.

Terraform compares:

```text
Current AWS Account
```

against:

```text
aws_account_id
```

configured in the workspace.

If they do not match, Terraform fails before creating resources.

Example:

```text
Expected Account: 212385701071
Actual Account:   999999999999

Result:
Terraform Run Failed
```

## Optional CLI-driven Remote Runs

If desired, Terraform can still be executed locally while using Terraform Cloud for:

* State management
* Remote execution
* Variable storage

For most enterprise deployments, VCS-driven workspaces are recommended.

## AAP Requirements

This project assumes:

* Ansible Automation Platform is already installed
* Inventory exists in AAP
* Job Template exists in AAP
* SSH credentials are configured inside AAP
* Job Template is launchable via API

Terraform only registers the host and launches the job.

The SSH private key should remain stored inside AAP credentials.

## Outputs

After successful apply Terraform returns:

```text
instance_id
public_ip
ssh_command
```

Example:

```text
instance_id = i-0123456789abcdef
public_ip   = 54.x.x.x

ssh_command = ssh -p 2222 ubuntu@54.x.x.x
```

## Destroying the Environment

To remove all AWS resources:

```bash
terraform destroy
```

Terraform removes:

```text
EC2 Instance
Security Group
Route Table
Subnet
Internet Gateway
VPC
Key Pair
```

This provides a clean demo environment similar to deleting an Azure Resource Group.
