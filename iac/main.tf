data "aws_route53_zone" "public_hostzone" {
    name = var.hostzone
}

data "aws_ssm_parameter" "alb_name" {
    name = "/alb/name"
}

data "aws_lb" "alb_name" {
    name = data.aws_ssm_parameter.alb_name.value
}

## Used in ECS Service - Parameter store ##
data "aws_ssm_parameter" "ecs_taskexecution_role" {
    name = "/ecs/taskexecutionrolearn"
}

data "aws_ssm_parameter" "ecs_cluster_arn" {
    name = "/${var.project}/${var.environment}/ecs/clusterarn"
}

data "aws_ssm_parameter" "ecs_cluster_name" {
    name = "/${var.project}/${var.environment}/ecs/clustername"
}

#multiple queue start
data "aws_ssm_parameter" "default_sqs_queue" {
    name = "/${var.project}/${var.environment}/${var.service_name}/default/sqs/url"
}

data "aws_ssm_parameter" "default_sqs_full_url" {
    name = "/${var.project}/${var.environment}/${var.service_name}/default/sqs/full_url"
}

data "aws_ssm_parameter" "low_sqs_queue" {
    name = "/${var.project}/${var.environment}/${var.service_name}/low/sqs/url"
}

data "aws_ssm_parameter" "low_sqs_full_url" {
    name = "/${var.project}/${var.environment}/${var.service_name}/low/sqs/full_url"
}

data "aws_ssm_parameter" "high_sqs_queue" {
    name = "/${var.project}/${var.environment}/${var.service_name}/high/sqs/url"
}

data "aws_ssm_parameter" "high_sqs_full_url" {
    name = "/${var.project}/${var.environment}/${var.service_name}/high/sqs/full_url"
}
#multiple queue emd

data "aws_ssm_parameter" "public_subnet_ids" {
    name = "/vpc/publicsubnetids"
}

data "aws_ssm_parameter" "ecs_sg" {
    name = "/${var.project}/${var.environment}/ecs/securitygroupid"
}

data "aws_ssm_parameter" "vpc_id" {
    name = "/vpc/id"
}

data "aws_ssm_parameter" "listerner_arn" {
    name = "/alb/listernerarn"
}

data "aws_ssm_parameter" "redis_endpoint" {
    name = "/redis/endpoint"
}

data "aws_ssm_parameter" "redis_port" {
    name = "/redis/port"
}

data "aws_ssm_parameter" "timezone" {
    name = "/timezone"
}

data "aws_ssm_parameter" "session_domain" {
    name = "/session/domain"
}

data "aws_ssm_parameter" "session_cookie" {
    name = "/session/cookie"
}

## Used in ECS Service - AWS Secrets ##
data "aws_secretsmanager_secret" "database" {
    name = var.database_secrets
}

data "aws_secretsmanager_secret_version" "database" {
    secret_id = data.aws_secretsmanager_secret.database.id
}

data "aws_secretsmanager_secret" "common" {
    name = var.common_secrets
}

data "aws_secretsmanager_secret_version" "common" {
    secret_id = data.aws_secretsmanager_secret.common.id
}

data "aws_caller_identity" "current" {}

locals {
    image_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

##############################################################
## Resource Creation 1.1: ECS - Log Group
##############################################################
resource "aws_cloudwatch_log_group" "main" {
    name              = "${var.project}-${var.environment}-${var.service_name}"
    retention_in_days = 1

    tags = {
        Name        = "${var.project}-${var.environment}-${var.service_name}"
        Environment = var.environment
    }
}

##############################################################
## Resource Creation 1.2: ECS - Task Definition
##############################################################
resource "aws_ecs_task_definition" "service" {
    family                   = "${var.project}-${var.environment}-${var.service_name}-td"
    execution_role_arn       = data.aws_ssm_parameter.ecs_taskexecution_role.value
    task_role_arn            = data.aws_ssm_parameter.ecs_taskexecution_role.value
    cpu                      = var.deployment_mode == "FARGATE" ? var.cpu : null
    memory                   = var.deployment_mode == "FARGATE" ? var.memory : 0
    requires_compatibilities = [var.deployment_mode]
    network_mode             = var.deployment_mode == "FARGATE" ? "awsvpc" : "bridge"
    container_definitions    = jsonencode([
        {
            name         = "${var.project}-${var.environment}-${var.service_name}-php"
            image        = "${local.image_url}/${var.phpapp_image_tag}"
            essential    = true
            portMappings = [
                {
                    containerPort = 9000
                    hostPort      = var.deployment_mode == "FARGATE" ? 9000 : 0 # It should be 0 for EC2 deployment mode
                }
            ]
            environment = [
                {
                    name  = "APP_DEBUG"
                    value = "false"
                },
                {
                    name  = "APP_ENV"
                    value = var.environment
                },
                {
                    name  = "APP_URL"
                    value = "https://${var.host_header}"
                },
                {
                    name  = "ASSET_URL"
                    value = "https://${var.host_header}"
                },
                {
                    name  = "REDIS_HOST"
                    value = data.aws_ssm_parameter.redis_endpoint.value
                },
                {
                    name  = "REDIS_PORT"
                    value = data.aws_ssm_parameter.redis_port.value
                },
                {
                    name  = "LOG_CHANNEL"
                    value = "stderr"
                },
                {
                    name  = "CACHE_DRIVER"
                    value = "redis"
                },
                {
                    name  = "SESSION_DRIVER"
                    value = "database"
                },
                {
                    "name" : "DB_CONNECTION",
                    "value" : "mysql"
                },
                {
                    "name" : "DB_PORT",
                    "value" : "3306"
                },
                {
                    "name" : "DB_NAME",
                    "value" : "epos"
                },
                {
                    "name" : "DB_DATABASE",
                    "value" : "eposuser"
                },
                {
                    "name" : "FILESYSTEM_DRIVER",
                    "value" : "s3"
                },
                {
                    "name" : "BROADCAST_DRIVER",
                    "value" : "log"
                },
                {
                    "name" : "AWS_BUCKET",
                    "value" : "cloud-trans-api-test"
                },
                {
                    name  = "TIMEZONE"
                    value = data.aws_ssm_parameter.timezone.value
                },
                {
                    name  = "QUEUE_CONNECTION"
                    value = "sqs"
                },
                {
                    name  = "SQS_QUEUE"
                    value = data.aws_ssm_parameter.default_sqs_queue.value
                },
                {
                    name  = "SQS_QUEUE_DEFAULT"
                    value = data.aws_ssm_parameter.default_sqs_queue.value
                },
                {
                    name  = "QUEUE_URL_DEFAULT"
                    value = data.aws_ssm_parameter.default_sqs_full_url.value
                },
                {
                    name  = "SQS_QUEUE_LOW"
                    value = data.aws_ssm_parameter.low_sqs_queue.value
                },
                {
                    name  = "QUEUE_URL_LOW"
                    value = data.aws_ssm_parameter.low_sqs_full_url.value
                },
                {
                    name  = "SQS_QUEUE_HIGH"
                    value = data.aws_ssm_parameter.high_sqs_queue.value
                },
                {
                    name  = "QUEUE_URL_HIGH"
                    value = data.aws_ssm_parameter.high_sqs_full_url.value
                }
            ]
            secrets = [
                {
                    "name"      = "APP_KEY",
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:APP_KEY::"
                },
                {
                    "name"      = "ENCRYPT_KEY",
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:APP_KEY::"
                },
                {
                    "name"      = "AWS_ACCESS_KEY_ID",
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:AWS_ACCESS_KEY_ID::"
                },
                {
                    "name"      = "AWS_DEFAULT_REGION",
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:AWS_DEFAULT_REGION::"
                },
                {
                    "name"      = "AWS_SECRET_ACCESS_KEY",
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:AWS_SECRET_ACCESS_KEY::"
                },
                {
                    "name"      = "AWS_SNS_TOPICS_MESSAGING"
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:AWS_SNS_TOPICS_MESSAGING::"
                },
                {
                    "name"      = "DB_HOST"
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.database.arn}:DB_CLOUD_HOST::"
                },
                {
                    "name"      = "DB_USERNAME"
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.database.arn}:DB_CLOUD_USER::"
                },
                {
                    "name"      = "DB_PASSWORD"
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.database.arn}:DB_CLOUD_PASS::"
                },
                {
                    "name"      = "SQS_PREFIX"
                    "valueFrom" = "${data.aws_secretsmanager_secret_version.common.arn}:SQS_PREFIX::"
                }
            ]
            logConfiguration = {
                logDriver = "awslogs"
                options   = {
                    awslogs-group         = aws_cloudwatch_log_group.main.name
                    awslogs-region        = var.region
                    awslogs-stream-prefix = "ecs"
                }
            }
        },
        {
            name      = "${var.project}-${var.environment}-${var.service_name}-nginx"
            image     = "${local.image_url}/${var.nginx_image_tag}"
            essential = true

            portMappings = [
                {
                    containerPort = 80
                    hostPort      = var.deployment_mode == "FARGATE" ? 80 : 0 # It should be 0 for EC2 deployment mode
                }
            ]

            links = var.deployment_mode == "EC2" ? [
                "${var.project}-${var.environment}-${var.service_name}-php"
            ] : []

            environment = [
                {
                    name  = "BACKEND_URL"
                    value = var.deployment_mode == "FARGATE" ? "localhost:9000" : "${var.project}-${var.environment}-${var.service_name}-php:9000"
                }
            ]

            logConfiguration = {
                logDriver = "awslogs"
                options   = {
                    awslogs-group         = aws_cloudwatch_log_group.main.name
                    awslogs-region        = var.region
                    awslogs-stream-prefix = "ecs"
                }
            }
        }
    ])
    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
    }
}

##############################################################
## Resource Creation 1.3: ECS - ECS Service
##############################################################
resource "aws_ecs_service" "main" {
    name                   = "${var.project}-${var.environment}-${var.service_name}-nginx"
    cluster                = data.aws_ssm_parameter.ecs_cluster_arn.value
    task_definition        = aws_ecs_task_definition.service.arn
    desired_count          = var.desired_count
    enable_execute_command = true
    launch_type            = var.deployment_mode
    wait_for_steady_state  = true

    deployment_circuit_breaker {
        enable   = true
        rollback = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.main.arn
        container_name   = "${var.project}-${var.environment}-${var.service_name}-nginx"
        container_port   = 80
    }

    dynamic "network_configuration" {
        for_each = var.deployment_mode == "FARGATE" ? [1] : []
        content {
            subnets          = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
            security_groups  = [data.aws_ssm_parameter.ecs_sg.value]
            assign_public_ip = true
        }
    }
}


######################################################################
## Resource Creation 1.4: ECS - This creates Target Group and Listerner Rule
#######################################################################
resource "aws_lb_target_group" "main" {
    port        = 80
    protocol    = "HTTP"
    vpc_id      = data.aws_ssm_parameter.vpc_id.value
    target_type = var.deployment_mode == "EC2" ? "instance" : "ip"

    health_check {
        enabled             = "true"
        path                = "/health"
        healthy_threshold   = 3
        interval            = 60          # Reduce interval for more frequent checks
        matcher             = 200         # Only consider 200 OK responses as healthy
        timeout             = 45           # Reduce timeout to a more typical 5 seconds
        unhealthy_threshold = 5           # Reduce unhealthy threshold for faster removal
    }

    tags = {
        "name" = "${var.project}-${var.environment}-${var.service_name}"
    }
}

resource "aws_lb_listener_rule" "main" {
    listener_arn = data.aws_ssm_parameter.listerner_arn.value
    priority     = 585

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.main.arn
    }

    condition {
        host_header {
            values = [var.host_header]
        }
    }
}

#########################################################################
## Resource Creation 2.1: Route53 - This register the domain in Route53
#########################################################################
resource "aws_route53_record" "main" {
    zone_id = data.aws_route53_zone.public_hostzone.id
    name    = var.subdomain_name
    type    = "A"

    alias {
        name                   = data.aws_lb.alb_name.dns_name
        zone_id                = data.aws_lb.alb_name.zone_id
        evaluate_target_health = true
    }
}

output "hosted_zone_id" {
    value = data.aws_route53_zone.public_hostzone.zone_id
}

#########################################################################
## Resource Creation 3.1: Autoscaling - This manage fargate autoscaling
#########################################################################
resource "aws_appautoscaling_target" "main" {
    count              = var.deployment_mode == "FARGATE" && var.enable_auto_scaling ? 1 : 0
    max_capacity       = var.max_capacity
    min_capacity       = var.min_capacity
    resource_id        = "service/${data.aws_ssm_parameter.ecs_cluster_name.value}/${aws_ecs_service.main.name}"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
    count              = var.deployment_mode == "FARGATE" && var.enable_auto_scaling ? 1 : 0
    name               = "${var.service_name}-cpu-scale"
    policy_type        = "TargetTrackingScaling"
    resource_id        = aws_appautoscaling_target.main[0].resource_id
    scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
    service_namespace  = aws_appautoscaling_target.main[0].service_namespace

    target_tracking_scaling_policy_configuration {
        target_value       = 80
        scale_in_cooldown  = 180
        scale_out_cooldown = 180
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
    }
}

resource "aws_appautoscaling_policy" "memory" {
    count              = var.deployment_mode == "FARGATE" && var.enable_auto_scaling ? 1 : 0
    name               = "${var.service_name}-memory-scale"
    policy_type        = "TargetTrackingScaling"
    resource_id        = aws_appautoscaling_target.main[0].resource_id
    scalable_dimension = aws_appautoscaling_target.main[0].scalable_dimension
    service_namespace  = aws_appautoscaling_target.main[0].service_namespace

    target_tracking_scaling_policy_configuration {
        target_value       = 60
        scale_in_cooldown  = 180
        scale_out_cooldown = 180
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
    }
}
