# AWS Services Setup Guide

This document explains how to replace Supabase with AWS services for the Sky High Booker application.

## 🏗️ **Architecture Overview**

### **Service Replacements:**
- **Supabase Database** → **Amazon RDS (PostgreSQL)**
- **Supabase Auth** → **Amazon Cognito**
- **Supabase Storage** → **Amazon S3**
- **Supabase API** → **API Gateway + Lambda**

### **Infrastructure Components:**
- **ECS Fargate**: Container orchestration for the React frontend
- **Application Load Balancer**: Traffic distribution and SSL termination
- **CloudFront**: CDN for static assets and caching
- **ECR**: Container image registry
- **VPC**: Secure network isolation

## 🚀 **Deployment Steps**

### **1. Install Dependencies**

```bash
# Install AWS SDK dependencies
npm install aws-amplify @aws-amplify/core @aws-amplify/auth @aws-amplify/adapter-nextjs

# Remove Supabase dependencies (already done)
npm uninstall @supabase/supabase-js
```

### **2. Deploy Infrastructure**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Important Variables to Update:**
```hcl
# In terraform.tfvars (create this file)
project_name = "sky-high-booker"
db_password = "YourSecurePassword123!"  # Use a secure password
```

### **3. Get AWS Resource IDs**

After Terraform deployment, get the outputs:

```bash
terraform output aws_environment_variables
```

This will show:
```bash
{
  "VITE_AWS_API_GATEWAY_URL" = "https://abc123.execute-api.us-east-1.amazonaws.com/prod"
  "VITE_AWS_REGION" = "us-east-1"
  "VITE_AWS_S3_BUCKET" = "sky-high-booker-storage-bucket"
  "VITE_AWS_USER_POOL_CLIENT_ID" = "1a2b3c4d5e6f7g8h9i0j1k2l"
  "VITE_AWS_USER_POOL_ID" = "us-east-1_abcdef123"
}
```

### **4. Configure Environment Variables**

Create `.env` file with the Terraform outputs:

```bash
# Copy from .env.example and update with real values
cp .env.example .env

# Update .env with Terraform output values
VITE_AWS_REGION=us-east-1
VITE_AWS_USER_POOL_ID=us-east-1_abcdef123
VITE_AWS_USER_POOL_CLIENT_ID=1a2b3c4d5e6f7g8h9i0j1k2l
VITE_AWS_API_GATEWAY_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod
VITE_AWS_S3_BUCKET=sky-high-booker-storage-bucket
```

### **5. Set Up Database Schema**

The RDS PostgreSQL instance needs the database schema. Connect using the credentials from Secrets Manager:

```sql
-- Connect to PostgreSQL and create tables
CREATE TABLE flights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_location VARCHAR(100) NOT NULL,
    to_location VARCHAR(100) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    airline VARCHAR(100) NOT NULL,
    flight_number VARCHAR(20) NOT NULL,
    duration VARCHAR(20) NOT NULL,
    aircraft VARCHAR(100) NOT NULL,
    available_seats INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,  -- Cognito User ID
    flight_id UUID REFERENCES flights(id),
    passenger_name VARCHAR(255) NOT NULL,
    passenger_email VARCHAR(255) NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    booking_status VARCHAR(20) DEFAULT 'confirmed',
    total_amount DECIMAL(10,2) NOT NULL,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample flight data
INSERT INTO flights (from_location, to_location, departure_time, arrival_time, price, airline, flight_number, duration, aircraft, available_seats) VALUES
('New York (JFK)', 'Los Angeles (LAX)', '2024-12-15 08:00:00', '2024-12-15 11:30:00', 299.99, 'American Airlines', 'AA123', '5h 30m', 'Boeing 737', 150),
('Los Angeles (LAX)', 'New York (JFK)', '2024-12-15 14:00:00', '2024-12-15 22:00:00', 319.99, 'Delta Airlines', 'DL456', '5h 0m', 'Airbus A320', 180),
('Chicago (ORD)', 'Miami (MIA)', '2024-12-16 09:15:00', '2024-12-16 12:45:00', 189.99, 'United Airlines', 'UA789', '3h 30m', 'Boeing 757', 120);
```

### **6. Deploy Lambda Functions**

The API Gateway needs Lambda functions to handle requests. Create these in the `lambda_functions/` directory:

**flights_api.py:**
```python
import json
import psycopg2
import boto3
import os
from datetime import datetime

def handler(event, context):
    # Get database credentials from Secrets Manager
    secrets_client = boto3.client('secretsmanager')
    secret_arn = os.environ['DB_SECRET_ARN']
    
    try:
        secret_response = secrets_client.get_secret_value(SecretId=secret_arn)
        db_config = json.loads(secret_response['SecretString'])
        
        # Connect to PostgreSQL
        conn = psycopg2.connect(
            host=db_config['host'],
            database=db_config['dbname'],
            user=db_config['username'],
            password=db_config['password'],
            port=db_config['port']
        )
        
        # Handle different HTTP methods
        if event['httpMethod'] == 'GET':
            return get_flights(conn, event.get('queryStringParameters', {}))
        
        return {
            'statusCode': 405,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'Method not allowed'})
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if 'conn' in locals():
            conn.close()

def get_flights(conn, params):
    cursor = conn.cursor()
    
    # Build query based on parameters
    query = "SELECT * FROM flights WHERE 1=1"
    query_params = []
    
    if params.get('from'):
        query += " AND from_location ILIKE %s"
        query_params.append(f"%{params['from']}%")
    
    if params.get('to'):
        query += " AND to_location ILIKE %s"
        query_params.append(f"%{params['to']}%")
    
    cursor.execute(query, query_params)
    flights = cursor.fetchall()
    
    # Convert to JSON format
    columns = [desc[0] for desc in cursor.description]
    flight_list = []
    
    for flight in flights:
        flight_dict = dict(zip(columns, flight))
        # Convert datetime objects to ISO strings
        for key, value in flight_dict.items():
            if isinstance(value, datetime):
                flight_dict[key] = value.isoformat()
        flight_list.append(flight_dict)
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'flights': flight_list})
    }
```

### **7. Test the Application**

```bash
# Build and test locally
npm run dev

# Build for production
npm run build

# Test Docker container
docker build -t sky-high-booker:aws .
docker run -p 8080:80 \
  -e VITE_AWS_REGION=us-east-1 \
  -e VITE_AWS_USER_POOL_ID=your-pool-id \
  -e VITE_AWS_USER_POOL_CLIENT_ID=your-client-id \
  -e VITE_AWS_API_GATEWAY_URL=your-api-url \
  -e VITE_AWS_S3_BUCKET=your-bucket \
  sky-high-booker:aws
```

## 🔧 **Key Differences from Supabase**

### **Authentication:**
- **Supabase**: Simple email/password with built-in UI
- **AWS Cognito**: More configuration but better integration with AWS services
- **Benefits**: Better security features, MFA support, identity federation

### **Database:**
- **Supabase**: Managed PostgreSQL with real-time features
- **AWS RDS**: Managed PostgreSQL without real-time (can add with AppSync)
- **Benefits**: Better performance controls, backup options, monitoring

### **API:**
- **Supabase**: Auto-generated REST API
- **AWS**: Custom Lambda functions with API Gateway
- **Benefits**: Full control over API logic, better performance optimization

### **Storage:**
- **Supabase**: Built-in file storage
- **AWS S3**: Industry-standard object storage
- **Benefits**: Better CDN integration, more storage classes, lifecycle policies

## 📊 **Cost Comparison**

**Supabase Pro Plan**: ~$25/month
**AWS Services** (estimated):
- RDS db.t3.micro: ~$13/month
- Cognito: Free for <50,000 MAUs
- API Gateway: ~$3.50/1M requests
- S3: ~$0.023/GB/month
- Lambda: Free tier covers basic usage

**Total AWS**: ~$15-20/month (with room to scale)

## 🛡️ **Security Benefits**

1. **Network Isolation**: VPC provides better network security
2. **IAM Integration**: Fine-grained access control with AWS IAM
3. **Encryption**: RDS encryption at rest, S3 encryption, HTTPS everywhere
4. **Compliance**: AWS compliance certifications (SOC, HIPAA, etc.)
5. **Monitoring**: CloudWatch for comprehensive monitoring and alerting

## 📈 **Scaling Considerations**

- **ECS Auto Scaling**: Automatic container scaling based on CPU/memory
- **RDS Scaling**: Easy to upgrade instance types or add read replicas
- **CloudFront**: Global CDN for better performance
- **Multi-AZ**: High availability with minimal downtime

## 🔄 **Migration Notes**

1. **User Data**: Export existing users from Supabase, import to Cognito
2. **Database**: pg_dump from Supabase, restore to RDS
3. **Files**: Download from Supabase storage, upload to S3
4. **API Changes**: Update frontend to use new AWS API endpoints

This setup provides a production-ready, scalable architecture using AWS native services!