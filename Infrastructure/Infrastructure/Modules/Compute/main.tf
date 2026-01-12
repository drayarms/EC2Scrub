#IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-vpc-ec2-reader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

#Permissioin to Manage ENIs
resource "aws_iam_role_policy" "lambda_vpc_access" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ]
      Resource = "*"
    }]
  })
}

#Permission that allows lambda to retrieve EC2s in the VPC
resource "aws_iam_role_policy" "lambda_ec2_read" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags"
      ]
      Resource = "*"
    }]
  })
}

# Permission to list and delete EC2 snapshots
resource "aws_iam_role_policy" "lambda_ec2_snapshot_cleanup" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeSnapshots",
        "ec2:DeleteSnapshot"
      ]
      Resource = "*"
    }]
  })
}

#CloudWatch Logs Permission for Lambda
resource "aws_iam_role_policy" "lambda_logging" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

#Security Group for Lambda ENIs. Outbout only is sufficient
resource "aws_security_group" "lambda_sg" {
	name  = "lambda-private-egress"
	description = "Allows HTTP egress"
	vpc_id = var.aws_vpc_id # Declared in variables.tf. Defined as an output of network #aws_vpc.name.id and consumed by root main.tf under Compute module

	egress {
		description = "All outbound"
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags = {
		Name = "lambda-sg"
	}
}

#Terraform's Built-In Archiver
data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = var.lambda_source_path
  output_path = "${path.module}/lambda.zip"
}

#Lambda Function (Attached to all Private Subnets)
resource "aws_lambda_function" "ec2_inventory" {
  function_name = var.lambda_name
  role = aws_iam_role.lambda_role.arn
  runtime = "python3.12"
  handler = var.lambda_handler

  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 #output_base64sha256 is an attrib of the archive_file data src

  timeout = 30

  vpc_config {
    subnet_ids = var.aws_private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name = var.lambda_name
  }
}

#Event bridge to trigger lambda function daily
resource "aws_cloudwatch_event_rule" "daily_ec2_scrub" {
  name = var.event_bridge_name
  description = "Trigger EC2 snapshot scrubbing Lambda daily"
  schedule_expression = "cron(0 2 * * ? *)"  #daily 2:00 AM UTC
  is_enabled = true
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowEventBridgeInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_inventory.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_ec2_scrub.arn
}

# Connect EventBridge rule to Lambda
resource "aws_cloudwatch_event_target" "daily_ec2_scrub_target" {
  rule = aws_cloudwatch_event_rule.daily_ec2_scrub.name
  target_id = var.event_bridge_target_id
  arn = aws_lambda_function.ec2_inventory.arn

  input = jsonencode({
    DryRun = true
  })

  depends_on = [aws_lambda_permission.allow_eventbridge]
}