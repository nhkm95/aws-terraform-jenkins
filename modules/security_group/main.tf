resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each          = { for idx, rule in var.ingress : idx => rule }

  security_group_id = aws_security_group.this.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each          = { for idx, rule in var.egress : idx => rule }

  security_group_id = aws_security_group.this.id
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
}
