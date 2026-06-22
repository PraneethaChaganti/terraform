# Terraform
Terraform configurations for automated AWS infrastructure provisioning, featuring automated deployments via Jenkins multibranch pipelines.

# 1. Install TFlint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# 2. Install Checkov (via Python pip)
sudo apt-get update && sudo apt-get install -y python3-pip jq python3-venv
pip3 install checkov

# 3. Install Terragrunt
# Fetch the latest version, download the binary, and move to your PATH
TG_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name)
wget https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64
mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
chmod +x /usr/local/bin/terragrunt
