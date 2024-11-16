tags = {
  Terraform = "true"
  Owner     = "DevOps Team"
  Env       = "staging"
}

aws_region  = "us-east-2"
azs         = ["us-east-2a", "us-east-2b"]
env_prefix  = "myproject"
environment = "staging"
site_domain = "myapp.sevira.cloud"

log_retention_in_days = 7

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.32.0/20", "10.1.48.0/20"]
private_subnet_cidrs = ["10.1.64.0/20", "10.1.80.0/20"]

desired_count           = 2
task_memory             = 4096
task_cpu                = 2048
task_cpu_low_threshold  = 25
task_cpu_high_threshold = 80
max_task                = 5
min_task                = 2
scaling_out_cooldown    = 120
scaling_in_cooldown     = 600
scaling_out_adjustment  = 2
scaling_in_adjustment   = -2

github_repo   = "paulofponciano/webapp-color"
github_branch = "master"
