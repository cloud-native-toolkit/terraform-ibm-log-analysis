
locals {
  tmp_dir     = "${path.cwd}/.tmp"
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  key_name    = "${local.name}-key"
  role        = "Manager"
  provision   = var.provision
  service     = "logdna"
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "resource_group" {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

// LogDNA - Logging
resource "ibm_resource_instance" "logdna_instance" {
  count             = local.provision ? 1 : 0

  name              = local.name
  service           = local.service
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

data ibm_resource_instance instance {
  depends_on = [ibm_resource_instance.logdna_instance]

  name              = local.name
  resource_group_id = data.ibm_resource_group.resource_group.id
  location          = var.region
  service           = local.service
}

resource ibm_resource_key logdna_instance_key {

  name                 = local.key_name
  resource_instance_id = data.ibm_resource_instance.instance.id
  role                 = local.role

  timeouts {
    create = "15m"
    delete = "15m"
  }
}
