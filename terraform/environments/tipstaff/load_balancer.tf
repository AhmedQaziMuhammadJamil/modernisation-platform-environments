resource "aws_security_group" "tipstaff_dev_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "ingress_traffic_lb" {
  for_each          = local.application_data.ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = 3000
  protocol          = "tcp"
  security_group_id = aws_security_group.tipstaff_dev_lb_sc.id
  to_port           = 3000
  type              = "ingress"
  cidr_blocks       = [local.application_data.accounts[local.environment].moj_ip]
}

resource "aws_security_group_rule" "egress_traffic_lb" {
  for_each          = local.application_data.ec2_sg_rules
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.tipstaff_dev_lb_sc.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "tipstaff_dev_lb" {
  name                       = "tipstaff-dev-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tipstaff_dev_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tipstaff_dev_lb_sc]
}

resource "aws_lb_target_group" "tipstaff_dev_target_group" {
  name                 = "tipstaff-dev-target-group"
  port                 = local.application_data.accounts[local.environment].container_port_1
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "2"
    interval            = "120"
    protocol            = "HTTP"
    port                = "3000"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}

resource "aws_lb_listener" "tipstaff_dev_lb_1" {
  load_balancer_arn = aws_lb.tipstaff_dev_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_1
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_1
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_1 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tipstaff_dev_target_group.arn
  }
}

resource "aws_lb_listener" "tipstaff_dev_lb_2" {
  depends_on = [
    aws_acm_certificate.external
  ]
  certificate_arn   = aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.tipstaff_dev_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_2
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tipstaff_dev_target_group.arn
  }
}
