import json
import boto3
import base64
import os
import logging
from datetime import datetime
from decimal import Decimal

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS Clients
dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

# Resource Names from environment variables
DYNAMO_TABLE = os.environ.get("DYNAMODB_TABLE_NAME", "stock-market-data")
S3_BUCKET = os.environ.get("S3_BUCKET_NAME", "stock-market-data-bucket-121485")

# Table reference
table = dynamodb.Table(DYNAMO_TABLE)

def lambda_handler(event, context):
    """
    Process Kinesis records containing stock market data.
    Store processed data in DynamoDB and archive raw data in S3.
    """
    processed_count = 0
    failed_count = 0
    
    logger.info(f"Processing {len(event['Records'])} Kinesis records")
    
    for record in event['Records']:
        try:
            # Decode base64 Kinesis data
            raw_data = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
            payload = json.loads(raw_data)
            
            logger.info(f"Processing record for symbol: {payload.get('symbol', 'UNKNOWN')}")
            
            # Validate required fields
            if not validate_record(payload):
                logger.error(f"Invalid record format: {payload}")
                failed_count += 1
                continue
            
            # Archive raw data to S3
            archive_success = archive_raw_data_to_s3(payload)
            if not archive_success:
                logger.warning("Failed to archive raw data to S3, continuing with processing")
            
            # Process and store data in DynamoDB
            dynamodb_success = store_processed_data_in_dynamodb(payload)
            if dynamodb_success:
                processed_count += 1
                logger.info(f"Successfully processed record for {payload['symbol']}")
            else:
                failed_count += 1
                logger.error(f"Failed to store processed data for {payload['symbol']}")
                
        except json.JSONDecodeError as e:
            logger.error(f"Failed to decode JSON from Kinesis record: {e}")
            failed_count += 1
        except Exception as e:
            logger.error(f"Unexpected error processing record: {e}")
            failed_count += 1
    
    logger.info(f"Processing complete. Processed: {processed_count}, Failed: {failed_count}")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Processing complete",
            "processed_count": processed_count,
            "failed_count": failed_count
        })
    }


def validate_record(payload):
    """
    Validate that the record contains required fields.
    """
    required_fields = ["symbol", "price", "timestamp"]
    
    for field in required_fields:
        if field not in payload:
            logger.error(f"Missing required field: {field}")
            return False
    
    # Validate data types
    try:
        float(payload["price"])
        if "volume" in payload:
            int(payload["volume"])
    except (ValueError, TypeError) as e:
        logger.error(f"Invalid data type in payload: {e}")
        return False
    
    return True


def archive_raw_data_to_s3(payload):
    """
    Archive raw data to S3 with organized folder structure.
    """
    try:
        # Parse timestamp for folder organization
        timestamp = payload["timestamp"]
        dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        
        # Create S3 key with organized structure: raw/{year}/{month}/{day}/{hour}/
        s3_key = f"raw/{dt.year:04d}/{dt.month:02d}/{dt.day:02d}/{dt.hour:02d}/kinesis-records-{payload['symbol']}-{dt.strftime('%Y%m%d%H%M%S')}.json"
        
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=json.dumps(payload, default=str),
            ContentType='application/json'
        )
        
        logger.info(f"Raw data archived to S3: {s3_key}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to archive raw data to S3: {e}")
        return False


def store_processed_data_in_dynamodb(payload):
    """
    Store processed stock data in DynamoDB.
    """
    try:
        # Get current timestamp for processing metadata
        processed_at = datetime.utcnow().isoformat() + 'Z'
        
        # Prepare data for DynamoDB (convert floats to Decimal for DynamoDB compatibility)
        processed_data = {
            "symbol": payload["symbol"],
            "timestamp": payload["timestamp"],
            "price": Decimal(str(payload["price"])),
            "processed_at": processed_at
        }
        
        # Add optional fields if present
        if "volume" in payload:
            processed_data["volume"] = int(payload["volume"])
        
        if "exchange" in payload:
            processed_data["exchange"] = payload["exchange"]
        
        # Store in DynamoDB
        table.put_item(Item=processed_data)
        
        logger.info(f"Data stored in DynamoDB for {payload['symbol']} at {payload['timestamp']}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to store data in DynamoDB: {e}")
        return False