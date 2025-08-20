# Glue Catalog Database Outputs
output "database_name" {
  description = "Name of the Glue Catalog database"
  value       = aws_glue_catalog_database.stock_data_db.name
}

output "database_arn" {
  description = "ARN of the Glue Catalog database"
  value       = aws_glue_catalog_database.stock_data_db.arn
}

output "database_catalog_id" {
  description = "Catalog ID of the Glue Catalog database"
  value       = aws_glue_catalog_database.stock_data_db.catalog_id
}

# Glue Catalog Table Outputs
output "table_name" {
  description = "Name of the Glue Catalog table"
  value       = aws_glue_catalog_table.stock_data_table.name
}

output "table_arn" {
  description = "ARN of the Glue Catalog table"
  value       = aws_glue_catalog_table.stock_data_table.arn
}

output "table_catalog_id" {
  description = "Catalog ID of the Glue Catalog table"
  value       = aws_glue_catalog_table.stock_data_table.catalog_id
}

# Athena Query Information
output "athena_database" {
  description = "Database name to use in Athena queries"
  value       = aws_glue_catalog_database.stock_data_db.name
}

output "athena_table" {
  description = "Table name to use in Athena queries"
  value       = aws_glue_catalog_table.stock_data_table.name
}

output "sample_athena_query" {
  description = "Sample Athena SQL query to get started with the data"
  value = <<-EOT
    SELECT 
      symbol,
      timestamp,
      open,
      high,
      low,
      price,
      previous_close,
      volume
    FROM ${aws_glue_catalog_database.stock_data_db.name}.${aws_glue_catalog_table.stock_data_table.name}
    WHERE symbol = 'AAPL'
    ORDER BY timestamp DESC
    LIMIT 10;
  EOT
}