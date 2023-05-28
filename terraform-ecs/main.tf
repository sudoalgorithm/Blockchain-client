#Creates the VPC for ecs cluster
resource "aws_vpc" "ecs_cluster_vpc" {
  cidr_block = var.vpc_cidr_range

  tags = {
    Name        = var.vpc_name
    environment = var.env
    created_by  = local.created_by
  }
}

#Creates the public subnets in ecs cluster vpc across all the az of aws in specified region
resource "aws_subnet" "ecs_cluster_vpc_public_subnets" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  count      = length(var.public_subnet_cidrs)
  cidr_block = element(var.public_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)

  map_public_ip_on_launch = true

  tags = {
    Name        = join("-", [var.public_subnet_name, count.index + 1])
    environment = var.env
    created_by  = local.created_by
  }
}

#Creates the private subnets in ecs cluster vpc across all the az of aws in specified region
resource "aws_subnet" "ecs_cluster_vpc_private_subnets" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  count      = length(var.private_subnet_cidrs)
  cidr_block = element(var.private_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)

  tags = {
    Name        = join("-", [var.private_subnet_name, count.index + 1])
    environment = var.env
    created_by  = local.created_by
  }
}

#Internet Gateway
resource "aws_internet_gateway" "ecs_cluster_vpc_internet_gw" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  tags = {
    Name        = var.internet_gateway
    environment = var.env
    created_by  = local.created_by
  }
}

#Route table for the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  tags = {
    Name        = var.public_route_table
    environment = var.env
    created_by  = local.created_by
  }
}

#Route associated to the public route table
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.public_destination_cidr_block
  gateway_id             = aws_internet_gateway.ecs_cluster_vpc_internet_gw.id
}

#Route table association
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.ecs_cluster_vpc_public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

#Elastic IP Address
resource "aws_eip" "nat_gateway_eip" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
}

#Nat Gateway
resource "aws_nat_gateway" "ecs_vpc_nat_gateway" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = element(aws_eip.nat_gateway_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.ecs_cluster_vpc_private_subnets.*.id, count.index)
  depends_on    = [aws_internet_gateway.ecs_cluster_vpc_internet_gw]
}

#Private Route Table
resource "aws_route_table" "private_route_table" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.ecs_cluster_vpc.id
}

#Route associated to the private route table 
resource "aws_route" "private_route" {
  count                  = length(compact(var.private_subnet_cidrs))
  route_table_id         = element(aws_route_table.private_route_table.*.id, count.index)
  destination_cidr_block = var.private_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.ecs_vpc_nat_gateway.*.id, count.index)
}

#Route table association
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.ecs_cluster_vpc_private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

#Creates the ecs cluster
resource "aws_ecs_cluster" "blockchain_clinet_ecs_cluster" {
  name = var.ecs_cluster_name

  tags = {
    Name        = var.ecs_cluster_name
    environment = var.env
    created_by  = local.created_by
  }
}

#Create the IAM role providing correct permission to the ecs task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "blockchain-client-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

#Create the task defination
resource "aws_ecs_task_definition" "main_task" {
  family                   = "blockchain_client_service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name        = "blockchain-clinet"
    image       = "${aws_ecr_repository.blockchain_client_repo.image.id}"
    essential   = true
    environment = "${var.env}"
    portMappings = [{
      protocol      = "tcp"
      containerPort = "${var.container_port}"
      hostPort      = "${var.container_port}"
    }]
  }])
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#Security group for ecs
resource "aws_security_group" "ecs_tasks" {
  name   = join("-", [var.ecs_security_group, var.env])
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  ingress {
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#Security group for alb
resource "aws_security_group" "ecs_alb_sg" {
  name   = join("-", [var.alb_security_group, var.env])
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "blockchain_client_alb_name" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = aws_security_group.ecs_alb_sg.id
  count              = length(var.public_subnet_cidrs)
  subnets            = element(aws_subnet.ecs_cluster_vpc_public_subnets.*.id, count.index)

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "main" {
  name        = var.alb_trage_group_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_cluster_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = data.aws_lb.blockchain_client_alb_name.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 3000
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_ecs_service" "blockchain_client_ecs_service" {
  name                               = var.blockchain_client_service_name
  cluster                            = aws_ecs_cluster.blockchain_clinet_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.main_task.arn
  desired_count                      = 3
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = aws_security_group.ecs_tasks.id
    subnets          = aws_subnet.ecs_cluster_vpc_private_subnets.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = "blockchain-clinet"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.blockchain_clinet_ecs_cluster.name}/${aws_ecs_service.blockchain_client_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}