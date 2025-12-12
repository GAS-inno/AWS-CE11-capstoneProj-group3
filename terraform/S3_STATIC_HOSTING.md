# Sky High Booker - S3 Static Website Infrastructure

This project uses **S3 + CloudFront** static website hosting for the React SPA.

## Architecture

- Static files hosted on S3
- CloudFront CDN for global distribution
- Route53 for custom domain
- ACM certificate for HTTPS
- Simple, cost-effective architecture

## Infrastructure Components

### Core Services
- **S3**: Static website hosting with versioning
- **CloudFront**: Global CDN with edge caching
- **Route53**: DNS management and custom domain
- **ACM**: SSL/TLS certificate (in us-east-1)
- **API Gateway**: Backend API endpoints
- **Lambda**: Serverless booking functions
- **DynamoDB**: NoSQL database for bookings
- **Cognito**: User authentication

## Deployment

### Automated Deployment
```bash
./scripts/deploy-s3.sh
```

This script will:
1. Deploy infrastructure via Terraform
2. Build the React application
3. Upload to S3 with proper cache headers
4. Invalidate CloudFront cache
5. Test the deployment

### Manual Deployment

#### 1. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### 2. Build Application
```bash
npm ci
npm run build
```

#### 3. Upload to S3
```bash
# HTML files (no cache)
aws s3 sync ./dist s3://YOUR_BUCKET/ \
  --exclude "*" --include "*.html" \
  --cache-control "no-cache, no-store, must-revalidate" \
  --delete

# Static assets (long-term cache)
aws s3 sync ./dist s3://YOUR_BUCKET/ \
  --exclude "*.html" \
  --cache-control "public, max-age=31536000, immutable" \
  --delete
```

#### 4. Invalidate CloudFront
```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

## Configuration

### Environment Variables
Environment variables are bundled at build time (not runtime):
- `VITE_AWS_REGION`
- `VITE_AWS_API_GATEWAY_URL`
- `VITE_AWS_USER_POOL_ID`
- `VITE_AWS_USER_POOL_CLIENT_ID`
- `VITE_AWS_S3_BUCKET`

### Custom Domain
Edit `terraform/variable.tf`:
```hcl
variable "domain_name" {
  default = "sky-high-booker.sctp-sandbox.com"
}
```

## Cost Estimate

### S3/CloudFront
- S3: ~$0.50/month (50GB storage, 1M requests)
- CloudFront: ~$1/month (10GB transfer)
- Route53: ~$0.50/month
- **Total: ~$2/month**

## Cache Strategy

### CloudFront Caching
- **HTML files**: No cache (always fresh)
- **Assets** (`/assets/*`): 1 year cache
- **Default**: 1 hour cache

### S3 Cache Headers
- **HTML**: `no-cache, no-store, must-revalidate`
- **Static assets**: `public, max-age=31536000, immutable`

## SPA Routing

CloudFront custom error responses handle client-side routing:
- 403 errors → serve `/index.html` (200)
- 404 errors → serve `/index.html` (200)

This ensures React Router works correctly.

## URLs

After deployment, you'll get:
- **CloudFront**: `https://d1234567890.cloudfront.net`
- **Custom Domain**: `https://sky-high-booker.sctp-sandbox.com`
- **API Gateway**: `https://abcdef1234.execute-api.us-east-1.amazonaws.com/prod`

## Monitoring

### CloudWatch Metrics
- CloudFront requests
- S3 bucket metrics
- Lambda invocations
- API Gateway requests

### Logs
- CloudFront access logs (optional)
- API Gateway logs
- Lambda function logs

## Troubleshooting

### Changes not visible
1. Check CloudFront invalidation status
2. Wait 5-15 minutes for edge cache updates
3. Clear browser cache (Cmd+Shift+R)

### 403 Forbidden errors
1. Check S3 bucket policy
2. Verify CloudFront OAI permissions
3. Ensure files were uploaded correctly

### SSL certificate issues
1. Certificate must be in us-east-1 for CloudFront
2. DNS validation records must be created
3. Wait for validation to complete

## Security

### S3 Bucket
- Not publicly accessible
- CloudFront OAI (Origin Access Identity) only
- Server-side encryption enabled
- Versioning enabled

### CloudFront
- HTTPS only (HTTP redirects to HTTPS)
- TLS 1.2+ minimum
- Custom domain with ACM certificate
- Origin access identity

### API Access
- CORS configured for API Gateway
- Cognito authentication required
- IAM roles for authenticated users

## Development

### Local Development
```bash
npm run dev
```

### Production Build
```bash
npm run build
```

### Preview Build
```bash
npm run preview
```

