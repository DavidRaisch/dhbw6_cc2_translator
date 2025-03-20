# DHBW6 CC2 Translator

## Overview

**DHBW6 CC2 Translator** is a Python-based translation service that leverages modern cloud infrastructure and automated configuration management. The application is containerized using Docker, ensuring consistent builds and deployments. Infrastructure is provisioned via Terraform to deploy necessary resources on Microsoft Azure and MongoDB Atlas, while an Ansible-driven deployment—executed by a dedicated Bash script—completes the configuration process.

## Project Structure

```plaintext
DHBW6_CC2_TRANSLATOR/
├── ansible/                         # Ansible playbooks and configurations
│   ├── deploy_app.yml               # Deployment playbook for the application
│   ├── inventory.ini                # Inventory file for target hosts
│   ├── inventory.tpl                # Inventory template (optional)
│   └── run_deployment.sh            # Script to trigger Ansible deployment
├── templates/                       # Template files (e.g., HTML, configs)
│   └── index.html                   # Frontend HTML template
├── terraform/                       # Terraform infrastructure configurations
│   ├── azure_infrastructure/        # Azure-specific resources
│   │   ├── main.tf                  # Azure resource definitions
│   │   ├── outputs.tf               # Output variables for Azure
│   │   ├── variables.tf             # Input variables for Azure
│   │   └── versions.tf              # Azure provider versions
│   ├── mongodb_atlas/               # MongoDB Atlas configurations
│   │   ├── main.tf                  # MongoDB cluster definitions
│   │   ├── outputs.tf               # Output variables for MongoDB
│   │   ├── variables.tf             # Input variables for MongoDB
│   │   └── versions.tf              # MongoDB Atlas provider versions
│   ├── .terraform.lock.hcl          # Terraform dependency lock file
│   ├── main.tf                      # Root Terraform configuration
│   ├── outputs.tf                   # Global outputs
│   ├── providers.tf                 # Terraform provider declarations
│   ├── terraform.tfstate            # Terraform state file (auto-generated)
│   ├── terraform.tfstate.backup     # Backup of state file
│   ├── terraform.tfvars             # Variable definitions (e.g., secrets)
│   └── variables.tf                 # Global input variables
├── .gitignore                       # Specifies files to ignore in Git
├── app.py                           # Main application code (Python)
├── Dockerfile                       # Docker image configuration
├── requirements.txt                 # Python dependencies
└── wsgi.py                          # WSGI entry point for deployment (e.g., Flask)
```

## Getting Started
### Prerequisites
   - Git
   - Docker
   - Terraform
   - Ansible
   - Command Line

### Installation
1. Clone the Repository
   ```bash
   git clone git@github.com:DavidRaisch/dhbw6_cc2_translator.git
   cd dhbw6_cc2_translator
2. Set Up Enviroment Variables
   The project requires several environment variables for proper operation. Configure these in your environment or via a .tfvars (.env) file if your workflow supports it.
   ```Plaintext
   azure_subscription_id: Your Azure subscription ID.
   azure_client_id: Azure service principal client ID.
   azure_client_secret: Azure service principal secret.
   azure_tenant_id: Azure tenant ID.
   mongodb_atlas_public_key: MongoDB Atlas API public key.
   mongodb_atlas_private_key: MongoDB Atlas API private key.
   deepL_auth_key: API Key for Translator
   mongodb_db_password: Set Password for MongoDB Database User
   ```
4. Docker Build
    Build and Push a Docker Image for Linux VM to the Docker Hub (only necessary if change in App.py or index.html were made)
     ```bash
     docker buildx build --platform linux/amd64 -t davidraisch/translator-app:latest --push .
     ```
4. Terraform Deployment
     ```Bash
     cd terraform
     terraform init
     terraform plan
     terraform apply
     ```
5. Ansible Deployment
     ```Bash
     cd ..
     cd ansible
     chmod +x run_deployment.sh
     ./run_deployment.sh
     ```
  The bash script extracts the necessary variables from the terraform output and use it to deploy the App environment.
  The Output of the ansible script is the ip address on which the app is running

## Testing
To test the Translator App, you need to perform the following steps:
1. Create a file "testenv" with the "MONGODB_CONNECTION_STRING" and the "DEEPL_AUTH_KEY" in the dhbw6_cc2_translator directory
2. Create a virtual Enviroment venv
   ```Bash
      python3 -m venv venv
      source venv/bin/activate  # On Linux/MacOS
      pip3 install pytest
   ````
3. Install all requieremnts in this virtual enviroment
   ```Bash
      pip3 install -r requirements.txt
   ```
4. Run the test script "test_app.py"
   ```Bash
      pytest test/test_app.py
   ````
   Make sure you are in the dhbw6_cc2_translator directory

## Additional Notes
### Troubleshooting
  - Verify that all environment variables are correctly configured.
  - Ensure your credentials (for Azure and MongoDB Atlas) have the necessary permissions.
  - Check Docker logs, Terraform outputs, and Ansible playbook results for any errors.
### Documentation
Further documentation may be found within the source code comments and additional documentation files in the repository.
   
