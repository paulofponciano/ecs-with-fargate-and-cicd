variable "tags" {
  description = "AWS Tags to add to all resources created."
  type        = map(string)
}

variable "aws_region" {
  description = "AWS Region (e.g. us-east-1, us-west-2, sa-east-1, us-east-2)"
  type        = string
}

variable "azs" {
  description = "AWS Availability Zones"
  type        = list(string)
}

variable "site_domain" {
  description = "The primary domain name of the website."
  type        = string
}

variable "env_prefix" {
  description = "Environment prefix for all resources to be created."
  type        = string
}

variable "environment" {
  description = "Name of the application environment."
  type        = string
}

variable "log_retention_in_days" {
  description = "The number of days to retain CloudWatch logs."
  type        = number
}

variable "vpc_cidr" {
  description = "The VPC CIDR block."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}

variable "task_memory" {
  description = "The amount (in MiB) of memory used by the task."
  type        = number
}

variable "task_cpu" {
  description = "The number of CPU units used by the task."
  type        = number
}

variable "desired_count" {
  description = "The number of instances of Fargate tasks to keep running."
  type        = number
}

variable "scaling_out_cooldown" {
  description = "Cooldown time after upscaling."
  type        = number
}

variable "scaling_in_cooldown" {
  description = "Cooldown time after downscaling."
  type        = number
}

variable "scaling_out_adjustment" {
  description = "Number of tasks to scale up."
  type        = number
}

variable "scaling_in_adjustment" {
  description = "Number of tasks to scale down."
  type        = number
}

variable "task_cpu_low_threshold" {
  description = "CPU threshold for downscaling."
  type        = number
}

variable "task_cpu_high_threshold" {
  description = "CPU threshold for upscaling."
  type        = number
}

variable "max_task" {
  description = "Maximum number of tasks."
  type        = number
}

variable "min_task" {
  description = "Minimum number of tasks."
  type        = number
}

variable "github_repo" {
  description = "GitHub repo (some-user/my-repo)."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch."
  type        = string
}

