#!/bin/bash

# Script to import existing AWS resources into Terraform dev workspace state
# Run this from the terraform directory after selecting the dev workspace

set -e

echo "⚠️  This script will import existing AWS resources into the dev workspace"
echo "Make sure you're in the correct workspace before proceeding!"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Check current workspace
WORKSPACE=$(terraform workspace show)
echo "Current workspace: $WORKSPACE"

if [ "$WORKSPACE" != "dev" ]; then
    echo "❌ Error: Not in dev workspace. Switch with: terraform workspace select dev"
    exit 1
fi

echo "Starting import process..."

# Import IAM resources
echo "Importing IAM Policy..."
terraform import aws_iam_policy.ecs_secrets_policy arn:aws:iam::255945442255:policy/ce11g3-policy-dev || echo "Already imported or failed"

echo "Importing ECS Execution Role..."
terraform import aws_iam_role.ecs_execution_role ce11g3-ecs-execution-role || echo "Already imported or failed"

echo "Importing ECS Task Role..."
terraform import aws_iam_role.ecs_task_role ce11g3-ecs-task-role || echo "Already imported or failed"

echo "Importing Cognito Authenticated Role..."
terraform import aws_iam_role.authenticated_role sky-high-booker-cognito-authenticated || echo "Already imported or failed"

echo "Importing Lambda Booking Role..."
terraform import aws_iam_role.lambda_booking_role sky-high-booker-dev-lambda-booking-role || echo "Already imported or failed"

# Import DynamoDB tables
echo "Importing DynamoDB Tables..."
terraform import aws_dynamodb_table.bookings sky-high-booker-bookings || echo "Already imported or failed"

# Import ECR repository
echo "Importing ECR Repository..."
terraform import aws_ecr_repository.sky_high_booker ce11g3-sky-high-booker || echo "Already imported or failed"

# Import ALB and Target Group (need to find ARNs)
echo "Importing ALB..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names sky-high-booker-dev-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    terraform import aws_lb.main "$ALB_ARN" || echo "Already imported or failed"
fi

echo "Importing Target Group..."
TG_ARN=$(aws elbv2 describe-target-groups --names sky-high-booker-dev-tg --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    terraform import aws_lb_target_group.ecs "$TG_ARN" || echo "Already imported or failed"
fi

# Import CloudWatch Log Groups
echo "Importing CloudWatch Log Groups..."
terraform import aws_cloudwatch_log_group.create_booking_logs /aws/lambda/sky-high-booker-dev-createBooking || echo "Already imported or failed"
terraform import aws_cloudwatch_log_group.get_bookings_logs /aws/lambda/sky-high-booker-dev-getBookings || echo "Already imported or failed"
terraform import aws_cloudwatch_log_group.get_booking_by_id_logs /aws/lambda/sky-high-booker-dev-getBookingById || echo "Already imported or failed"
terraform import aws_cloudwatch_log_group.get_occupied_seats_logs /aws/lambda/sky-high-booker-dev-getOccupiedSeats || echo "Already imported or failed"

echo "✅ Import process completed!"
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to verify the state"
echo "2. Address any configuration drift between code and actual resources"
