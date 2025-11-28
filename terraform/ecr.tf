resource "aws_ecr_repository" "backend" {
  name = "queue-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "queue-backend-ecr"
    Project = "queue-system"
  }
}
