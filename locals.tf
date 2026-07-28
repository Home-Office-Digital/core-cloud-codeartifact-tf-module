locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      source-repo = var.source-repo
    },
    var.tags
  )

  # Only create a KMS key when customer-managed encryption is requested and no
  # existing key ARN has been supplied.
  create_kms_key = var.kms_key_type == "CUSTOMER_MANAGED" && var.customer_managed_kms_key_arn == null

  domain_encryption_key = (
    var.kms_key_type != "CUSTOMER_MANAGED" ? null :
    var.customer_managed_kms_key_arn != null ? var.customer_managed_kms_key_arn :
    aws_kms_key.codeartifact[0].arn
  )

  kms_key_arn = local.create_kms_key ? aws_kms_key.codeartifact[0].arn : var.customer_managed_kms_key_arn
}
