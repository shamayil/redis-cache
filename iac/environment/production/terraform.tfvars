region              = "eu-west-2"
project             = "redis-cache"
environment         = "production"
service_name        = "service"
hostzone            = "iposg.com"
enable_auto_scaling = true
max_capacity        = 1
min_capacity        = 1
desired_count       = 1
deployment_mode     = "FARGATE" # FARGATE or EC2
host_header         = "redis-cache.iposg.com" # ALB Value
subdomain_name      = "redis-cache" # Route53 Value
database_secrets    = "iposg-database-secrets"
common_secrets      = "common-secret-keys"

# main configuration
cpu              = 256
memory           = 512
nginx_image_tag  = "redis-cache-production-service:nginx-31141"
phpapp_image_tag = "redis-cache-production-service:php-31141"

# worker configuration
worker_cpu    = 256
worker_memory = 512

worker_enable_auto_scaling = true
worker_max_capacity        = 1
worker_min_capacity        = 1
worker_desired_count       = 1
