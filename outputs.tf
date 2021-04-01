output "id" {
  value       = data.ibm_resource_instance.logdna_instance.id
  description = "The id of the provisioned LogDNA instance."
}

output "name" {
  value       = local.name
  depends_on  = [ibm_resource_instance.logdna_instance]
  description = "The name of the provisioned LogDNA instance."
}
