# ============================================================
# 09-rds.tf — RDS (관계형 데이터베이스 서비스)
# AWS가 설치·패치·백업을 대신 관리해 주는 관리형 DB.
# 여기서는 MariaDB를 프라이빗 서브넷 2개(2a, 2c)에 배포한다.
#
# 구성 순서: 서브넷 그룹(DB가 들어갈 서브넷 묶음) → 파라미터 그룹(DB 엔진 설정)
#           → db_instance(실제 DB)
# ※ password 평문 입력은 실습용 — 운영에서는 Secrets Manager·변수로 관리
# ============================================================

# RDS 서브넷 그룹 생성
# DB 인스턴스가 배치될 서브넷 후보 묶음 — RDS는 반드시 2개 이상의 AZ에 걸친
# 서브넷 그룹이 필요하다
resource "aws_db_subnet_group" "terraform_rds_subnet_group" {
  name       = "terraform-rds-subnet-group"
  subnet_ids = [aws_subnet.terraform_pri_subnet_2a.id, aws_subnet.terraform_pri_subnet_2c.id]

  tags = {
    Name = "terraform-rds-subnet-group"
  }
}

# MariaDB Parameter Group 설정
# DB 엔진의 세부 동작을 바꾸는 설정 묶음 (my.cnf에 해당)
resource "aws_db_parameter_group" "terraform_mariadb_parameter_group" {
  name        = "terraform-mariadb-parameter-group"
  family      = "mariadb10.11" # 사용 중인 MariaDB 버전에 맞게 조정
  description = "Custom parameter group for MariaDB"

  # 동시 접속 수 제한 — db.t3.micro 기본값보다 여유 있게 상향
  parameter {
    name  = "max_connections"
    value = "150"
  }

  # DB 서버 타임존 — 한국 시간 기준
  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  # 문자셋을 utf8mb4로 통일 — 이모지 등 4바이트 문자까지 저장 가능
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_filesystem"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  # 정렬 규칙 — utf8mb4에 맞는 unicode collation
  parameter {
    name  = "collation_connection"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  # 바이너리 로그 형식 — ROW 방식 (복제·CDC 시 행 단위 변경 추적에 필요)
  parameter {
    name  = "binlog_format"
    value = "ROW"
  }
}

# RDS 생성
resource "aws_db_instance" "terraform_mariadb_rds" {
  identifier_prefix    = "terraform-mariadb-rds" # 인스턴스 식별자 접두사
  allocated_storage    = 10                      # 스토리지 10GB
  engine               = "mariadb"
  engine_version       = "10.11.13"
  instance_class       = "db.t3.micro"           # 최소 사양 — 실습용
  db_name              = "terraform_mariadb_rds" # 영문자로 시작해야 하며 영문자와 숫자, _만 가능
  username             = "root"
  password             = "Password1234" # 8자 이상, 영문 대소문자, 숫자 및 특수 문자를 혼합하여 사용
  parameter_group_name = aws_db_parameter_group.terraform_mariadb_parameter_group.name
  skip_final_snapshot  = true # 삭제 시 최종 스냅샷 생략 — 실습용
  #multi_az               = true                    # 주석 해제 시 이중화(standby) — 비용 증가
  db_subnet_group_name   = aws_db_subnet_group.terraform_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.terraform_sg_rds.id]

  tags = {
    Name = "terraform-mariadb-rds"
  }
}
