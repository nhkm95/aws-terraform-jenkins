# output "windows_password" {
#   value     = { for k, v in module.windows_server : k => v.password_data }
#   sensitive = true
# }