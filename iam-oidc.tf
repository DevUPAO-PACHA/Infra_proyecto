# 1) OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d9c758c50a11cb01a15a519e098a0c71e",
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# 2) PLAN ROLE (Pull Requests)
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
        # Permite PRs en este repo específicamente
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
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::tfstate-dev-974646089872/dev/terraform.tfstate"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::tfstate-dev-974646089872"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/tf-lock-dev"
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
  value = aws_iam_role.github_actions_plan.arn
}

# 3) APPLY ROLE (Push a main)
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
        # Solo cuando se ejecuta en branch `main`
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
  value = aws_iam_role.github_actions_apply.arn
}

# 4) DESTROY ROLE (Manual workflow_dispatch)
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
        # Igual que apply, destroy solo debe funcionar en main
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
  value = aws_iam_role.github_actions_destroy.arn
}
