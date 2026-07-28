# Security and compliance validation for CodeArtifact
# Validates AWS-managed vs customer-managed KMS key behaviour.

provider "aws" {
  region                      = "eu-west-2"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

variables {
  domain_name  = "testdomain"
  project_name = "testproject"
  environment  = "test"
  region       = "eu-west-2"
  source-repo  = "github.com/Home-Office-Digital/core-cloud-tooling-resources-terragrunt"
  account_id   = "123456789012"

  tags = {
    Environment  = "test-ops-tooling"
    Project      = "cc"
    cost-centre  = "1709144"
    account-code = "521835"
    portfolio-id = "CTO"
    project-id   = "CC"
    service-id   = "QE"
  }
}

run "validate_aws_managed_key_is_default" {
  command = plan

  assert {
    condition     = var.kms_key_type == "AWS_MANAGED"
    error_message = "kms_key_type should default to AWS_MANAGED"
  }

  assert {
    condition     = length(aws_kms_key.codeartifact) == 0
    error_message = "No KMS key should be created when kms_key_type is AWS_MANAGED"
  }
}

run "validate_customer_managed_key_created" {
  command = plan

  variables {
    kms_key_type = "CUSTOMER_MANAGED"
  }

  assert {
    condition     = length(aws_kms_key.codeartifact) == 1
    error_message = "A KMS key should be created when kms_key_type is CUSTOMER_MANAGED and no existing key ARN is supplied"
  }

  assert {
    condition     = aws_kms_key.codeartifact[0].enable_key_rotation == true
    error_message = "Customer-managed KMS key must have key rotation enabled"
  }

  assert {
    condition     = aws_kms_alias.codeartifact[0].name == "alias/codeartifact"
    error_message = "KMS alias should be prefixed with 'alias/' and use the default kms_alias value"
  }
}

run "validate_existing_customer_managed_key_reused" {
  command = plan

  variables {
    kms_key_type                 = "CUSTOMER_MANAGED"
    customer_managed_kms_key_arn = "arn:aws:kms:eu-west-2:123456789012:key/existing-key-id"
  }

  assert {
    condition     = length(aws_kms_key.codeartifact) == 0
    error_message = "No new KMS key should be created when an existing customer_managed_kms_key_arn is supplied"
  }

  assert {
    condition     = aws_codeartifact_domain.this.encryption_key == "arn:aws:kms:eu-west-2:123456789012:key/existing-key-id"
    error_message = "Domain encryption_key should use the supplied existing KMS key ARN"
  }
}
