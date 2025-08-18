# Stock Market Data Analytics Pipeline

A simplified Terraform infrastructure for real-time stock market data processing using AWS services.

## Architecture

- **Kinesis Data Stream** - Real-time data ingestion
- **Lambda Function** - Data processing 
- **DynamoDB** - Processed data storage
- **S3 Bucket** - Data archival
- **IAM Role** - Service permissions

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed

### Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

### Configuration

All values are hardcoded in `main.tf` for simplicity:

- **Region**: us-east-1
- **Environment**: dev
- **Kinesis Stream**: stock-market-stream (1 shard)
- **DynamoDB Table**: stock-market-data (pay-per-request)
- **S3 Bucket**: stock-market-data-bucket-121485
- **Lambda Function**: ConsumerStockData (Python 3.13)

## Code Quality

### Pre-commit Hooks (Optional)

Set up automated code formatting and validation:

```bash
# Install pre-commit hooks
.\scripts\setup-pre-commit.ps1

# Or manually
pip install pre-commit
pre-commit install
```

This will automatically run on every commit:
- Terraform formatting (`terraform fmt`)
- Terraform validation
- Security scanning
- Python code formatting

## Project Structure

```
├── main.tf                    # Main infrastructure configuration
├── outputs.tf                 # Resource outputs
├── lambda_function.py         # Lambda function code
├── lambda_function.zip        # Lambda deployment package
├── modules/                   # Terraform modules
│   ├── kinesis/
│   ├── dynamodb/
│   ├── s3_bucket/
│   ├── iam_role/
│   └── lambda_function/
├── environments/              # Environment-specific configs
└── scripts/
    └── setup-pre-commit.ps1   # Pre-commit setup helper
```

## Deployment Commands

```bash
# Standard Terraform workflow
terraform init      # Initialize providers and modules
terraform validate  # Check syntax and configuration
terraform plan      # Preview infrastructure changes
terraform apply     # Create/update infrastructure
terraform destroy   # Remove all infrastructure
```

## Customization

To modify the configuration, edit the hardcoded values in `main.tf`:

- Change AWS region in the provider block
- Modify resource names in module calls
- Adjust Lambda memory, timeout, or batch size
- Update S3 bucket name (must be globally unique)

## Clean Architecture

This project uses a simplified approach:
- No variables files - all values hardcoded in main.tf
- No complex validation scripts - uses native Terraform commands
- Minimal dependencies - just Terraform and AWS CLI
- Clear module structure for maintainability

## Support

The infrastructure is designed to be simple and self-documenting. Use standard Terraform commands for all operations.