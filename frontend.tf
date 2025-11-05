# --- 1. Bucket S3 para el Frontend (Angular) ---
resource "aws_s3_bucket" "frontend" {
  bucket = "mi-app-frontend-bucket-${data.aws_caller_identity.current.account_id}" # Nombre de bucket debe ser único globalmente

  tags = {
    Name = "frontend-bucket"
  }
}

# --- 2. Bloqueo de Acceso Público ---
# El bucket debe ser PRIVADO. Solo CloudFront podrá leerlo.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 3. Identidad de CloudFront (OAI) ---
# Creamos un "usuario" especial para que CloudFront acceda a S3.
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI para el bucket S3 del frontend"
}

# --- 4. Política del Bucket S3 ---
# Le damos permiso a la OAI de CloudFront para leer (GetObject)
# los archivos de nuestro bucket.
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontRead",
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# --- 5. Distribución de CloudFront (El CDN) ---
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html" # Objeto raíz (tu Angular)

  # --- Origen 1: El Bucket S3 (Default) ---
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-Frontend"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # --- Origen 2: El Load Balancer (para la API) ---
  origin {
    domain_name = aws_lb.main.dns_name # El DNS de tu ALB
    origin_id   = "ALB-API-Backend"

    # Configuración de origen personalizado (no S3)
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # El ALB escucha en 80
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --- Comportamiento por defecto (Sirve el S3) ---
  default_cache_behavior {
    target_origin_id = "S3-Frontend"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # --- Comportamiento de API (Redirige al ALB) ---
  # ¡La conexión clave!
  ordered_cache_behavior {
    path_pattern     = "/api/*" # Todas las peticiones a /api...
    target_origin_id = "ALB-API-Backend" # ...van al ALB.

    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"] # Cachear solo GET/HEAD
    viewer_protocol_policy = "redirect-to-https"

    # Reenvía todo al backend (cookies, headers, etc.)
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["*"]
    }
  }

  # --- Manejo de errores (para SPA/Angular) ---
  # Si Angular usa rutas (ej: /reservas) y el usuario refresca,
  # S3 dará un 404. Esto lo intercepta y devuelve index.html
  # para que el router de Angular se encargue.
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # Configuración de SSL (Usando el certificado por defecto de CloudFront)
  # Para un dominio personalizado, añadirías un 'acm_certificate_arn'.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}