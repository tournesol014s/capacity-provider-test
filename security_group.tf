resource "aws_security_group" "external_alb" {
  name        = "external_alb"
  description = "Security group for external ALB"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic by default"
  }
}

resource "aws_security_group_rule" "external_alb_from_internet" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.external_alb.id
  description       = "HTTP from Internet"
}

resource "aws_security_group" "ecs_service" {
  name        = "ecs_service"
  description = "Security group for ECS services"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic by default"
  }
}

resource "aws_security_group_rule" "ecs_service_from_external_alb" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 61000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.external_alb.id
  security_group_id        = aws_security_group.ecs_service.id
  description              = "HTTP from extenal ALB"
}