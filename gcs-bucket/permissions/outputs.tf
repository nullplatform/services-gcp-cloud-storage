output "granted_to" {
  value = sort(values(local.principals))
}

output "role" {
  value = local.roles[var.access_level]
}

output "path_prefix" {
  value = var.path_prefix
}
