# =============================================================================
# GLUE CATALOG MODULE VARIABLES
# =============================================================================
# This module creates AWS Glue Catalog database and table for Athena queries
# Dependencies: S3 bucket (for data location)
# Used by: Amazon Athena for querying stock market data stored in S3

variable "database_name" {
  description = "Name of the Glue Catalog database for stock market data analytics. Used by Athena to organize tables and enable SQL queries on S3 data."
  type        = string
  default     = "stock_data_db"

  validation {
    condition = can(regex("^[a-z0-9_]+$", var.database_name)) && length(var.database_name) >= 1 && length(var.database_name) <= 255
    error_message = "Database name must be 1-255 characters and contain only lowercase letters, numbers, and underscores."
  }
}

variable "database_description" {
  description = "Description of the Glue Catalog database explaining its purpose and contents."
  type        = string
  default     = "Database for stock market data analytics and reporting"

  validation {
    condition = length(var.database_description) <= 2048
    error_message = "Database description must be no more than 2048 characters long."
  }
}

variable "table_name" {
  description = "Name of the Glue Catalog table for stock market data. This table defines the schema for querying JSON data stored in S3 using Athena."
  type        = string
  default     = "stock_data_table"

  validation {
    condition = can(regex("^[a-z0-9_]+$", var.table_name)) && length(var.table_name) >= 1 && length(var.table_name) <= 255
    error_message = "Table name must be 1-255 characters and contain only lowercase letters, numbers, and underscores."
  }
}

variable "table_description" {
  description = "Description of the Glue Catalog table explaining the data structure and usage."
  type        = string
  default     = "Table containing real-time stock market data in JSON format for analytics and reporting"

  validation {
    condition = length(var.table_description) <= 2048
    error_message = "Table description must be no more than 2048 characters long."
  }
}

variable "s3_location" {
  description = "S3 location where the stock market data files are stored. Must be a valid S3 URI pointing to the data directory. Used by Athena to read data files."
  type        = string

  validation {
    condition = can(regex("^s3://[a-z0-9.-]+/.+", var.s3_location))
    error_message = "S3 location must be a valid S3 URI starting with s3:// followed by bucket name and path."
  }
}

variable "data_format" {
  description = "Format of the data files stored in S3. Supported formats include JSON, Parquet, CSV, ORC, and Avro."
  type        = string
  default     = "JSON"

  validation {
    condition = contains(["JSON", "PARQUET", "CSV", "ORC", "AVRO"], upper(var.data_format))
    error_message = "Data format must be one of: JSON, PARQUET, CSV, ORC, AVRO."
  }
}

variable "enable_partition_projection" {
  description = "Enable partition projection for improved query performance. Useful for time-series data partitioned by date/time."
  type        = bool
  default     = false
}

variable "partition_keys" {
  description = "List of partition keys for the table. Used to organize data and improve query performance by filtering on partition columns."
  type = list(object({
    name = string
    type = string
  }))
  default = []

  validation {
    condition = alltrue([
      for key in var.partition_keys : contains(["string", "int", "bigint", "double", "boolean", "date", "timestamp"], key.type)
    ])
    error_message = "Partition key types must be valid Hive data types: string, int, bigint, double, boolean, date, timestamp."
  }
}

variable "compression_type" {
  description = "Compression type used for the data files. Common types include gzip, snappy, lz4, and brotli."
  type        = string
  default     = "none"

  validation {
    condition = contains(["none", "gzip", "snappy", "lz4", "brotli", "zstd"], lower(var.compression_type))
    error_message = "Compression type must be one of: none, gzip, snappy, lz4, brotli, zstd."
  }
}

variable "tags" {
  description = "A map of tags to assign to the Glue Catalog resources. Tags are used for resource organization, cost allocation, and access control."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[\\w\\s+=.:/@-]*$", k)) && can(regex("^[\\w\\s+=.:/@-]*$", v))
    ])
    error_message = "Tag keys and values must contain only alphanumeric characters, spaces, and the following characters: + = . : / @ -"
  }

  validation {
    condition = length(var.tags) <= 50
    error_message = "Maximum of 50 tags allowed per Glue Catalog resource."
  }
}