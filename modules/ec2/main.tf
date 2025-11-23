resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data
  get_password_data           = var.get_password_data
  monitoring                  = var.monitoring

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }
  
  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}