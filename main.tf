provider "ibm" {
  version = ">= 1.2.1"
  region  = var.resource_location
}

provider "helm" {
  version = ">= 1.1.1"
  kubernetes {
    config_path = var.cluster_config_file_path
  }
}

provider "null" {
}

data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  name_prefix       = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name              = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-logdna"
  role              = "Manager"
  provision         = var.provision
  bind              = (var.provision || (!var.provision && var.name != "")) && var.cluster_config_file_path != "" && var.cluster_type != ""
  image_url         = var.base_icon_url != "" ? "${var.base_icon_url}/logdna" : ""
}

resource "null_resource" "logging" {
  provisioner "local-exec" {
    command = "echo 'provision: ${local.provision}, bind: ${local.bind}'"
  }
}

// LogDNA - Logging
resource "ibm_resource_instance" "logdna_instance" {
  depends_on = [null_resource.logging]
  count             = local.provision ? 1 : 0

  name              = local.name
  service           = "logdna"
  plan              = var.plan
  location          = var.resource_location
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  tags              = var.tags

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

data "ibm_resource_instance" "logdna_instance" {
  count             = local.bind ? 1 : 0
  depends_on        = [ibm_resource_instance.logdna_instance]

  name              = local.name
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  location          = var.resource_location
  service           = "logdna"
}

resource "ibm_resource_key" "logdna_instance_key" {
  count = local.bind ? 1 : 0

  name                 = "${local.name}-key"
  resource_instance_id = data.ibm_resource_instance.logdna_instance[0].id
  role                 = local.role

  //User can increase timeouts 
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "null_resource" "scc-cleanup" {
  count = local.bind ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete scc -l app.kubernetes.io/name=${var.service_account_name} --wait 1> /dev/null 2> /dev/null || true"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "helm_release" "service-account" {
  count = local.bind ? 1 : 0
  depends_on = [null_resource.scc-cleanup]

  name              = var.service_account_name
  chart             = "service-account"
  namespace         = var.namespace
  repository        = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  timeout           = 1200
  force_update      = true
  replace           = true

  disable_openapi_validation = true

  set {
    name  = "global.clusterType"
    value = var.cluster_type
  }

  set {
    name  = "name"
    value = var.service_account_name
  }

  set {
    name  = "create"
    value = true
  }

  set {
    name  = "sccs"
    value = "{anyuid, privileged}"
  }
}

resource "null_resource" "logdna_bind" {
  count = local.bind ? 1 : 0
  depends_on = [helm_release.service-account]

  triggers = {
    namespace  = var.namespace
    KUBECONFIG = var.cluster_config_file_path
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/bind-logdna.sh ${var.cluster_type} ${ibm_resource_key.logdna_instance_key[0].credentials.ingestion_key} ${var.resource_location} ${var.namespace} ${var.service_account_name}"

    environment = {
      KUBECONFIG = self.triggers.KUBECONFIG
      TMP_DIR    = "${path.cwd}/.tmp"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unbind-logdna.sh ${self.triggers.namespace}"

    environment = {
      KUBECONFIG = self.triggers.KUBECONFIG
    }
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type == "ocp4" && local.bind ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=logdna || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "helm_release" "logdna" {
  count = local.bind ? 1 : 0
  depends_on = [null_resource.logdna_bind]

  name              = "logdna"
  chart             = "tool-config"
  namespace         = var.namespace
  repository        = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  timeout           = 1200
  force_update      = true
  replace           = true

  disable_openapi_validation = true

  set {
    name  = "displayName"
    value = "LogDNA"
  }

  set {
    name  = "url"
    value = "https://cloud.ibm.com/observe/logging"
  }

  set {
    name  = "imageUrl"
    value = local.image_url
  }

  set {
    name  = "applicationMenu"
    value = true
  }

  set {
    name  = "global.clusterType"
    value = var.cluster_type
  }
}
