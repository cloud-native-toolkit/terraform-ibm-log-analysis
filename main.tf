
locals {
  tmp_dir           = "${path.cwd}/.tmp"
  name_prefix       = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name              = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-logdna"
  role              = "Manager"
  provision         = var.provision
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group_name
}

// LogDNA - Logging
resource "ibm_resource_instance" "logdna_instance" {
  count             = local.provision ? 1 : 0

  name              = local.name
  service           = "logdna"
  plan              = var.plan
  location          = var.region
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = var.tags

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

data "ibm_resource_instance" "logdna_instance" {
  depends_on = [ibm_resource_instance.logdna_instance]

  name              = local.name
  resource_group_id = data.ibm_resource_group.resource_group.id
  location          = var.region
  service           = "logdna"
}
