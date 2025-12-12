# Quick Reference Guide - S3 Static Website Deployment

## 🚀 Quick Deploy
```bash
./scripts/deploy-s3.sh
```

## 📁 New Files Created
```
terraform/
├── s3.tf                    # S3 bucket configuration
├── cloudfront.tf            # CloudFront CDN
└── S3_STATIC_HOSTING.md     # Detailed documentation

scripts/
└── deploy-s3.sh             # S3 deployment script

MIGRATION_TO_S3.md           # Architecture guide
```

## 🔧 Modified Files
- `terraform/provider.tf` - Added us-east-1 provider
- `terraform/variable.tf` - Added domain_name variable
- `terraform/route53.tf` - Points to CloudFront
- `terraform/output.tf` - S3/CloudFront outputs

## 💡 Key Changes

### Architecture
- Build → S3 → CloudFront → Route53

### Deployment
- `npm build && upload to S3 && invalidate CloudFront`

### Environment Variables
- Build-time bundling via .env.production

## 📊 Infrastructure Overview

| Aspect | Details |
|--------|--------|
| Cost | ~$2/month |
| Complexity | Low |
| Scaling | Instant/Unlimited |
| Cold Start | No |
| CDN | Built-in |
| SSL | CloudFront certificate |

## 🌐 Access Points

### Production URLs
```bash
# Get URLs from Terraform
cd terraform
terraform output application_url        # Primary URL
terraform output cloudfront_url         # CloudFront URL
terraform output app_domain_url         # Custom domain (if configured)
```

### API Endpoints (Unchanged)
```bash
terraform output api_gateway_url        # API Gateway
terraform output cognito_user_pool_id   # Cognito User Pool
```

## ⚡ Common Commands

### Deploy Everything
```bash
./scripts/deploy-s3.sh
```

### Deploy Infrastructure Only
```bash
cd terraform
terraform apply
```

### Deploy Application Only
```bash
# Build
npm run build

# Upload
S3_BUCKET=$(cd terraform && terraform output -raw s3_bucket_name)
aws s3 sync ./dist "s3://$S3_BUCKET/" --delete

# Invalidate cache
CF_DIST_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id "$CF_DIST_ID" --paths "/*"
```

### View Infrastructure
```bash
cd terraform
terraform show
terraform output
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy
```

## 🐛 Quick Fixes

### Site not updating?
```bash
# Invalidate CloudFront cache
CF_DIST_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id "$CF_DIST_ID" --paths "/*"
```

### API calls failing?
```bash
# Check CORS configuration
cd terraform
terraform output api_gateway_url

# Verify environment variables in build
grep VITE_ .env.production
```

### Domain not working?
```bash
# Check DNS records
cd terraform
terraform show | grep route53_record

# Verify certificate validation
terraform show | grep acm_certificate
```

## 📈 Monitoring

### CloudWatch Metrics
```bash
# CloudFront requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=$(cd terraform && terraform output -raw cloudfront_distribution_id) \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum

# S3 bucket size
aws s3 ls s3://$(cd terraform && terraform output -raw s3_bucket_name) --recursive --summarize
```

### Logs
```bash
# API Gateway logs (CloudWatch)
# Lambda logs (CloudWatch)
# CloudFront access logs (optional, configure in cloudfront.tf)
```

## 🔐 Security Checklist

- [x] S3 bucket not publicly accessible
- [x] CloudFront OAI configured
- [x] HTTPS enforced
- [x] TLS 1.2+ minimum
- [x] Server-side encryption enabled
- [x] Versioning enabled
- [x] CORS properly configured
- [ ] CloudFront WAF (optional)
- [ ] CloudFront logging (optional)

## 🎯 Performance Tips

1. **Cache Optimization**
   - HTML: No cache (always fresh)
   - Assets: 1 year cache (immutable)
   - API calls: Not cached by CloudFront

2. **Build Optimization**
   ```bash
   # Check bundle size
   npm run build
   ls -lh dist/assets/
   
   # Analyze bundle
   npm install -D rollup-plugin-visualizer
   ```

3. **CloudFront Optimization**
   - Use PriceClass_100 (NA + EU) for lower cost
   - Use PriceClass_All for global performance
   - Configure in `terraform/cloudfront.tf`

## 📚 Additional Resources

- [Detailed Documentation](terraform/S3_STATIC_HOSTING.md)
- [Migration Guide](MIGRATION_TO_S3.md)
- [AWS S3 Static Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices.html)

## 🆘 Support

If you encounter issues:
1. Check the detailed documentation
2. Review Terraform outputs
3. Check AWS Console (S3, CloudFront, Route53)
4. Review CloudWatch logs
5. Test API Gateway endpoints separately

---

**Ready to deploy?** Run: `./scripts/deploy-s3.sh` 🚀
