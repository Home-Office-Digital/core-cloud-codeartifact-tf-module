resource "aws_kms_key" "codeartifact" {
  count = local.create_kms_key ? 1 : 0

  description             = "KMS key for CodeArtifact domain ${var.domain_name} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_key_policy" "codeartifact" {
  count = local.create_kms_key ? 1 : 0

  key_id = aws_kms_key.codeartifact[0].id
  policy = jsonencode({
    Id = "${var.kms_alias} policy"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
        ]
        Effect = "Allow"
        Principal = {
          Service = "codeartifact.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Allow CodeArtifact to use the key"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_kms_alias" "codeartifact" {
  count = local.create_kms_key ? 1 : 0

  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.codeartifact[0].key_id
}

resource "aws_codeartifact_domain" "this" {
  domain         = var.domain_name
  encryption_key = local.domain_encryption_key

  tags = local.common_tags
}

resource "aws_codeartifact_repository" "this" {
  for_each = local.repositories_without_upstreams

  domain      = aws_codeartifact_domain.this.domain
  repository  = each.key
  description = each.value.description

  dynamic "external_connections" {
    for_each = each.value.external_connection != null ? [each.value.external_connection] : []
    content {
      external_connection_name = external_connections.value
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

resource "aws_codeartifact_repository" "with_upstreams" {
  for_each = local.repositories_with_upstreams

  domain      = aws_codeartifact_domain.this.domain
  repository  = each.key
  description = each.value.description

  dynamic "upstream" {
    for_each = each.value.upstreams
    content {
      repository_name = aws_codeartifact_repository.this[upstream.value].repository
    }
  }

  dynamic "external_connections" {
    for_each = each.value.external_connection != null ? [each.value.external_connection] : []
    content {
      external_connection_name = external_connections.value
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

data "aws_organizations_organization" "current" {
  count = local.needs_org_id ? 1 : 0
}

# Domain-level resource policy. Required for any principal outside the
# domain's own account e.g. a cross-account GitHub OIDC role
data "aws_iam_policy_document" "domain" {
  count = length(var.domain_permissions_policy) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = local.domain_policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = [aws_codeartifact_domain.this.arn]

      principals {
        type        = "AWS"
        identifiers = statement.value.principals
      }

      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_codeartifact_domain_permissions_policy" "this" {
  count = length(var.domain_permissions_policy) > 0 ? 1 : 0

  domain          = aws_codeartifact_domain.this.domain
  policy_document = data.aws_iam_policy_document.domain[0].json
}

# Repository-level resource policies. Required for any principal outside the
# domain's own account to call repository-level actions like
# ReadFromRepository, GetRepositoryEndpoint or PublishPackageVersion.
data "aws_iam_policy_document" "repository" {
  for_each = local.repository_policy_statements

  dynamic "statement" {
    for_each = each.value
    content {
      sid     = statement.value.sid
      effect  = statement.value.effect
      actions = statement.value.actions
      resources = [
        local.repository_arns[each.key],
        local.repository_package_arns[each.key],
      ]

      principals {
        type        = "AWS"
        identifiers = statement.value.principals
      }

      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_codeartifact_repository_permissions_policy" "this" {
  for_each = local.repository_policy_statements

  domain          = aws_codeartifact_domain.this.domain
  repository      = each.key
  policy_document = data.aws_iam_policy_document.repository[each.key].json

  depends_on = [
    aws_codeartifact_repository.this,
    aws_codeartifact_repository.with_upstreams,
  ]
}
