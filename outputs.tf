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
  value       = local.repository_arns
}

output "repository_admins" {
  description = "Map of repository name to the AWS account ID that administers the repository"
  value = merge(
    { for k, v in aws_codeartifact_repository.this : k => v.administrator_account },
    { for k, v in aws_codeartifact_repository.with_upstreams : k => v.administrator_account },
  )
}

output "domain_permissions_policy_revision" {
  description = "The current revision of the CodeArtifact domain permissions (resource-based) policy, if var.domain_permissions_policy is set"
  value       = try(aws_codeartifact_domain_permissions_policy.this[0].policy_revision, null)
}

output "repository_permissions_policy_revisions" {
  description = "Map of repository name to the current revision of its CodeArtifact repository permissions (resource-based) policy, for repositories configured via var.repository_permissions_policies"
  value       = { for k, v in aws_codeartifact_repository_permissions_policy.this : k => v.policy_revision }
}
