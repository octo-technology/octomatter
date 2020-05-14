module "aurora" {
  source                = "terraform-aws-modules/rds-aurora/aws"
  version               = "2.17.0"
  name                  = var.name_prefix
  engine                = "aurora"
  engine_mode           = "serverless"
  replica_scale_enabled = false
  replica_count         = 0

  password = random_string.random.result

  backtrack_window = 10 # ignored in serverless

  subnets                         = data.aws_subnet_ids.all.ids
  vpc_id                          = data.aws_vpc.default.id
  monitoring_interval             = 60
  instance_type                   = "db.t3.medium"
  apply_immediately               = true
  skip_final_snapshot             = true
  storage_encrypted               = true
  db_parameter_group_name         = aws_db_parameter_group.aurora_db_postgres96_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_postgres96_parameter_group.id

  scaling_configuration = {
    auto_pause               = true
    max_capacity             = 2
    min_capacity             = 1
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
}

resource "aws_db_parameter_group" "aurora_db_postgres96_parameter_group" {
  name        = format("%s-parameter-group", var.name_prefix)
  family      = "aurora5.6"
  description = "test-aurora56-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_postgres96_parameter_group" {
  name        = format("%s-cluster-parameter-group", var.name_prefix)
  family      = "aurora5.6"
  description = "test-aurora56-cluster-parameter-group"
}

resource "aws_security_group_rule" "allow_access" {
  type                     = "ingress"
  from_port                = module.aurora.this_rds_cluster_port
  to_port                  = module.aurora.this_rds_cluster_port
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.app_servers.id
  security_group_id        = module.aurora.this_security_group_id
}

resource "aws_security_group_rule" "allow_lambda" {
  type                     = "ingress"
  from_port                = module.aurora.this_rds_cluster_port
  to_port                  = module.aurora.this_rds_cluster_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_rotation.id
  security_group_id        = module.aurora.this_security_group_id
}

