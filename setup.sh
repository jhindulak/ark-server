#!/bin/sh

echo 'Generating ssh key for Terraform...'
ssh-keygen -f id_rsa -t rsa -N ''
TF_VAR_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)

# Terraform apply
echo "The following items are required: "
read -p "Azure subscription ID: " -r TF_VAR_azure_subscription_id
read -p "Azure client ID: " -r TF_VAR_azure_client_id
read -p "Azure client secret: " -r TF_VAR_azure_client_secret
read -p "Tenant ID: " -r TF_VAR_tenant_id
read -p "Domain name label: " -r TF_VAR_domain_name_label

# Do validation on these, if not empty/null save as TF_ENV
echo "The following items are optional. Hit the enter key without entry to accept the default for an item."
read -p "Resource location (default: eastus): " -r resource_location
if [ -n "$resource_location"];
    TF_VAR_resource_location = resource_location
fi
read -p "VM size (default: Standard_DS1_v2): " -r vm_size
if [ -n "$vm_size"];
    TF_VAR_vm_size = vm_size
fi

echo "Starting to terraform..."
cd terraform
terraform init

echo "Applying terraform..."
terraform apply -auto-approve

ark_public_ip=$(terraform output ark_public_ip)
echo "ark_server ${terraform output ark_public_ip}" >> ../ansible/inventory

# Ansible
echo "Enter your server information..."
read -p "Ark session name: " -r ark_session_name
read -p "Ark server password (Hit enter for no password): " -r ark_server_password
read -p "Ark admin password: " -r ark_admin_password
read -p "Ark server map: " -r ark_server_map

cd ../ansible
ansible-playbook ./playbook.yml

# Give user the ssh keys to keep for future use
echo "Printing SSH keys to screen for safe keeping..."
echo "Here is your SSH private key - KEEP THIS SAFE:"
cat ~/.ssh/id_rsa
echo "Here is your SSH public key:"
cat ~/.ssh/id_rsa.pub