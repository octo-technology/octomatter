data "aws_route53_zone" "rrops" {
  name         = "rrops.fr."
}

data "aws_lb" "mm" {
  name = "mattermost"
}
