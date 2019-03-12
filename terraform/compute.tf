resource "aws_launch_configuration" "app" {
  name_prefix     = "app-${local.stack}"
  image_id        = "${var.machine_image}"
  instance_type   = "t3.micro"
  key_name        = "${aws_key_pair.root.key_name}"
  security_groups = ["${aws_security_group.app.id}"]

  user_data_base64 = "${data.template_cloudinit_config.config.rendered}"

  iam_instance_profile = "${aws_iam_instance_profile.app.name}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "root" {
  key_name_prefix = "root-${local.stack}"
  public_key      = "${file(var.public_key)}"
}

resource "aws_security_group" "app" {
  name   = "app-${local.stack}"
  vpc_id = "${aws_cloudformation_stack.vpc.outputs["VPC"]}"
}

resource "aws_security_group_rule" "allow_ssh_from_bastion" {
  security_group_id        = "${aws_security_group.app.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_cloudformation_stack.bastion.outputs["SecurityGroup"]}"
}

resource "aws_security_group_rule" "allow_http_from_alb" {
  security_group_id        = "${aws_security_group.app.id}"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.app_loadbalancer.id}"
}

resource "aws_security_group_rule" "allow_all_outgoing" {
  security_group_id = "${aws_security_group.app.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "app" {
  name_prefix          = "app-${local.stack}"
  max_size             = 4
  desired_capacity     = "${var.machine_count}"
  min_size             = 0
  launch_configuration = "${aws_launch_configuration.app.id}"
  vpc_zone_identifier  = ["${split(",", aws_cloudformation_stack.vpc.outputs["SubnetsPrivate"])}"]

  health_check_type         = "ELB"
  target_group_arns         = ["${aws_lb_target_group.app.arn}"]
  health_check_grace_period = "300"

  lifecycle {
    create_before_destroy = true
  }

  termination_policies = ["OldestLaunchConfiguration"]

  tag {
    key                 = "Name"
    value               = "app-${local.stack}"
    propagate_at_launch = true
  }
}

data "aws_ecr_repository" "app" {
  name = "dragonjokes"
}

data "template_file" "cloud_init" {
  template = "${file("instance/cloud-init.sh")}"

  vars {
    docker_image = "${data.aws_ecr_repository.app.repository_url}:${var.dragonjokes_version}"
    table_name   = "${aws_dynamodb_table.app_jokes.name}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config
packages:
  - cowsay
users:
  - default
  - name: app
    groups: docker
write_files:
  - content: |
      ${base64encode(file("instance/application.yml"))}
    encoding: b64
    owner: app:app
    path: /home/app/application.yml
    permissions: '0655'
EOF
  }

  part {
    filename     = "instance/cloud-init.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.cloud_init.rendered}"
  }
}
