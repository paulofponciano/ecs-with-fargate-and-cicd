module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = ">= 5.0"
  name                       = "${var.env_prefix}-${var.environment}"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = false
  tags                       = var.tags
}


module "acm" {
  source            = "terraform-aws-modules/acm/aws"
  version           = ">= v2.0"
  domain_name       = var.site_domain
  zone_id           = data.aws_route53_zone.this.zone_id
  validation_method = "DNS"
  tags              = var.tags
}

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "${var.env_prefix}-${var.environment}"
  cidr                   = var.vpc_cidr
  azs                    = var.azs
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  tags                   = var.tags
  version                = ">=2.0"
  enable_dns_hostnames   = true
}

# module "s3_bucket" {
#   source        = "terraform-aws-modules/s3-bucket/aws"
#   version       = "3.10.1"
#   create_bucket = true

#   bucket = var.bucket_name

#   versioning = {
#     enabled = false
#   }
# }
