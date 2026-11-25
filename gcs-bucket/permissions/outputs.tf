output "granted_to" {
  value = sort(values(local.principals))
}

output "role" {
  value = local.roles[var.access_level]
}
