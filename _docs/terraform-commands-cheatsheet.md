# Terraform Commands Cheat Sheet

Reference for common Terraform CLI commands. Replace `<path>`, `<name>`, `<address>` with your values. Run from the directory that contains your `.tf` files (or use `-chdir=<path>`).

---

## 1. Core workflow

| Goal | Command |
|------|---------|
| Initialize (download providers, init backend) | `terraform init` |
| Format .tf files | `terraform fmt` (current dir) or `terraform fmt -recursive` |
| Validate configuration | `terraform validate` |
| Plan (preview changes) | `terraform plan` |
| Apply (create/update infrastructure) | `terraform apply` |
| Apply with auto-approve (CI/scripts) | `terraform apply -auto-approve` |
| Destroy resources | `terraform destroy` |
| Destroy with auto-approve | `terraform destroy -auto-approve` |

**Suggested order:** `init` → `fmt` → `validate` → `plan` → `apply`.

---

## 2. Plan and apply options

```bash
# Save plan to a file (for review or apply later)
terraform plan -out=tfplan
terraform apply tfplan

# Target specific resource(s) only
terraform plan -target=aws_instance.my_instance
terraform apply -target=aws_instance.my_instance

# Refresh state before plan (default: yes)
terraform plan -refresh=true
terraform plan -refresh=false

# Specify var file or vars
terraform plan -var-file=production.tfvars
terraform plan -var="instance_type=t3.medium"
terraform apply -var-file=production.tfvars
```

---

## 3. State (where Terraform stores what exists)

**List resources in state:**

```bash
terraform state list
```

**Show a resource (attributes):**

```bash
terraform state show <address>
# e.g. terraform state show aws_instance.web
```

**Pull state (download to file):**

```bash
terraform state pull > state.json
```

**Remove resource from state (don’t destroy in AWS):**

```bash
terraform state rm <address>
```

**Move resource (rename in state):**

```bash
terraform state mv <from_address> <to_address>
```

**Import existing resource into state:**

```bash
terraform import <address> <id>
# e.g. terraform import aws_instance.web i-0123456789abcdef0
```

---

## 4. Workspaces (multiple environments in one config)

```bash
# List workspaces (default is "default")
terraform workspace list

# Create and switch to a workspace
terraform workspace new <name>
terraform workspace select <name>

# Delete workspace (must not be current, state must be empty)
terraform workspace delete <name>
```

Use `terraform.workspace` in config to branch (e.g. different instance types per env).

---

## 5. Variables and output

**Set variable via env (TF_VAR_<name>):**

```bash
export TF_VAR_region=us-east-1
export TF_VAR_environment=dev
terraform plan
```

**Output values (after apply):**

```bash
terraform output
terraform output -json
terraform output <output_name>
```

---

## 6. Run from another directory

```bash
terraform -chdir=path/to/module init
terraform -chdir=path/to/module plan
terraform -chdir=path/to/module apply
```

---

## 7. AWS provider (EKS / general)

**Typical provider block (in `.tf`):**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "my-tf-state-bucket"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}
```

**Use a profile or assume role:**

```hcl
provider "aws" {
  region  = var.region
  profile = var.aws_profile
  # Or: assume_role { role_arn = "..." }
}
```

**Then:**

```bash
export AWS_PROFILE=myprofile
terraform init
terraform plan
```

---

## 8. Useful flags

| Flag | Use |
|------|-----|
| `-input=true/false` | Prompt for unset variables. |
| `-lock=true/false` | State locking (e.g. S3 + DynamoDB). |
| `-lock-timeout=<duration>` | How long to wait for lock. |
| `-parallelism=N` | Limit concurrent operations (default 10). |
| `-refresh-only` | Update state from real resources, no plan changes. |
| `-replace=<address>` | Force replace of one resource. |
| `-no-color` | Disable color (for logs/CI). |

**Examples:**

```bash
terraform apply -refresh-only
terraform apply -replace=aws_instance.web
terraform plan -no-color
```

---

## 9. Debugging and logging

```bash
# More logs (TRACE for everything)
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform plan

# Unset when done
unset TF_LOG TF_LOG_PATH
```

---

## 10. Quick reference

| Task | Command |
|------|---------|
| First time / after adding provider or backend | `terraform init` |
| See what would change | `terraform plan` |
| Apply changes | `terraform apply` |
| Destroy all | `terraform destroy` |
| List state | `terraform state list` |
| Show one resource | `terraform state show <address>` |
| Import existing resource | `terraform import <address> <id>` |
| Switch env | `terraform workspace select <name>` |
| Use another folder | `terraform -chdir=<path> plan` |

---

## 11. Files you’ll see

| File / dir | Purpose |
|------------|---------|
| `*.tf` | Configuration (resources, variables, outputs). |
| `*.tfvars` | Variable values (e.g. `production.tfvars`). |
| `.terraform/` | Providers and modules (after `init`). |
| `.terraform.lock.hcl` | Locked provider versions. |
| `terraform.tfstate` | State (if local; often use S3 backend). |
| `terraform.tfstate.backup` | Backup of previous state. |

For more on EKS with Terraform, see the [AWS EKS Terraform provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) and [EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).

---

## 12. Download / install Terraform

**Option A — Latest (Linux/macOS, Bash):**

```bash
# Set TF_VER to desired version (see https://releases.hashicorp.com/terraform/)
TF_VER="1.6.0"
TF_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
TF_ARCH=amd64
[ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] && TF_ARCH=arm64
curl -sL "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_${TF_OS}_${TF_ARCH}.zip" -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /tmp
sudo mv /tmp/terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
terraform version
```

**Option B — Specific version (Linux/macOS, no jq):**

```bash
TF_VER="1.6.0"   # set desired version
TF_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
TF_ARCH=amd64
[ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] && TF_ARCH=arm64
curl -sL "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_${TF_OS}_${TF_ARCH}.zip" -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /tmp
sudo mv /tmp/terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
terraform version
```

**Option C — User directory (no sudo, e.g. CloudShell):**

```bash
BIN_DIR="${BIN_DIR:-$HOME/bin}"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

TF_VER="1.6.0"
TF_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
TF_ARCH=amd64
[ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] && TF_ARCH=arm64
curl -sL "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_${TF_OS}_${TF_ARCH}.zip" -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /tmp
mv /tmp/terraform "$BIN_DIR/"
chmod +x "$BIN_DIR/terraform"
terraform version
echo "Add to PATH: export PATH=\"$BIN_DIR:\$PATH\""
```

**Option D — Windows (PowerShell, Chocolatey or manual):**

```powershell
# Chocolatey
choco install terraform -y

# Or winget
winget install Hashicorp.Terraform

# Or manual: download zip from https://www.terraform.io/downloads
# Extract terraform.exe and add folder to PATH
```

**Verify:**

```bash
command -v terraform && terraform version
```

**Releases:** [releases.hashicorp.com/terraform](https://releases.hashicorp.com/terraform). Docs: [terraform.io/docs](https://www.terraform.io/docs).
