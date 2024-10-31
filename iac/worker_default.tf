##############################################################
## Resource Creation 1.1: ECS - Log Group
##############################################################
resource "aws_cloudwatch_log_group" "worker_default" {
    name              = "${var.project}-${var.environment}-${var.service_name}-worker-default"
    retention_in_days = 1

    tags = {
        Name        = "${var.project}-${var.environment}-${var.service_name}"
        Environment = var.environment
    }
}

##############################################################
## Resource Creation 1.2: ECS - Task Definition
##############################################################
resource "aws_ecs_task_definition" "worker_default" {
    family                   = "${var.project}-${var.environment}-${var.service_name}-worker-default-td"
    execution_role_arn       = data.aws_ssm_parameter.ecs_taskexecution_role.value
    task_role_arn            = data.aws_ssm_parameter.ecs_taskexecution_role.value
    cpu                      = var.deployment_mode == "FARGATE" ? var.worker_cpu : null
    memory                   = var.deployment_mode == "FARGATE" ? var.worker_memory : 0
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
                    hostPort      = var.deployment_mode == "FARGATE" ? 9000 : 0
                }
            ]
            entrypoint  = ["./proxy/php/worker_default.sh"]
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
                    name  = "SQS_QUEUE_DEFAULT"
                    value = data.aws_ssm_parameter.default_sqs_queue.value
                },
                {
                    name  = "SQS_QUEUE"
                    value = data.aws_ssm_parameter.default_sqs_queue.value
                },
                {
                    name  = "QUEUE_URL_DEFAULT"
                    value = data.aws_ssm_parameter.default_sqs_full_url.value
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
                    awslogs-group         = aws_cloudwatch_log_group.worker_default.name
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
resource "aws_ecs_service" "worker_default" {
    name                   = "${var.project}-${var.environment}-${var.service_name}-worker-default-nginx"
    cluster                = data.aws_ssm_parameter.ecs_cluster_arn.value
    task_definition        = aws_ecs_task_definition.worker_default.arn
    desired_count          = var.worker_desired_count
    enable_execute_command = true
    launch_type            = var.deployment_mode
    wait_for_steady_state  = true

    deployment_circuit_breaker {
        enable   = true
        rollback = true
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

#########################################################################
## Resource Creation 3.1: Autoscaling - This manage fargate autoscaling
#########################################################################
resource "aws_appautoscaling_target" "worker_default" {
    count              = var.deployment_mode == "FARGATE" && var.worker_enable_auto_scaling ? 1 : 0
    max_capacity       = var.worker_max_capacity
    min_capacity       = var.worker_min_capacity
    resource_id        = "service/${data.aws_ssm_parameter.ecs_cluster_name.value}/${aws_ecs_service.main.name}"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "worker_default_cpu" {
    count              = var.deployment_mode == "FARGATE" && var.worker_enable_auto_scaling ? 1 : 0
    name               = "${var.service_name}-cpu-scale"
    policy_type        = "TargetTrackingScaling"
    resource_id        = aws_appautoscaling_target.worker_default[0].resource_id
    scalable_dimension = aws_appautoscaling_target.worker_default[0].scalable_dimension
    service_namespace  = aws_appautoscaling_target.worker_default[0].service_namespace

    target_tracking_scaling_policy_configuration {
        target_value       = 80
        scale_in_cooldown  = 180
        scale_out_cooldown = 180
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
    }
}

resource "aws_appautoscaling_policy" "worker_default_memory" {
    count              = var.deployment_mode == "FARGATE" && var.worker_enable_auto_scaling ? 1 : 0
    name               = "${var.service_name}-memory-scale"
    policy_type        = "TargetTrackingScaling"
    resource_id        = aws_appautoscaling_target.worker_default[0].resource_id
    scalable_dimension = aws_appautoscaling_target.worker_default[0].scalable_dimension
    service_namespace  = aws_appautoscaling_target.worker_default[0].service_namespace

    target_tracking_scaling_policy_configuration {
        target_value       = 60
        scale_in_cooldown  = 180
        scale_out_cooldown = 180
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
    }
}
