resource "aws_cloudformation_stack" "vpc" {
  name         = "${local.stack}-vpc"
  template_url = "https://s3-eu-west-1.amazonaws.com/widdix-aws-cf-templates-releases-eu-west-1/stable/vpc/vpc-2azs.yaml"
}

resource "aws_cloudformation_stack" "nat_a" {
  name         = "${local.stack}-nat-a"
  template_url = "https://s3-eu-west-1.amazonaws.com/widdix-aws-cf-templates-releases-eu-west-1/stable/vpc/vpc-nat-gateway.yaml"

  parameters = {
    ParentVPCStack = aws_cloudformation_stack.vpc.name
    SubnetZone     = "A"
  }
}

resource "aws_cloudformation_stack" "nat_b" {
  name         = "${local.stack}-nat-b"
  template_url = "https://s3-eu-west-1.amazonaws.com/widdix-aws-cf-templates-releases-eu-west-1/stable/vpc/vpc-nat-gateway.yaml"

  parameters = {
    ParentVPCStack = aws_cloudformation_stack.vpc.name
    SubnetZone     = "B"
  }
}

resource "aws_cloudformation_stack" "bastion" {
  name         = "${local.stack}-bastion"
  template_url = "https://s3-eu-west-1.amazonaws.com/widdix-aws-cf-templates-releases-eu-west-1/stable/vpc/vpc-ssh-bastion.yaml"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    ParentVPCStack   = aws_cloudformation_stack.vpc.name
    IAMUserSSHAccess = "true"
  }
}

data "aws_caller_identity" "current" {
}

output "ssh_jump_command" {
  value = "ssh -A -J ${element(split("/", data.aws_caller_identity.current.arn), 1)}@${aws_cloudformation_stack.bastion.outputs["IPAddress"]} ec2-user@IP"
}

