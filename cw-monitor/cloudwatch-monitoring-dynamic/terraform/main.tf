provider "aws" {
  region = var.region
}

# =========================
# SNS Topic for Alerts
# =========================
resource "aws_sns_topic" "alerts" {
  name = "ec2-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =========================
# IAM Role for Lambda
# =========================
resource "aws_iam_role" "lambda_role" {
  name = "ec2-monitoring-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "sns" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ec2_readonly" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# =========================
# Lambda Function
# =========================
resource "aws_lambda_function" "ec2_monitor" {
  function_name = "ec2-monitoring-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_monitor.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  filename         = "${path.module}/lambda_monitor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_monitor.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

# =========================
# EventBridge Rule
# =========================
resource "aws_cloudwatch_event_rule" "ec2_events" {
  name        = "ec2-state-change"
  description = "Trigger on EC2 state changes"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_events.name
  target_id = "EC2Lambda"
  arn       = aws_lambda_function.ec2_monitor.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_events.arn
}

# =========================
# Auto-invoke Lambda once at deployment
# =========================
resource "null_resource" "invoke_lambda" {
  depends_on = [aws_lambda_function.ec2_monitor]

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.ec2_monitor.function_name} --payload '{}' response.json --region ${var.region}"
  }
}
