# Stock Market Data Analytics Pipeline

A simplified Terraform infrastructure for real-time stock market data processing using AWS services.

## Architecture

- **Kinesis Data Stream** - Real-time data ingestion
- **Lambda Function** - Data processing 
- **DynamoDB** - Processed data storage with streams
- **S3 Bucket** - Data archival and analytics
- **Glue Catalog** - Data catalog for Athena queries
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
- **DynamoDB Table**: stock-market-data (pay-per-request, streams enabled)
- **S3 Bucket**: stock-market-data-bucket-121485
- **Lambda Function**: ConsumerStockData (Python 3.13)
- **Glue Database**: stock_data_db
- **Glue Table**: stock_data_table (for Athena queries)

## Code Quality

### Pre-commit Hooks (Optional)

Set up automated code formatting and validation:

```bash
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
└── modules/                   # Terraform modules
    ├── kinesis/
    ├── dynamodb/
    ├── s3_bucket/
    ├── iam_role/
    ├── lambda_function/
    └── glue_catalog/
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

## Querying Data with Athena

After deploying the infrastructure, you can query the stock data using Amazon Athena:

### Sample Queries

```sql
-- Get latest stock prices
SELECT symbol, timestamp, open, high, low, price, previous_close, volume
FROM stock_data_db.stock_data_table
ORDER BY timestamp DESC
LIMIT 10;

-- Get AAPL price history
SELECT timestamp, open, high, low, price, previous_close, volume
FROM stock_data_db.stock_data_table
WHERE symbol = 'AAPL'
ORDER BY timestamp DESC;

-- Calculate daily averages
SELECT 
  symbol,
  DATE(timestamp) as date,
  AVG(price) as avg_price,
  MAX(high) as max_high,
  MIN(low) as min_low,
  AVG(volume) as avg_volume
FROM stock_data_db.stock_data_table
GROUP BY symbol, DATE(timestamp)
ORDER BY date DESC;
```

### Access Athena
1. Go to AWS Console → Athena
2. Select database: `stock_data_db`
3. Query table: `stock_data_table`
4. Data location: `s3://stock-market-data-bucket-121485/raw/`

## Clean Architecture

This project uses a simplified approach:
- No variables files - all values hardcoded in main.tf
- No complex validation scripts - uses native Terraform commands
- Minimal dependencies - just Terraform and AWS CLI
- Clear module structure for maintainability

## Support

The infrastructure is designed to be simple and self-documenting. Use standard Terraform commands for all operations.