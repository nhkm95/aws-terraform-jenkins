locals {
  base_name = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  vpc_name = "${local.base_name}-vpc"

  public_subnets_with_names = {
    for k, subnet in var.public_subnets :
    k => merge(
      subnet,
      { name_tag = "${local.base_name}-${k}" }
    )
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr      = var.vpc_cidr
  vpc_name      = local.vpc_name
  public_subnets = local.public_subnets_with_names
  tags          = local.common_tags
}

module "security_groups" {
  source = "../../modules/security_group"

  for_each = var.security_groups

  name        = "${local.base_name}-${each.key}"
  description = each.value.description
  vpc_id      = module.vpc.vpc_id
  ingress     = each.value.ingress_rules
  egress      = each.value.egress_rules
  tags        = local.common_tags
}

module "jenkins_ec2" {
  source = "../../modules/jenkins_ec2"

  for_each = { for k, v in var.ec2_instances : k => v if k == "jenkins" }

  name                 = "${local.base_name}-${each.key}"
  subnet_id            = module.vpc.public_subnet_ids[each.value.subnet_key]
  sg_ids               = [for sg_name in each.value.sg_names : module.security_groups[sg_name].security_group_id]
  ami                  = var.jenkins_ami
  instance_type        = each.value.instance_type
  key_name             = each.value.key_pair_name
  root_volume_gb       = each.value.root_volume_gb
  associate_public_ip  = true
  user_data            = try(file("${path.module}/${each.value.user_data_file}"), null)
  tags                 = local.common_tags
}

# module "windows_server" {
#   source = "../../modules/ec2"

#   for_each = { for k, v in var.ec2_instances : k => v if k == "tooling" }

#   name                 = "${local.base_name}-${each.key}"
#   ami                  = var.windows_ami
#   instance_type        = each.value.instance_type
#   subnet_id            = module.vpc.public_subnet_ids[each.value.subnet_key]
#   sg_ids               = [for sg_name in each.value.sg_names : module.security_groups[sg_name].security_group_id]
#   key_name             = each.value.key_pair_name
#   root_volume_gb       = each.value.root_volume_gb
#   associate_public_ip  = true
#   get_password_data    = true
#   tags                 = local.common_tags
# }