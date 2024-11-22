output "s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = try(module.s3_bucket.this[0].arn, "")
}

output "route53_record_fqdn" {
  value       = aws_route53_record.app.fqdn
  description = "Route53 record."
}
