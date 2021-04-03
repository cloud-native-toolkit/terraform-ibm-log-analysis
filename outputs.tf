output "id" {
  value       = data.ibm_resource_instance.logdna_instance.id
  description = "The id of the provisioned LogDNA instance."
}

output "guid" {
  value       = data.ibm_resource_instance.logdna_instance.guid
  description = "The guid of the provisioned LogDNA instance."
}

output "name" {
  value       = local.name
  depends_on  = [ibm_resource_instance.logdna_instance]
  description = "The name of the provisioned LogDNA instance."
}

output "key_name" {
  value       = local.key_name
  depends_on  = [ibm_resource_key.logdna_instance_key]
  description = "The name of the key provisioned for the LogDNA instance."
}
