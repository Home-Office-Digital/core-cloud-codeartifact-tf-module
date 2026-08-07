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

  repositories_without_upstreams = { for k, v in var.repositories : k => v if length(v.upstreams) == 0 }
  repositories_with_upstreams    = { for k, v in var.repositories : k => v if length(v.upstreams) > 0 }

  repository_arns = merge(
    { for k, v in aws_codeartifact_repository.this : k => v.arn },
    { for k, v in aws_codeartifact_repository.with_upstreams : k => v.arn },
  )

  # A "*" principal is only ever safe when it's also pinned to this AWS Organization. Rather than trust every caller it's not possible to end up with a truly public policy (by design)
  # through this module (which is what we want).
  domain_policy_needs_org_id = anytrue([for s in var.domain_permissions_policy : contains(s.principals, "*")])
  repository_policy_needs_org_id = anytrue(flatten([
    for statements in values(var.repository_permissions_policies) : [
      for s in statements : contains(s.principals, "*")
    ]
  ]))
  needs_org_id = local.domain_policy_needs_org_id || local.repository_policy_needs_org_id
  org_id       = local.needs_org_id ? data.aws_organizations_organization.current[0].id : null

  domain_policy_statements = [
    for s in var.domain_permissions_policy : merge(s, {
      conditions = concat(
        s.conditions,
        contains(s.principals, "*") ? [{
          test     = "StringEquals"
          variable = "aws:PrincipalOrgID"
          values   = [local.org_id]
        }] : []
      )
    })
  ]

  repository_policy_statements = {
    for repo_name, statements in var.repository_permissions_policies : repo_name => [
      for s in statements : merge(s, {
        conditions = concat(
          s.conditions,
          contains(s.principals, "*") ? [{
            test     = "StringEquals"
            variable = "aws:PrincipalOrgID"
            values   = [local.org_id]
          }] : []
        )
      })
    ]
  }
}
