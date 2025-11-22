# data "aws_ami" "this" {
#   most_recent = true
#   owners      = [var.ami_owner]

#   filter {
#     name   = "name"
#     values = [var.ami_name_filter]
#   }
# }

resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.jenkins-profile.name
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data

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

data "aws_iam_policy_document" "jenkins" {
  statement {
    actions   = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::nhbs-dev-tfstate",
      "arn:aws:s3:::nhbs-dev-tfstate/*"      
    ]
    effect = "Allow"
  }
  statement {
    actions   = [
      "ec2:Describe*",

      "ec2:CreateVpc",
      "ec2:DeleteVpc",

      "ec2:CreateSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:DeleteSubnet",

      "ec2:CreateInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:DeleteInternetGateway",

      "ec2:CreateRouteTable",
      "ec2:AssociateRouteTable",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
      "ec2:DeleteRoute",

      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",

      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:ModifyInstanceAttribute",

      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]
    effect = "Allow"
  }
  statement {
    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:UpdateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListAttachedRolePolicies",

      "iam:CreateInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile"
    ]
    resources = [
        "arn:aws:iam::004401752458:role/iamr-jenkins",
        "arn:aws:iam::004401752458:instance-profile/jenkins-profile",
        "arn:aws:iam::004401752458:policy/iamp-jenkins"
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::004401752458:role/iamr-jenkins"
    ]
    condition {
      test = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "ec2.amazonaws.com"
      ]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# resource "aws_iam_policy" "jenkins" {
#   name = "iamp-jenkins"
#   path = "/"
#   description = "Policy for Jenkins IAM role"

#   policy = data.aws_iam_policy_document.jenkins
# }

resource "aws_iam_role" "jenkins" {
  name = "iamr-jenkins"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  
}

resource "aws_iam_policy" "jenkins" {
  name = "iamp-jenkins"
  description = "Jenkins IAM Policy"
  policy = data.aws_iam_policy_document.jenkins.json
}

resource "aws_iam_policy_attachment" "jenkins" {
  name = "jenkins-policy-attachment"
  roles = [aws_iam_role.jenkins.name]
  policy_arn = aws_iam_policy.jenkins.arn
}

resource "aws_iam_instance_profile" "jenkins-profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins.name
}