variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "state_key" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  description = "Logical public subnets; keyed by short name. Name tag is derived from project+env+key."
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
  }))
}

variable "security_groups" {
  description = "Multiple SG definitions keyed by SG name."
  type = map(object({
    description   = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
}

variable "ec2_instances" {
  description = "Multiple EC2 instances keyed by instance name."
  type = map(object({
    subnet_key     = string          # which public_subnets key to attach to
    sg_names       = list(string)    # list of SG names (keys in security_groups)
    instance_type  = string
    key_pair_name  = string
    root_volume_gb = number
    user_data_file = optional(string)          # file in this module dir
  }))
}

variable "jenkins_ami" {
  type = string
}

variable "windows_ami" {
  type = string
}