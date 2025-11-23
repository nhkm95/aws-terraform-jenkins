variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sg_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "root_volume_gb" {
  type = number
}

variable "iam_instance_profile" {
  type    = string
  default = null
}

variable "associate_public_ip" {
  type = bool
}

variable "user_data" {
  type    = string
  default = null
}

variable "tags" {
  type = map(string)
}

variable "ami" {
  type = string
}

# variable "ami_owner" {
#   type    = string
# #  default = "099720109477" # Canonical; override via tfvars if you want
# }

# variable "ami_name_filter" {
#   type    = string
# #  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
# }
variable "get_password_data" {
  type    = bool
  default = false
}

variable "monitoring" {
  type    = bool
  default = false
}