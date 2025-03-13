// Create MongoDB Atlas Project
resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = var.org_id
}

// Create MongoDB Atlas Cluster (Free Tier, M0)
resource "mongodbatlas_cluster" "cluster" {
  project_id                  = mongodbatlas_project.project.id
  name                        = var.cluster_name
  provider_name               = "TENANT"
  backing_provider_name       = "AZURE"
  provider_region_name        = var.provider_region_name
  provider_instance_size_name = var.provider_instance_size_name
  cluster_type                = "REPLICASET"
  backup_enabled              = false
}

// Create MongoDB Database User
resource "mongodbatlas_database_user" "translator_user" {
  username           = var.db_username
  password           = var.db_password
  project_id         = mongodbatlas_project.project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}

// Local value to adjust the connection string
locals {
  mongodb_server_without_uri = replace(mongodbatlas_cluster.cluster.connection_strings[0].standard_srv, "mongodb+srv://", "")
}

// Create Atlas IP Access List entry using the VM's public IP
resource "mongodbatlas_project_ip_access_list" "access" {
  project_id = mongodbatlas_project.project.id
  ip_address = var.vm_public_ip
  comment    = "Allow access from translator VM"
}
