# 🛫 Sky High Booker - Flight Booking System

A modern, cloud-native flight booking application built with React, AWS serverless architecture, and Infrastructure as Code.

![Architecture](https://img.shields.io/badge/Architecture-Serverless-orange)
![AWS](https://img.shields.io/badge/AWS-Multi--Service-yellow)
![React](https://img.shields.io/badge/Frontend-React-blue)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)

## 🌟 Features

- **✈️ Flight Search & Booking** - Browse and book flights with seat selection
- **👤 User Authentication** - Secure login with AWS Cognito
- **💺 Seat Management** - Interactive seat map with real-time availability
- **📱 Responsive Design** - Mobile-friendly interface
- **🔒 Secure Payment** - Mock payment processing (demo purposes)
- **📊 Booking Management** - View and manage your bookings
- **🌐 Custom Domain** - Professional HTTPS domain with SSL
- **📈 Auto-Scaling** - Handles traffic spikes automatically

## 🏗️ Architecture

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **AWS Amplify Auth** for authentication

### Backend (Serverless)
- **API Gateway** for REST APIs
- **Lambda Functions** for business logic
- **DynamoDB** for data storage
- **Cognito** for user management
- **S3** for static assets

### Infrastructure
- **ECS Fargate** for containerized frontend
- **Application Load Balancer** with SSL
- **Route 53** for custom domains
- **VPC** with public subnets
- **CloudWatch** for monitoring

### DevOps
- **Terraform** for Infrastructure as Code
- **Docker** for containerization
- **ECR** for container registry
- **Automated deployment scripts**

## 🚀 Quick Start (New Repository)

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed and running
- Terraform installed

### 1. Setup New Repository
```bash
# Clone your new repository
git clone https://github.com/YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO

# Copy Sky High Booker files
cp -r /path/to/sky-high-booker/* ./

# Run setup script to customize for your project
./scripts/new-repo-setup.sh
```

### 2. Configure AWS
```bash
aws configure
# Enter your AWS credentials and set region to us-east-1
```

### 3. Deploy Everything
```bash
# Single command deployment
./scripts/deploy.sh
```

That's it! The script will:
- ✅ Deploy all AWS infrastructure
- ✅ Build and push Docker container
- ✅ Deploy application to ECS
- ✅ Set up custom domain with SSL
- ✅ Provide access URLs

## 🌐 Access Your Application

After deployment, access at:
- **Custom Domain**: `https://your-app.sctp-sandbox.com` (if configured)
- **Load Balancer**: `http://[alb-dns-name]` (redirects to HTTPS)

## 🛠️ Development

### Local Development
```bash
cd static-website
npm install
npm run dev
# Open http://localhost:5173
```

### Environment Variables
The application uses runtime environment injection:
- `VITE_AWS_API_GATEWAY_URL` - API Gateway endpoint
- `VITE_AWS_USER_POOL_ID` - Cognito User Pool ID
- `VITE_AWS_USER_POOL_CLIENT_ID` - Cognito Client ID
- `VITE_AWS_S3_BUCKET` - S3 bucket name
- `VITE_AWS_REGION` - AWS region

### API Endpoints
- `GET /bookings` - List all bookings
- `POST /bookings` - Create new booking
- `GET /bookings/{id}` - Get booking details
- `GET /occupied-seats` - Get occupied seats for flight

## 📁 Project Structure

```
sky-high-booker/
├── static-website/          # React frontend application
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API services
│   │   └── types/          # TypeScript definitions
│   ├── public/             # Static assets
│   └── package.json
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main Terraform configuration
│   ├── vpc.tf             # Network resources
│   ├── ecs_simplified.tf  # Container orchestration
│   ├── dynamodb.tf        # Database configuration
│   ├── lambda/            # Lambda function code
│   └── route53.tf         # DNS and SSL configuration
├── scripts/               # Deployment and utility scripts
│   ├── deploy.sh          # Complete deployment script
│   ├── destroy.sh         # Infrastructure cleanup
│   └── new-repo-setup.sh  # New repository configuration
├── Dockerfile             # Container configuration
└── DEPLOYMENT.md          # Detailed deployment guide
```

## 🧹 Cleanup

To remove all infrastructure:
```bash
./scripts/destroy.sh
```
⚠️ This will destroy ALL resources including data!

## 🔧 Customization

### Changing the Name Prefix
Update `terraform/variable.tf`:
```hcl
variable "name_prefix" {
  default = "your-prefix-"
}
```

### Adding Custom Domain
1. Create Route 53 hosted zone for your domain
2. Update `terraform/route53.tf` with your domain name
3. Run `terraform apply`

### Scaling Configuration
Update in `terraform/variable.tf`:
```hcl
variable "ecs_desired_count" {
  default = 3  # Number of containers
}

variable "ecs_task_cpu" {
  default = 512  # CPU units
}
```

## 📊 Monitoring

### CloudWatch Logs
- ECS tasks: `/aws/ecs/sky-high-booker/`
- Lambda functions: `/aws/lambda/sky-high-booker-*`
- API Gateway: Available in API Gateway console

### Metrics
- ECS service metrics in CloudWatch
- Lambda function performance
- API Gateway request metrics
- Application Load Balancer health checks

## 🚨 Troubleshooting

### Common Issues

1. **Deployment fails at Docker build**
   - Ensure Docker is running
   - Check available disk space

2. **ECS tasks fail to start**
   - Check CloudWatch logs for container errors
   - Verify environment variables are set correctly

3. **API calls fail**
   - Check API Gateway configuration
   - Verify Lambda function permissions

4. **Domain not accessible**
   - DNS propagation can take up to 5 minutes
   - Check Route 53 hosted zone configuration

### Getting Help
- Check CloudWatch logs for detailed error messages
- Review Terraform plan output
- Verify AWS service limits and quotas

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🙏 Acknowledgments

- Built for SCTP Cloud Engineering Capstone Project
- AWS serverless architecture best practices
- React and modern frontend development patterns

---

**Ready to deploy your flight booking system? Run `./scripts/deploy.sh` and take off! ✈️**