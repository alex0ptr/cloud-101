resource "aws_lb" "app" {
  name_prefix        = "${local.stack_short}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.app_loadbalancer.id}"]
  subnets            = ["${split(",", aws_cloudformation_stack.vpc.outputs["SubnetsPublic"])}"]
}

output "curl_command" {
  value = "curl -s http://${aws_lb.app.dns_name}/jokes | jp '@'"
}

resource "aws_security_group" "app_loadbalancer" {
  name   = "app-loadbalancer-${local.stack}"
  vpc_id = "${aws_cloudformation_stack.vpc.outputs["VPC"]}"
}

resource "aws_security_group_rule" "alb_allow_all_outgoing" {
  security_group_id = "${aws_security_group.app_loadbalancer.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_allow_all_incoming" {
  security_group_id = "${aws_security_group.app_loadbalancer.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = "${aws_lb.app.arn}"
  port              = "80"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "host_based_routing" {
  listener_arn = "${aws_lb_listener.app.arn}"
  priority     = 99

  condition {
    field  = "path-pattern"
    values = ["/jokes*"]
  }

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.app.arn}"
  }
}

resource "aws_lb_target_group" "app" {
  name_prefix = "${local.stack_short}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${aws_cloudformation_stack.vpc.outputs["VPC"]}"

  health_check {
    interval = 5
    path     = "/actuator/health"
    port     = 8080
    timeout  = 3
  }
}
