output "s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3_bucket.s3_bucket_arn
}

output "route53_record_fqdn" {
  value       = aws_route53_record.app.fqdn
  description = "Route53 record."
}
