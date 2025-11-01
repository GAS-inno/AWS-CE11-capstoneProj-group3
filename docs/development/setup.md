# Development Setup Guide

This guide helps you set up the Sky High Booker application for local development.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/GAS-inno/AWS-CE11-capstoneProj-group3.git
cd AWS-CE11-capstoneProj-group3

# Start development environment (automated)
./scripts/dev.sh
```

## 📋 Prerequisites

### **Required Software**
- **Node.js** (v18 or higher)
- **npm** (v9 or higher)  
- **Git**
- **Docker** (for containerization)
- **AWS CLI** (for deployment)

### **Installation Commands**

#### **Ubuntu/WSL:**
```bash
# Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Docker
sudo apt update
sudo apt install docker.io
sudo usermod -aG docker $USER

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### **macOS:**
```bash
# Using Homebrew
brew install node npm docker aws-cli
```

#### **Windows:**
- Download Node.js from [nodejs.org](https://nodejs.org/)
- Install Docker Desktop
- Install AWS CLI from [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## ⚙️ Environment Setup

### **1. Environment Variables**
Create a `.env` file in the project root:

```bash
# Copy example environment file
cp .env.example .env

# Edit with your values
vim .env
```

**Required variables:**
```bash
# Supabase Configuration
VITE_SUPABASE_URL=your-supabase-project-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key

# AWS Configuration (for deployment)
AWS_REGION=us-east-1
AWS_PROFILE=default

# Application Configuration
VITE_APP_NAME="Sky High Booker"
VITE_APP_VERSION="1.0.0"
```

### **2. AWS Configuration**
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_REGION=us-east-1
```

### **3. Supabase Setup**
1. Create account at [supabase.com](https://supabase.com/)
2. Create new project
3. Get project URL and anon key from Settings > API
4. Update `.env` file with your values

## 🛠️ Manual Development Setup

### **1. Install Dependencies**
```bash
# Install all packages
npm install

# Or use clean install
npm ci
```

### **2. Start Development Server**
```bash
# Start dev server with hot reload
npm run dev

# Start on specific port
npm run dev -- --port 5173
```

### **3. Build Application**
```bash
# Development build
npm run build

# Production build
npm run build:prod
```

### **4. Run Tests**
```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### **5. Code Quality**
```bash
# Type checking
npm run type-check

# Linting
npm run lint

# Format code
npm run format
```

## 🐳 Docker Development

### **Build and Run Locally**
```bash
# Build Docker image
docker build -t sky-high-booker .

# Run container
docker run -p 3000:80 sky-high-booker

# Run with environment variables
docker run -p 3000:80 -e VITE_SUPABASE_URL=your-url sky-high-booker
```

### **Docker Compose (Optional)**
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down
```

## 📁 Project Structure

```
sky-high-booker/
├── src/                    # React application source
│   ├── components/        # Reusable UI components
│   ├── pages/            # Page components
│   ├── contexts/         # React contexts
│   ├── hooks/            # Custom hooks
│   ├── lib/              # Utility functions
│   └── assets/           # Static assets
├── public/                # Public static files
├── scripts/               # Deployment and utility scripts
├── terraform/             # Infrastructure as Code
├── docs/                  # Documentation
└── [config files]        # Various configuration files
```

## 🔄 Development Workflow

### **1. Feature Development**
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test locally
npm run dev

# Run tests
npm test

# Commit changes
git add .
git commit -m "Add your feature description"

# Push and create PR
git push origin feature/your-feature-name
```

### **2. Code Quality Checks**
```bash
# Before committing, run quality checks
npm run type-check    # TypeScript validation
npm run lint          # ESLint checking  
npm run test          # Unit tests
npm run build         # Build validation
```

### **3. Local Testing**
```bash
# Test different scenarios
npm run dev           # Development mode
npm run build && npm run preview  # Production build test
docker build -t test . && docker run -p 3000:80 test  # Container test
```

## 🔧 IDE Configuration

### **VS Code (Recommended)**
Install these extensions:
- **ES7+ React/Redux/React-Native snippets**
- **TypeScript Importer**
- **Tailwind CSS IntelliSense**
- **ESLint**
- **Prettier**
- **Auto Rename Tag**
- **Bracket Pair Colorizer**

**Settings (`.vscode/settings.json`):**
```json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"]
  ]
}
```

### **WebStorm/IntelliJ**
- Enable TypeScript service
- Configure ESLint integration
- Set Prettier as code formatter
- Install Tailwind CSS plugin

## 🐛 Troubleshooting

### **Common Issues:**

**Node modules issues:**
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

**Port already in use:**
```bash
# Kill process on port 5173
lsof -ti:5173 | xargs kill -9

# Or use different port
npm run dev -- --port 3001
```

**TypeScript errors:**
```bash
# Restart TypeScript service
# In VS Code: Ctrl+Shift+P -> "TypeScript: Restart TS Server"

# Check TypeScript config
npx tsc --noEmit
```

**Supabase connection issues:**
```bash
# Verify environment variables
echo $VITE_SUPABASE_URL
echo $VITE_SUPABASE_ANON_KEY

# Test Supabase connection in browser console
```

**Docker build fails:**
```bash
# Clear Docker cache
docker system prune -a

# Build with verbose output
docker build --progress=plain -t sky-high-booker .
```

## 📚 Useful Resources

- [React Documentation](https://reactjs.org/docs/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Vite Guide](https://vitejs.dev/guide/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [shadcn/ui Components](https://ui.shadcn.com/)

## 🤝 Getting Help

- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas  
- **Documentation**: Check the [docs/](../) directory
- **Code Review**: Create pull requests for feedback