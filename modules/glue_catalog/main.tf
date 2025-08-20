# AWS Glue Catalog Database
resource "aws_glue_catalog_database" "stock_data_db" {
  name        = var.database_name
  description = var.database_description

  tags = var.tags
}

# AWS Glue Catalog Table for stock data
resource "aws_glue_catalog_table" "stock_data_table" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.stock_data_db.name
  description   = var.table_description

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"                   = "json"
    "compressionType"                 = "none"
    "typeOfData"                      = "file"
    "useGlueParquetWriter"           = "true"
    "projection.enabled"              = "false"
    "has_encrypted_data"              = "false"
  }

  storage_descriptor {
    location      = var.s3_location
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "JsonSerDe"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      
      parameters = {
        "serialization.format" = "1"
      }
    }

    # Define the schema for stock data - matches the specified table structure
    columns {
      name = "symbol"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "string"
    }

    columns {
      name = "open"
      type = "double"
    }

    columns {
      name = "high"
      type = "double"
    }

    columns {
      name = "low"
      type = "double"
    }

    columns {
      name = "price"
      type = "double"
    }

    columns {
      name = "previous_close"
      type = "double"
    }

    columns {
      name = "volume"
      type = "double"
    }
  }

  # Note: aws_glue_catalog_table doesn't support tags directly
}