# Stock Market Data Analytics Pipeline

A simplified Terraform infrastructure for real-time stock market data processing using AWS services.

## Architecture

- **Kinesis Data Stream** – Real-time data ingestion
- **Lambda Functions** –
  - `ConsumerStockData`: processes Kinesis records, archives to S3, writes to DynamoDB
  - `StockTrendAnalysis`: triggered by DynamoDB Streams for trend analysis and alerts
- **DynamoDB** – `stock-market-data` table with streams enabled
- **S3 Buckets** –
  - `stock-market-data-bucket-121485`: raw/archive storage for Kinesis payloads
  - `athena-query-results-121485`: results location for Athena query outputs
- **Glue Catalog** – Database and table definitions for querying S3 data with Athena
- **SNS** – `stock-trend-alerts` topic with email subscription for alerts
- **IAM Roles** – Execution roles for Lambdas
- **Local Producer Script** – Sends stock data to Kinesis using yfinance or mock data

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

Confirm the email subscription sent by Amazon SNS to activate alerts.

### Configuration

All values are hardcoded in `main.tf` for simplicity:

- **Region**: us-east-1
- **Environment**: dev
- **Kinesis Stream**: `stock-market-stream` (1 shard)
- **DynamoDB Table**: `stock-market-data` (on-demand, streams enabled)
- **S3 Buckets**: `stock-market-data-bucket-121485`, `athena-query-results-121485`
- **Lambda Functions**: `ConsumerStockData`, `StockTrendAnalysis` (Python 3.13)
- **Glue Catalog**: Database `stock_data_db`, Table `stock_data_table`
- **SNS Topic**: `stock-trend-alerts` with email subscription

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
├── main.tf                                      # Main infrastructure configuration
├── outputs.tf                                   # Resource outputs
├── producer_data_function.py                    # Local producer to send data to Kinesis
└── modules/                                     # Terraform modules
    ├── kinesis/
    ├── dynamodb/
    ├── s3_bucket/
    ├── iam_role/
    ├── lambda_function/
    │   ├── lambda_consumer/
    │   │   ├── lambda_function.py
    │   │   └── lambda_function.zip
    │   └── lambda_trend/
    │       ├── lambda_function.py
    │       └── lambda_function.zip
    ├── glue_catalog/
    └── sns/
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

### Producer script
- Set stream name dynamically via environment variable (fallback is `stock-market-stream`):
  - PowerShell: `$env:KINESIS_STREAM_NAME="your-stream"; python .\producer_data_function.py`
  - Bash: `KINESIS_STREAM_NAME=your-stream python producer_data_function.py`

### Lambda environment variables
- Consumer: `DYNAMODB_TABLE_NAME`, `S3_BUCKET_NAME`
- Trend: `DYNAMODB_TABLE_NAME`, `SNS_TOPIC_ARN`

### S3 bucket destroy behavior
- Buckets are configured with `force_destroy = true` so `terraform destroy` will delete non-empty buckets (including object versions). If you enabled this after initial creation, run `terraform apply` first to update the buckets, then `terraform destroy`.

## Querying Data with Athena

This project uses Amazon Athena to query data defined in the AWS Glue Catalog. Athena itself is a query service and is not provisioned via Terraform in this project. After deploying the infrastructure and ingesting data, you can run queries in the Athena console against the Glue database/table created by Terraform.

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

---

###  Author: Mon Villarin
 📌 LinkedIn: [Ramon Villarin](https://www.linkedin.com/in/ramon-villarin/)  
 📌 Portfolio Site: [MonVillarin.com](https://monvillarin.com)  
 📌 Blog Post: [Real-Time Stock Market Data Analytics Pipeline on AWS with Terraform](https://blog.monvillarin.com/real-time-stock-market-data-analytics-pipeline-on-aws-with-terraform)
