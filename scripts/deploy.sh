#!/bin/bash

# Terraform deployment wrapper script
# Usage: ./deploy.sh <environment> [plan|apply|destroy]

set -e

ENVIRONMENT=$1
ACTION=${2:-plan}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <environment> [plan|apply|destroy]"
  echo "Example: $0 dev plan"
  exit 1
fi

ENV_DIR="environments/$ENVIRONMENT"

if [ ! -d "$ENV_DIR" ]; then
  echo "❌ Environment '$ENVIRONMENT' not found in $ENV_DIR"
  exit 1
fi

cd $ENV_DIR

echo "🚀 Terraform $ACTION for environment: $ENVIRONMENT"
echo "Working directory: $(pwd)"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Format check
echo "🎨 Checking Terraform formatting..."
terraform fmt -check -recursive

case $ACTION in
  plan)
    echo "📋 Creating Terraform plan..."
    terraform plan -out=tfplan
    ;;
  
  apply)
    echo "🔨 Applying Terraform changes..."
    if [ "$ENVIRONMENT" == "prod" ]; then
      echo "⚠️  WARNING: Deploying to PRODUCTION!"
      read -p "Are you sure? (yes/no): " CONFIRM
      if [ "$CONFIRM" != "yes" ]; then
        echo "Deployment cancelled."
        exit 0
      fi
    fi
    terraform apply -auto-approve tfplan
    ;;
  
  destroy)
    echo "💣 WARNING: This will DESTROY all resources in $ENVIRONMENT!"
    read -p "Type 'destroy-$ENVIRONMENT' to confirm: " CONFIRM
    if [ "$CONFIRM" != "destroy-$ENVIRONMENT" ]; then
      echo "Destruction cancelled."
      exit 0
    fi
    terraform destroy
    ;;
  
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Valid actions: plan, apply, destroy"
    exit 1
    ;;
esac

echo "✅ Done!"
