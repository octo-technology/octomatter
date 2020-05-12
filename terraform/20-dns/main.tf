resource "aws_route53_record" "mattermost" {
  zone_id = data.aws_route53_zone.rrops.id
  name    = "mattermost"
  type    = "CNAME"
  ttl     = "300"
  records = [data.aws_lb.mm.dns_name]
}
