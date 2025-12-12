# S3 Static Website Hosting

## Summary

This React SPA project uses **S3 + CloudFront static website hosting** for optimal performance and cost efficiency.

## ✅ What Changed

### Infrastructure Files Created
1. **`terraform/s3.tf`** - S3 bucket for static website hosting
   - S3 bucket with versioning and encryption
   - CloudFront Origin Access Identity
   - Bucket policy for CloudFront access
   - CORS configuration
   - Website configuration for SPA routing

2. **`terraform/cloudfront.tf`** - CloudFront CDN distribution
   - Global CDN for fast content delivery
   - Custom domain support
   - SSL/TLS certificate (ACM in us-east-1)
   - Cache behaviors for HTML and assets
   - Custom error responses for SPA routing

3. **`scripts/deploy-s3.sh`** - New deployment script
   - Infrastructure deployment with Terraform
   - Application build with npm
   - S3 upload with proper cache headers
   - CloudFront cache invalidation
   - Deployment testing

4. **`terraform/S3_STATIC_HOSTING.md`** - Documentation
   - Architecture overview
   - Deployment instructions
   - Configuration guide
   - Troubleshooting tips

### Infrastructure Files Modified
1. **`terraform/provider.tf`** - Added us-east-1 provider alias
   - Required for CloudFront ACM certificates

2. **`terraform/variable.tf`** - Added domain_name variable
   - Configurable custom domain support

3. **`terraform/route53.tf`** - Updated DNS configuration
   - Points to CloudFront instead of ALB
   - Conditional Route53 records
   - ACM certificate validation (moved from here to cloudfront.tf)

4. **`terraform/output.tf`** - Updated outputs
   - S3 bucket information
   - CloudFront distribution details
   - Removed ECS/ECR outputs
   - Updated deployment commands

## 🚀 How to Deploy

### Automated (Recommended)
```bash
./scripts/deploy-s3.sh
```

### Manual
```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 2. Build and deploy application
cd ..
npm ci
npm run build

# 3. Get S3 bucket name and CloudFront distribution ID from Terraform outputs
S3_BUCKET=$(terraform output -raw s3_bucket_name)
CF_DIST_ID=$(terraform output -raw cloudfront_distribution_id)

# 4. Upload to S3
aws s3 sync ./dist "s3://$S3_BUCKET/" --delete

# 5. Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id "$CF_DIST_ID" --paths "/*"
```

## 💰 Cost Estimate

- **S3**: ~$0.50/month
- **CloudFront**: ~$1/month  
- **Route53**: ~$0.50/month
- **Total**: **~$2/month**

Highly cost-effective for static hosting! 🎉

## 📝 Configuration

### Environment Variables
Edit `terraform/variable.tf`:
```hcl
variable "domain_name" {
  default = "sky-high-booker.sctp-sandbox.com"  # Change to your domain
}
```

Environment variables are now bundled at **build time** (not runtime):
- `VITE_AWS_REGION`
- `VITE_AWS_API_GATEWAY_URL`
- `VITE_AWS_USER_POOL_ID`
- `VITE_AWS_USER_POOL_CLIENT_ID`
- `VITE_AWS_S3_BUCKET`

## 🌐 Access URLs

After deployment:
- **CloudFront**: `https://d1234567890.cloudfront.net`
- **Custom Domain**: `https://sky-high-booker.sctp-sandbox.com`
- **API Gateway**: (unchanged)

## ⚡ Performance Benefits

1. **Global CDN**: Content served from edge locations worldwide
2. **Better Caching**: Static assets cached for 1 year
3. **HTTPS**: Automatic SSL/TLS with CloudFront
4. **No Cold Starts**: No container startup delays
5. **Instant Scaling**: CloudFront handles any traffic volume

## 🔒 Security

- S3 bucket is private (not publicly accessible)
- CloudFront Origin Access Identity for secure access
- HTTPS enforced (HTTP redirects to HTTPS)
- TLS 1.2+ minimum protocol
- Server-side encryption enabled
- Versioning enabled for rollback

## 🎯 SPA Routing

CloudFront custom error responses handle React Router:
- 403/404 errors → serve `/index.html` (200 status)
- All routes work correctly with client-side routing

## 🔄 Cache Strategy

### CloudFront
- **HTML files**: No cache (always fresh)
- **Assets** (`/assets/*`): 1 year cache
- **Default**: 1 hour cache

### S3 Upload Headers
- **HTML**: `no-cache, no-store, must-revalidate`
- **Static assets**: `public, max-age=31536000, immutable`

## 🛠️ Troubleshooting

### Changes not visible?
1. Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"`
2. Wait 5-15 minutes for edge cache updates
3. Clear browser cache (Cmd+Shift+R)

### 403 Forbidden errors?
1. Check S3 bucket policy allows CloudFront OAI
2. Verify files were uploaded: `aws s3 ls s3://YOUR_BUCKET/`

### SSL certificate issues?
1. Certificate must be in us-east-1 (handled automatically)
2. DNS validation records must exist in Route53
3. Wait for validation to complete (~5 minutes)

## 📚 Documentation

See `terraform/S3_STATIC_HOSTING.md` for detailed documentation.

## ✨ Next Steps

1. **Test the deployment**: Visit your CloudFront/custom domain URL
2. **Monitor performance**: Check CloudFront metrics in AWS Console
3. **Set up CI/CD**: Automate deployment with GitHub Actions or similar
4. **Enable CloudFront logs**: For detailed access analytics (optional)
5. **Configure WAF**: Add Web Application Firewall for security (optional)

## 🎉 Benefits Summary

✅ **Cost-effective** (~$2/month)
✅ **Global performance** (CDN edge caching)
✅ **Simple architecture** (no servers to manage)
✅ **Instant scaling** (handles any traffic)
✅ **Always fast** (no cold starts)
✅ **Built-in HTTPS** (free SSL certificates)
✅ **High reliability** (99.99% SLA)

Your static React SPA is production-ready! 🚀
