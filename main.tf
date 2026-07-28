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
  for_each = var.repositories

  domain      = aws_codeartifact_domain.this.domain
  repository  = each.key
  description = each.value.description

  dynamic "upstream" {
    for_each = each.value.upstreams
    content {
      repository_name = upstream.value
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
