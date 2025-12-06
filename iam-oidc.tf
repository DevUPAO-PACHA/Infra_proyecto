
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d9c758c50a11cb01a15a519e098a0c71e",
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

#  PLAN ROLE
resource "aws_iam_role" "github_actions_plan" {
  name = "${var.app_name}-${var.environment}-gha-plan-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" : "repo:DevUPAO-PACHA/Infra_proyecto:pull_request"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-gha-plan-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "plan_backend_access" {
  name = "${var.app_name}-${var.environment}-gha-plan-backend-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::${var.backend_s3_bucket_name}/${var.environment}/terraform.tfstate"
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::${var.backend_s3_bucket_name}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.backend_dynamo_table_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "plan_readonly_access" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "plan_backend_access_attach" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = aws_iam_policy.plan_backend_access.arn
}

output "plan_role_arn" {
  description = "ARN del rol para el pipeline de 'plan'"
  value       = aws_iam_role.github_actions_plan.arn
}

#  APPLY ROLE (solo producción desde main)
resource "aws_iam_role" "github_actions_apply" {
  name = "${var.app_name}-${var.environment}-gha-apply-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" : "repo:DevUPAO-PACHA/Infra_proyecto:ref:refs/heads/main"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-gha-apply-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "apply_admin_access" {
  role       = aws_iam_role.github_actions_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "apply_role_arn" {
  description = "ARN del rol para el pipeline de 'apply'"
  value       = aws_iam_role.github_actions_apply.arn
}

#  DESTROY ROLE (manual)
resource "aws_iam_role" "github_actions_destroy" {
  name = "${var.app_name}-${var.environment}-gha-destroy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        # Solo permite ejecución manual ("workflow_dispatch")
        StringLike = {
          "token.actions.githubusercontent.com:sub" : "repo:DevUPAO-PACHA/Infra_proyecto:ref:refs/heads/main"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-gha-destroy-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "destroy_admin_access" {
  role       = aws_iam_role.github_actions_destroy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "destroy_role_arn" {
  description = "ARN del rol para el pipeline de 'destroy'"
  value       = aws_iam_role.github_actions_destroy.arn
}
