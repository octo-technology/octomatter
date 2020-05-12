module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "mattermost"

  load_balancer_type = "application"

  vpc_id             = data.aws_vpc.default.id
  subnets            = tolist(data.aws_subnet_ids.all.ids)
  security_groups    = [aws_security_group.alb.id]

  target_groups = [
    {
      name_prefix      = "mm"
      backend_protocol = "HTTP"
      backend_port     = 8065
      target_type      = "instance"
      health_check     = {
        path = "/"
        port = 8065
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = aws_acm_certificate.cert.arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = {
    Environment = "Test"
  }
}
