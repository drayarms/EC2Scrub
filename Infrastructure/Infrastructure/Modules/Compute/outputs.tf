output "lambda_zip_path" {
  description = "Path to the generated Lambda deployment package"
  value = data.archive_file.lambda_zip.output_path
}
