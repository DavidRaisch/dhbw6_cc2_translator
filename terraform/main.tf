// Call the Azure Infrastructure module
module "azure_infrastructure" {
  source                = "./modules/azure_infrastructure"
  location              = var.location
  resource_group_name   = var.resource_group_name
  virtual_network_name  = var.virtual_network_name
  subnet_name           = var.subnet_name
  nsg_name              = var.nsg_name
  public_ip_name        = var.public_ip_name
  nic_name              = var.nic_name
  vm_name               = var.vm_name
  vm_size               = var.vm_size
  vm_admin_username     = var.vm_admin_username
  ssh_public_key_path   = var.ssh_public_key_path
  vm_image_sku          = var.vm_image_sku
}

// Call the MongoDB Atlas module
module "mongodb_atlas" {
  source                         = "./modules/mongodb_atlas"
  org_id                         = var.mongodb_atlas_org_id
  project_name                   = var.mongodb_project_name
  cluster_name                   = var.mongodb_cluster_name
  provider_region_name           = var.mongodb_provider_region_name
  provider_instance_size_name    = var.mongodb_provider_instance_size_name
  db_username                    = var.mongodb_db_username
  db_password                    = var.mongodb_db_password
  // Pass the public IP from the Azure module to set the IP access list
  vm_public_ip                   = module.azure_infrastructure.public_ip
}

// Null resource to output terraform outputs to a JSON file (optional)
resource "null_resource" "write_tf_output" {
  triggers = {
    always = timestamp()
  }
  provisioner "local-exec" {
    command = "terraform output -json > terraform_output.json"
  }
}

# Create dynamic inventory file in the ansible folder from a template
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini" 
  content  = templatefile("${path.module}/../ansible/inventory.tpl", {
    public_ip = module.azure_infrastructure.public_ip
  })
}

