
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.13.0"

  name                   = "mattermost"
  instance_count         = 1

  ami                    = "${data.aws_ami.latest-centos.id}"
  instance_type          = "t2.medium"
  key_name               = "rre"
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.app_servers.id]
  subnet_id              = tolist(data.aws_subnet_ids.all.ids)[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.ec2.id[0]
}

resource "aws_ebs_volume" "this" {
  availability_zone = module.ec2.availability_zone[0]
  size              = 100
}

resource "aws_lb_target_group_attachment" "this" {
  count = length(module.ec2.id)
  target_group_arn = module.alb.target_group_arns[0]
  target_id        = module.ec2.id[count.index]
  port             = 8065
}
