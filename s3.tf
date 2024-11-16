resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket                  = module.s3_bucket.s3_bucket_id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_vpc_endpoint" "s3_gw_endpoint" {
  vpc_id          = module.vpc.vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = module.vpc.private_route_table_ids

  tags = var.tags
}

