output "id" {
  value       = data.ibm_resource_instance.instance.id
  description = "The id of the provisioned instance."
}

output "guid" {
  value       = data.ibm_resource_instance.instance.guid
  description = "The id of the provisioned instance."
}

output "name" {
  value       = local.name
  depends_on  = [ibm_resource_instance.logdna_instance]
  description = "The name of the provisioned instance."
}

output "crn" {
  description = "The id of the provisioned instance"
  value       = data.ibm_resource_instance.instance.id
}

output "location" {
  description = "The location of the provisioned instance"
  value       = var.region
  depends_on  = [data.ibm_resource_instance.instance]
}

output "service" {
  description = "The service name of the provisioned instance"
  value       = local.service
  depends_on = [data.ibm_resource_instance.instance]
}

output "label" {
  description = "The label for the instance"
  value       = var.label
  depends_on = [data.ibm_resource_instance.instance]
}

output "key_name" {
  value       = local.key_name
  depends_on  = [ibm_resource_key.logdna_instance_key]
  description = "The name of the key provisioned for the LogDNA instance."
}
