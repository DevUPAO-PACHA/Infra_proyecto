# iam-oidc.tf
# Configura el proveedor OIDC y el Rol IAM para GitHub Actions

# 1. Configura a GitHub como un proveedor de identidad OIDC
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # Este thumbprint es público y estándar para GitHub.
  # A veces AWS pide actualizarlo, pero este es el más común.
  thumbprint_list = ["6938fd4d9c758c50a11cb01a15a519e098a0c71e", "1b511abead59c6ce207077c0bf0e0043b1382612"]
}

# 2. Crea el Rol IAM que GitHub Actions asumirá
resource "aws_iam_role" "github_actions_plan" {
  name = "github-actions-plan-role"

  # La política de confianza: permite a GitHub asumir este rol
  # SOLAMENTE en Pull Requests de tu repositorio.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          # Confía en el proveedor OIDC que acabamos de registrar
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # ¡IMPORTANTE! Cambia esto por tu usuario/repo
            "token.actions.githubusercontent.com:sub" : "repo:DevUPAO-PACHA/Infra_proyecto:pull_request"
          }
        }
      }
    ]
  })
}

# 3. Política de permisos para que el rol lea el backend
resource "aws_iam_policy" "plan_backend_access" {
  name = "github-actions-plan-backend-access"

  # Esta política es muy específica:
  # Permite leer/escribir en la tabla de bloqueo (para 'plan')
  # y leer el archivo de estado de S3.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::${var.backend_s3_bucket_name}/global/terraform.tfstate"
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::${var.backend_s3_bucket_name}"
      },
      {
        Effect   = "Allow",
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.backend_dynamo_table_name}"
      }
    ]
  })
}

# 4. Política de permisos para que el rol ejecute 'plan'
# 'plan' necesita muchos permisos de "lectura" para ver qué hay en AWS
resource "aws_iam_role_policy_attachment" "plan_readonly_access" {
  role       = aws_iam_role.github_actions_plan.name
  # Usamos la política gestionada por AWS "ReadOnlyAccess"
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 5. Adjuntamos la política del backend al rol
resource "aws_iam_role_policy_attachment" "plan_backend_access" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = aws_iam_policy.plan_backend_access.arn
}

# 6. Un output para obtener el ARN del rol
output "plan_role_arn" {
  description = "ARN del rol para el pipeline de 'plan'"
  value       = aws_iam_role.github_actions_plan.arn
}

# --- AÑADIR ESTE CÓDIGO AL FINAL DE iam-oidc.tf ---

# --- 7. Rol de IAM para "Apply" (El Constructor) ---
resource "aws_iam_role" "github_actions_apply" {
  name = "github-actions-apply-role"

  # Política de confianza:
  # Confía en GitHub, PERO SOLO para la rama 'main'.
  # ¡Nunca permitas que un PR ejecute 'apply'!
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            # Esta es la diferencia clave:
            # "ref:refs/heads/main" significa "solo la rama main".
            "token.actions.githubusercontent.com:sub" : "repo:DevUPAO-PACHA/Infra_proyecto:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# --- 8. Permisos de "Apply" ---
#
# ----------------- ¡¡ADVERTENCIA!! -----------------
# Le estamos dando 'AdministratorAccess'. Esto da poder TOTAL sobre tu cuenta.
# Es la forma más fácil de empezar nuestro tutorial.
# En una empresa real, deberías crear una política personalizada
# con los permisos mínimos necesarios.
# ---------------------------------------------------
resource "aws_iam_role_policy_attachment" "apply_admin_access" {
  role       = aws_iam_role.github_actions_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- 9. Output para el nuevo ARN ---
output "apply_role_arn" {
  description = "ARN del rol para el pipeline de 'apply'"
  value       = aws_iam_role.github_actions_apply.arn
}

# --- AÑADIR ESTE CÓDIGO AL FINAL DE iam-oidc.tf ---

# --- 10. Rol de IAM para "Destroy" (Manual) ---
resource "aws_iam_role" "github_actions_destroy" {
  name = "github-actions-destroy-role"

  # Política de confianza:
  # Solo confía en la rama 'main', que es donde vivirá
  # el workflow manual 'workflow_dispatch'.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
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
      }
    ]
  })
}

# --- 11. Permisos de "Destroy" ---
# También necesita 'AdministratorAccess' para poder borrar todo.
resource "aws_iam_role_policy_attachment" "destroy_admin_access" {
  role       = aws_iam_role.github_actions_destroy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- 12. Output para el nuevo ARN ---
output "destroy_role_arn" {
  description = "ARN del rol para el pipeline de 'destroy'"
  value       = aws_iam_role.github_actions_destroy.arn
}