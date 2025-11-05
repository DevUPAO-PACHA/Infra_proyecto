# --- 1. Creación de la VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "mi-app-vpc"
  }
}

# --- 2. Subredes Públicas (para ALB y NAT Gateways) ---
# Usamos 'count' para crear una subred por cada CIDR en nuestra variable
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Importante para subredes públicas

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# --- 3. Subredes Privadas (para ECS Fargate) ---
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# --- 4. Subredes de Base de Datos (para RDS) ---
resource "aws_subnet" "database" {
  count             = length(var.db_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "db-subnet-${count.index + 1}"
  }
}

# --- 5. Internet Gateway (Para dar salida a las subredes públicas) ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# --- 6. NAT Gateways (Para dar salida a las subredes privadas) ---
# (Necesita una IP Elástica primero)

resource "aws_eip" "nat" {
  count  = length(var.public_subnets_cidr) # 1 NAT por AZ pública
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # El NAT vive en la subred pública

  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# --- 7. Tablas de Rutas ---

# Ruta para subredes PÚBLICAS (tráfico 0.0.0.0/0 -> Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Ruta para subredes PRIVADAS (tráfico 0.0.0.0/0 -> NAT Gateway)
resource "aws_route_table" "private" {
  count  = length(var.private_subnets_cidr)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "private-route-table-${count.index + 1}"
  }
}

# Ruta para subredes de BD (sin salida a internet por defecto)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "database-route-table"
  }
}

# --- 8. Asociaciones de Tablas de Rutas ---

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count          = length(var.db_subnets_cidr)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# --- 9. Grupo de Subredes de BD (Requerido por RDS) ---
# Aurora necesita saber en qué subredes (privadas) debe vivir.
resource "aws_db_subnet_group" "aurora" {
  name       = "aurora-db-subnet-group"
  subnet_ids = aws_subnet.database.*.id # Recoge los IDs de todas las subredes de BD creadas

  tags = {
    Name = "Grupo de subredes para Aurora"
  }
}

# Esto es una prueba del pipeline.