output "public_ips" {
  value = { for name, inst in module.jenkins_ec2 : name => inst.public_ip }
}

output "public_dns" {
  value = { for name, inst in module.jenkins_ec2 : name => inst.public_dns }
}