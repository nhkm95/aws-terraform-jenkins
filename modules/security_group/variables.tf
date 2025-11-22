variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ingress" {
  type = list(object({
    from_port   = optional(number)
    to_port     = optional(number)
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "egress" {
  type = list(object({
    from_port   = optional(number)
    to_port     = optional(number)
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "tags" {
  type = map(string)
}
