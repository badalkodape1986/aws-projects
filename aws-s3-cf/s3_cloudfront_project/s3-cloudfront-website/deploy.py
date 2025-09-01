#!/usr/bin/env python3
import boto3, json, sys

bucket = input("Enter S3 bucket name: ")
domain = input("Enter domain name: ")
cert_arn = input("Enter ACM Certificate ARN (must be validated in us-east-1): ")

cf = boto3.client('cloudfront')

print("🚀 Creating CloudFront distribution...")
response = cf.create_distribution(
    DistributionConfig={
        'CallerReference': domain,
        'Comment': f"Static website for {domain}",
        'Enabled': True,
        'Origins': {
            'Quantity': 1,
            'Items': [{
                'Id': bucket,
                'DomainName': f"{bucket}.s3.amazonaws.com",
                'S3OriginConfig': {'OriginAccessIdentity': ''}
            }]
        },
        'DefaultCacheBehavior': {
            'TargetOriginId': bucket,
            'ViewerProtocolPolicy': 'redirect-to-https',
            'AllowedMethods': {'Quantity': 2, 'Items': ['GET', 'HEAD']},
            'CachedMethods': {'Quantity': 2, 'Items': ['GET', 'HEAD']},
            'ForwardedValues': {'QueryString': False, 'Cookies': {'Forward': 'none'}},
            'MinTTL': 0
        },
        'ViewerCertificate': {
            'ACMCertificateArn': cert_arn,
            'SSLSupportMethod': 'sni-only',
            'MinimumProtocolVersion': 'TLSv1.2_2019',
        },
        'Aliases': {'Quantity': 1, 'Items': [domain]},
        'DefaultRootObject': 'index.html'
    }
)

print("✅ CloudFront Distribution Created!")
print("Distribution Domain:", response['Distribution']['DomainName'])
