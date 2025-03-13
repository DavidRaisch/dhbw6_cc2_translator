#!/bin/bash

# Ensure the sensitive variables are passed from Terraform outputs:
export DEEPL_AUTH_KEY=$(terraform -chdir=../terraform output -raw deepl_auth_key)
export MONGODB_CONNECTION_STRING=$(terraform -chdir=../terraform output -raw mongodb_connection_string)

echo "DeepL Auth Key: $DEEPL_AUTH_KEY"
echo "MongoDB Connection String: $MONGODB_CONNECTION_STRING"

# Run the playbook using the dynamically generated inventory file.
ansible-playbook -i inventory.ini deploy_app.yml --private-key ~/.ssh/Azure_deploy_key 
