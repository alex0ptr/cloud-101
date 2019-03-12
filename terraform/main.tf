variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "dragonjokes_version" {
  default = "0.0.1"
}

variable "machine_image" {
  default = "ami-0e3a8845198de41af"
}

variable "machine_count" {
  default = 2
}

terraform {
  backend "s3" {
    bucket = "terraform-alex"
    key    = "cloud-101"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "random_id" "stack_postfix" {
  byte_length = 2
}

locals {
  stack = "${terraform.workspace}-${random_id.stack_postfix.hex}"
  stack_short ="${random_id.stack_postfix.hex}"
}
