variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "public_subnets" {
  description = "Map of public subnets keyed by short name"
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    name_tag                = string
  }))
}

variable "tags" {
  type = map(string)
}