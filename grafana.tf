resource "aws_iam_role" "grafana_role" {
  name = "${var.app_name}-${var.environment}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "grafana.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-grafana-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "grafana_cloudwatch_policy" {
  name = "${var.app_name}-${var.environment}-grafana-cloudwatch-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-grafana-cloudwatch-policy"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "grafana_attach" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.grafana_cloudwatch_policy.arn
}

resource "aws_grafana_workspace" "this" {
  name        = "${var.app_name}-${var.environment}-grafana"
  description = "Observability workspace for ${var.app_name} (${var.environment})"

  authentication_providers = ["AWS_SSO"]

  account_access_type = "CURRENT_ACCOUNT"
  permission_type     = "CUSTOMER_MANAGED"

  role_arn = aws_iam_role.grafana_role.arn

  tags = {
    Service     = "${var.app_name}-${var.environment}-observability"
    Environment = var.environment
  }
}

output "grafana_workspace_url" {
  value = aws_grafana_workspace.this.endpoint
}

output "grafana_role_arn" {
  value = aws_iam_role.grafana_role.arn
}
