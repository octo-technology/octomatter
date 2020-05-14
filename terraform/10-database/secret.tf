resource "random_string" "random" {
  length = 16
  special = true
  override_special = "/@£$"
}

resource "aws_secretsmanager_secret" "database_secret" {
  name                = format("%s-rds-password", var.name_prefix)
  rotation_lambda_arn = aws_lambda_function.rotate_database.arn

  rotation_rules {
    automatically_after_days = 5
  }
}

resource "aws_secretsmanager_secret_version" "database_default_secret" {
  secret_id     = aws_secretsmanager_secret.database_secret.id
  secret_string = <<EOT
  {
    "engine": "mysql",
    "host": "${module.aurora.this_rds_cluster_endpoint}",
    "username": "${module.aurora.this_rds_cluster_master_username}",
    "password": "${random_string.random.result}",
    "dbname": "${module.aurora.this_rds_cluster_database_name}",
    "port": ${module.aurora.this_rds_cluster_port}
  }
  EOT
}

resource "aws_lambda_function" "rotate_database" {
  filename           = "${path.module}/${var.filename}.zip"
  function_name      = format("%s-rotator", var.name_prefix)
  role               = aws_iam_role.lambda_rotation.arn
  handler            = "lambda_function.lambda_handler"
  source_code_hash   = filebase64sha256("${path.module}/${var.filename}.zip")
  runtime            = "python2.7"

  vpc_config {
    subnet_ids         = data.aws_subnet_ids.all.ids
    security_group_ids = [aws_security_group.lambda_rotation.id]
  }

  timeout            = 30
  description        = "Conducts an AWS SecretsManager secret rotation for RDS MySQL using single user rotation scheme"
  environment {
    variables = { #https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }
}

resource "aws_lambda_permission" "allow_secret_manager_call_lambda" {
    function_name = aws_lambda_function.rotate_database.function_name
    statement_id = "AllowExecutionSecretManager"
    action = "lambda:InvokeFunction"
    principal = "secretsmanager.amazonaws.com"
}

resource "aws_iam_role" "lambda_rotation" {
  name = format("%s-rotation-lambda", var.name_prefix)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_rotation" {
  name       = format("%s-rotation-lambda", var.name_prefix)
  roles      = [aws_iam_role.lambda_rotation.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "SecretsManagerRDSMySQLRotationSingleUserRolePolicy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
    ]
    resources = [ "*",]
  }
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      format("arn:%s:secretsmanager:%s:%s:secret:*", data.aws_partition.current.partition, data.aws_region.current.name, data.aws_caller_identity.current.account_id),
    ]
  }
  statement {
    actions = ["secretsmanager:GetRandomPassword"]
    resources = ["*",]
  }
}

resource "aws_iam_policy" "SecretsManagerRDSMySQLRotationSingleUserRolePolicy" {
  name   = format("%s-SecretsManagerRDSMySQLRotationSingleUserRolePolicy", var.name_prefix)
  path   = "/"
  policy = data.aws_iam_policy_document.SecretsManagerRDSMySQLRotationSingleUserRolePolicy.json
}

resource "aws_iam_policy_attachment" "SecretsManagerRDSMySQLRotationSingleUserRolePolicy" {
  name       = format("%s-SecretsManagerRDSMySQLRotationSingleUserRolePolicy", var.name_prefix)
  roles      = [aws_iam_role.lambda_rotation.name]
  policy_arn = aws_iam_policy.SecretsManagerRDSMySQLRotationSingleUserRolePolicy.arn
}

resource "aws_security_group" "lambda_rotation" {
    vpc_id = data.aws_vpc.default.id
    name = format("%s-lambda-secretmanager", var.name_prefix)

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
  }
}
