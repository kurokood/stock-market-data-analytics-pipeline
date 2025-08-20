import boto3
import json
import time
import os
import yfinance as yf

# AWS Kinesis Configuration
kinesis_client = boto3.client('kinesis', region_name='us-east-1')
STREAM_NAME = os.environ.get("KINESIS_STREAM_NAME", "stock-market-stream")
STOCK_SYMBOL = "AAPL"
DELAY_TIME = 30  # Time delay in seconds

# Function to fetch stock data
def get_stock_data(symbol):
    try:
        stock = yf.Ticker(symbol)
        
        # Try different periods to get data
        for period in ["2d", "5d", "1wk"]:
            data = stock.history(period=period)
            if len(data) >= 2:
                break
        
        if len(data) < 2:
            # If still no data, create mock data for testing
            print("No real market data available, generating mock data for testing...")
            import random
            base_price = 150.0  # Mock base price for AAPL
            change = random.uniform(-5, 5)
            current_price = base_price + change
            
            stock_data = {
                "symbol": symbol,
                "open": round(base_price + random.uniform(-2, 2), 2),
                "high": round(current_price + random.uniform(0, 3), 2),
                "low": round(current_price - random.uniform(0, 3), 2),
                "price": round(current_price, 2),
                "previous_close": round(base_price, 2),
                "change": round(change, 2),
                "change_percent": round((change / base_price) * 100, 2),
                "volume": random.randint(50000000, 100000000),
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "data_source": "mock"  # Indicate this is test data
            }
            return stock_data

        # Use real market data
        stock_data = {
            "symbol": symbol,
            "open": round(data.iloc[-1]["Open"], 2),
            "high": round(data.iloc[-1]["High"], 2),
            "low": round(data.iloc[-1]["Low"], 2),
            "price": round(data.iloc[-1]["Close"], 2),
            "previous_close": round(data.iloc[-2]["Close"], 2),
            "change": round(data.iloc[-1]["Close"] - data.iloc[-2]["Close"], 2),
            "change_percent": round(((data.iloc[-1]["Close"] - data.iloc[-2]["Close"]) / data.iloc[-2]["Close"]) * 100, 2),
            "volume": int(data.iloc[-1]["Volume"]),
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "data_source": "yfinance"  # Indicate this is real data
        }
        return stock_data
        
    except Exception as e:
        print(f"Error fetching stock data: {e}")
        return None

# Function to stream data into Kinesis
def send_to_kinesis():
    print(f"Starting stock data producer for {STOCK_SYMBOL}")
    print(f"Sending data to Kinesis stream: {STREAM_NAME}")
    print(f"Data will be sent every {DELAY_TIME} seconds")
    print("-" * 50)
    
    iteration = 0
    while True:
        try:
            iteration += 1
            print(f"\n[Iteration {iteration}] Fetching stock data...")
            
            stock_data = get_stock_data(STOCK_SYMBOL)
            if stock_data is None:
                print("❌ Failed to get stock data, skipping this iteration")
                time.sleep(DELAY_TIME)
                continue

            print(f"✅ Got stock data: ${stock_data['price']} ({stock_data['change']:+.2f}, {stock_data['change_percent']:+.2f}%)")
            print(f"📊 Data source: {stock_data.get('data_source', 'unknown')}")

            # Send to Kinesis
            response = kinesis_client.put_record(
                StreamName=STREAM_NAME,
                Data=json.dumps(stock_data),
                PartitionKey=STOCK_SYMBOL
            )

            # Check response
            if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
                print(f"🚀 Successfully sent to Kinesis (Shard: {response['ShardId']})")
            else:
                print(f"❌ Error sending to Kinesis: {response}")

            print(f"⏳ Waiting {DELAY_TIME} seconds until next iteration...")
            time.sleep(DELAY_TIME)

        except KeyboardInterrupt:
            print("\n🛑 Stopping producer (Ctrl+C pressed)")
            break
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            print(f"⏳ Waiting {DELAY_TIME} seconds before retry...")
            time.sleep(DELAY_TIME)

# Run the streaming function
send_to_kinesis()
