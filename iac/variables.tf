variable "region" {
    type        = string
    description = "ap-southeast-1 | eu-west-2"
}

variable "project" {
    type        = string
    description = "Project name | srp"
}

variable "environment" {
    type        = string
    description = "Environment name | staging / production"
}

variable "service_name" {
    type = string
}

variable "hostzone" {
    type = string
}

# Task definition
variable "nginx_image_tag" {
    type = string
}

variable "phpapp_image_tag" {
    type = string
}

variable "cpu" {
    type = number
}

variable "worker_cpu" {
    type = number
}

variable "memory" {
    type = number
}

variable "worker_memory" {
    type = number
}

variable "desired_count" {
    type = number
}

variable "worker_desired_count" {
    type = number
}

variable "deployment_mode" {
    type = string
    validation {
        condition     = contains(["FARGATE", "EC2"], var.deployment_mode)
        error_message = "Allowed values are FARGATE or EC2"
    }
}

variable "max_capacity" {
    type = number
}

variable "worker_max_capacity" {
    type = number
}

variable "min_capacity" {
    type = number
}

variable "worker_min_capacity" {
    type = number
}

variable "enable_auto_scaling" {
    type = bool
}

variable "worker_enable_auto_scaling" {
    type = bool
}

variable "database_secrets" {
    type    = string
    default = null
}

variable "common_secrets" {
    type    = string
    default = null
}

# Target group
variable "host_header" {
    type = string
}

variable "subdomain_name" {
    type = string
}
