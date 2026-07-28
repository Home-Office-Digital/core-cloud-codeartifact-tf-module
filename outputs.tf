output "domain_name" {
  description = "The name of the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.domain
}

output "domain_arn" {
  description = "The ARN of the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.arn
}

output "domain_owner" {
  description = "The AWS account ID that owns the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.owner
}

output "domain_encryption_key" {
  description = "The KMS key ARN used to encrypt the domain (null when using the AWS-managed key)"
  value       = aws_codeartifact_domain.this.encryption_key
}

output "kms_key_arn" {
  description = "The ARN of the customer-managed KMS key used by the domain, if any"
  value       = local.kms_key_arn
}

output "repository_arns" {
  description = "Map of repository name to repository ARN"
  value       = { for k, v in aws_codeartifact_repository.this : k => v.arn }
}

output "repository_admins" {
  description = "Map of repository name to the AWS account ID that administers the repository"
  value       = { for k, v in aws_codeartifact_repository.this : k => v.administrator_account }
}
