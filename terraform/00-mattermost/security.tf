
resource "aws_security_group" "app_servers" {
  name        = "app-servers"
  description = "For application servers"
  vpc_id      = data.aws_vpc.default.id
}

#resource "aws_security_group_rule" "allow_ssh" {
#  type                     = "ingress"
#  from_port                = 22
#  to_port                  = 22
#  protocol                 = "tcp"
#  cidr_blocks              = ["0.0.0.0/0"]
#  security_group_id        = aws_security_group.app_servers.id
#}

resource "aws_security_group_rule" "allow_mattermost" {
  type                     = "ingress"
  from_port                = 8065
  to_port                  = 8065
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "allow_outbound" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.app_servers.id
}

resource "aws_security_group" "alb" {
  name        = "mattermost-alb"
  description = "For mattermost alb"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "allow_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "allow_outbound_alb" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.alb.id
}
