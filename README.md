# Sky High Booker

🛫 **Modern Flight Booking Application** - A full-stack React application with AWS ECS deployment.

[![CI/CD Pipeline](https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3/actions/workflows/ci.yml/badge.svg)](https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3/actions/workflows/ci.yml)
[![Infrastructure](https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3/actions/workflows/terraform.yml/badge.svg)](https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3/actions/workflows/terraform.yml)
[![Deployment](https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3/actions/workflows/deploy.yml/badge.svg)](https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3/actions/workflows/deploy.yml)

## ✨ Features

- 🔍 **Flight Search** - Search for flights by destination, dates, and preferences
- 📅 **Date Selection** - Interactive calendar for departure and return dates
- 👥 **Passenger Management** - Add multiple passengers with details
- � **Seat Selection** - Choose your preferred seats with visual seat map
- 💳 **Secure Booking** - Complete booking process with payment integration
- 📱 **Responsive Design** - Optimized for desktop and mobile devices
- 🎨 **Modern UI** - Built with shadcn/ui components and Tailwind CSS
- 🔐 **Authentication** - User registration and login with AWS Cognito
- 📊 **Dashboard** - User dashboard to manage bookings and profile

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   React App     │────│   AWS ECS        │────│   AWS Cognito   │
│   (Frontend)    │    │   (Container)    │    │   (Auth)        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
          │                       │                       │
          │                       │                       │
    ┌─────▼─────┐          ┌──────▼──────┐         ┌──────▼──────┐
    │   Vite    │          │Application  │         │PostgreSQL + │
    │   Build   │          │Load Balancer│         │   Auth      │
    └───────────┘          └─────────────┘         └─────────────┘
```

## Quick Start

### **🚨 New Repository Setup**
For first-time setup or new developers:

```bash
git clone <repository-url>
cd AWS-CE11-capstoneProj-group3

# Automated setup (handles all dependencies)
./scripts/setup.sh
```

### **🔄 Existing Infrastructure**
If infrastructure already exists:

```bash
# Frontend development only
npm install
cp .env.example .env
# Edit .env with current AWS environment variables
npm run dev

# Or infrastructure changes
cd terraform
terraform apply
```

**⚠️ Important**: See `SETUP.md` for detailed dependency information.

## 📁 Project Structure

```
sky-high-booker/
├── 📁 src/                     # React application source
│   ├── 📁 components/         # Reusable UI components
│   │   ├── ui/               # shadcn/ui components
│   │   ├── booking/          # Booking-specific components
│   │   ├── flight/           # Flight search components
│   │   └── auth/             # Authentication components
│   ├── 📁 pages/             # Page components
│   ├── 📁 contexts/          # React contexts (auth, booking)
│   ├── 📁 hooks/             # Custom React hooks
│   ├── 📁 lib/               # Utility functions
│   └── 📁 assets/            # Static assets
├── 📁 scripts/               # Deployment and utility scripts
│   ├── deploy-ecs.sh         # ECS deployment automation
│   ├── deploy.sh             # General deployment script
│   ├── dev.sh               # Development environment setup
│   └── 📁 docker/           # Docker configuration files
├── 📁 terraform/             # Infrastructure as Code
│   ├── main.tf              # Core AWS resources (ECS, ALB, VPC)
│   ├── backend.tf           # Remote state configuration
│   ├── provider.tf          # AWS provider setup
│   ├── variable.tf          # Input variables
│   └── output.tf            # Resource outputs
├── 📁 docs/                  # Documentation
│   ├── 📁 deployment/       # Deployment guides
│   ├── 📁 infrastructure/   # Architecture documentation
│   └── 📁 development/     # Development setup guides
├── 📁 .github/workflows/     # GitHub Actions CI/CD
│   ├── ci.yml               # Continuous Integration
│   ├── deploy.yml           # Automated deployment
│   ├── deploy-multi-env.yml # Multi-environment deployment
│   └── terraform.yml        # Infrastructure management
└── 📄 [config files]        # Various configuration files
```

## 🛠️ Technology Stack

### **Frontend**
- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **shadcn/ui** for UI components
- **Lucide React** for icons
- **React Router** for navigation
- **React Hook Form** for form management

### **Backend & Database**
- **AWS Lambda** (Node.js) for serverless API functions
- **Amazon DynamoDB** for NoSQL database
- **AWS Cognito** for user authentication
- **API Gateway** for REST API management

### **Infrastructure**
- **AWS ECS Fargate** for container orchestration
- **Application Load Balancer** for traffic distribution
- **Amazon ECR** for container registry
- **VPC** with public/private subnets
- **Auto Scaling** for high availability

### **DevOps**
- **Terraform** for Infrastructure as Code
- **GitHub Actions** for CI/CD
- **Docker** for containerization
- **AWS CLI** for deployment automation

## 🚢 Deployment

### **Automated Deployment (Recommended)**
```bash
# Push to main branch triggers automatic deployment
git push origin main

# Or manually trigger via GitHub Actions
# Go to Actions → "Complete CI/CD Pipeline" → "Run workflow"
```

### **Manual Deployment**
```bash
# Deploy infrastructure
cd terraform/
terraform init
terraform apply

# Deploy application
./scripts/deploy-ecs.sh
```

### **Multi-Environment Support**
- **Staging**: Triggered on `develop` branch
- **Production**: Triggered on `main` branch or manual approval
- **Feature branches**: CI testing only

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](./docs/) directory:

- 📖 **[Development Setup](./docs/development/setup.md)** - Complete development environment setup
- 🏗️ **[Infrastructure Architecture](./docs/infrastructure/architecture.md)** - AWS infrastructure deep dive
- 🚀 **[Deployment Guide](./docs/deployment/guide.md)** - Comprehensive deployment instructions
- 🔧 **[Scripts Documentation](./scripts/README.md)** - Deployment and utility scripts guide

### **Quick Links**
- [Getting Started](./docs/development/setup.md#-quick-start)
- [Environment Variables](./docs/development/setup.md#-environment-setup)
- [Deployment Process](./docs/deployment/guide.md#-automated-deployment-github-actions)
- [Troubleshooting](./docs/deployment/guide.md#-troubleshooting)
- [Architecture Overview](./docs/infrastructure/architecture.md#-architecture-overview)

## 🔧 Development

### **Available Scripts**
```bash
# Development
npm run dev              # Start development server
npm run build           # Build for production
npm run preview         # Preview production build locally

# Code Quality
npm run lint            # ESLint checking
npm run type-check      # TypeScript validation
npm test               # Run tests
npm run format         # Format with Prettier

# Docker
docker build -t sky-high-booker .
docker run -p 3000:80 sky-high-booker

# Deployment
./scripts/dev.sh        # Quick development setup
./scripts/deploy.sh     # Full deployment
./scripts/deploy-ecs.sh # ECS-specific deployment
```

### **Key Development Commands**
```bash
# Setup new development environment
./scripts/dev.sh

# Run development server with hot reload
npm run dev

# Build and test locally
npm run build && npm run preview

# Type checking and linting
npm run type-check && npm run lint
```

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# E2E tests (if configured)
npm run test:e2e
```

## 🔒 Security

- **Authentication**: AWS Cognito with email/password
- **Authorization**: IAM policies and Cognito user pools
- **Data Protection**: HTTPS everywhere, secure headers
- **Container Security**: Non-root user, minimal base image
- **Infrastructure**: Private subnets, security groups, IAM roles
- **Secrets Management**: GitHub Secrets, AWS Parameter Store

## 📊 Monitoring

- **Application Monitoring**: ECS CloudWatch logs and metrics
- **Infrastructure Monitoring**: ALB, ECS, and auto-scaling metrics
- **Error Tracking**: CloudWatch error logs and alarms
- **Performance**: Response time and resource utilization tracking

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** and test locally
4. **Run quality checks**: `npm run lint && npm run type-check && npm test`
5. **Commit changes**: `git commit -m 'Add amazing feature'`
6. **Push to branch**: `git push origin feature/amazing-feature`
7. **Create Pull Request** with detailed description

### **Development Workflow**
- Follow TypeScript strict mode
- Use conventional commit messages
- Add tests for new features
- Update documentation as needed
- Ensure CI passes before merging

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Development Team**: CE11 Group 3
- **Infrastructure**: AWS ECS Fargate with Terraform
- **Frontend**: React + TypeScript + Tailwind CSS
- **Backend**: AWS Lambda + DynamoDB + Cognito

## 🔗 Links

- **Live Application**: [Deployed via AWS ECS]
- **Documentation**: [`docs/`](./docs/) directory
- **GitHub Actions**: [Workflows](./.github/workflows/)
- **Infrastructure**: [`terraform/`](./terraform/) directory
- **Deployment Scripts**: [`scripts/`](./scripts/) directory

## 📞 Support

For questions, issues, or contributions:

1. **Check Documentation**: Review the [`docs/`](./docs/) directory
2. **GitHub Issues**: Create an issue for bugs or feature requests
3. **GitHub Discussions**: Ask questions and share ideas
4. **Pull Requests**: Contribute improvements and fixes

---

**Sky High Booker** - Elevating your flight booking experience! ✈️

*Built with ❤️ by CE11 Group 3*

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript checks

## Deployment

### Frontend Deployment
The application can be deployed to various platforms:
- **AWS S3 + CloudFront** (recommended)
- **Vercel**
- **Netlify**

### Infrastructure Deployment
Use Terraform to deploy the AWS infrastructure:
```bash
cd terraform
terraform init
terraform apply
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please open an issue in the GitHub repository.

---

Built with ❤️ by the CE11 Group 3 Team