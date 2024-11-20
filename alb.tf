resource "aws_lb_target_group" "blue" {
  name        = "${var.env_prefix}-${var.environment}-blue-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.env_prefix}-${var.environment}-green-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = module.acm.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
      message_body = "unauthorized"
    }
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 1
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }
    }
  }

  condition {
    host_header {
      values = [var.site_domain]
    }
  }
}
