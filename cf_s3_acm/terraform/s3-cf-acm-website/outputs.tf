output "s3_bucket_name" {
  value = aws_s3_bucket.website.bucket
}

output "s3_website_endpoint" {
  value = aws_s3_bucket.website.website_endpoint
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "custom_domain_name" {
  value = var.domain_name
}
