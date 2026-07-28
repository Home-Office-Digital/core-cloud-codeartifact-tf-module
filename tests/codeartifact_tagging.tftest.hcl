# Tag validation for CodeArtifact resources - validates local.common_tags

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

run "validate_mandatory_tags_on_domain" {
  command = plan

  assert {
    condition     = contains(keys(aws_codeartifact_domain.this.tags), "Environment")
    error_message = "Environment tag must be present on the CodeArtifact domain"
  }

  assert {
    condition     = contains(keys(aws_codeartifact_domain.this.tags), "Project")
    error_message = "Project tag must be present on the CodeArtifact domain"
  }

  assert {
    condition     = contains(keys(aws_codeartifact_domain.this.tags), "ManagedBy")
    error_message = "ManagedBy tag must be present on the CodeArtifact domain"
  }

  assert {
    condition     = contains(keys(aws_codeartifact_domain.this.tags), "source-repo")
    error_message = "source-repo tag must be present on the CodeArtifact domain"
  }
}

run "validate_tag_values" {
  command = plan

  variables {
    environment  = "test-ops-tooling"
    project_name = "cc"
    source-repo  = "github.com/Home-Office-Digital/core-cloud-tooling-resources-terragrunt"
  }

  assert {
    condition     = aws_codeartifact_domain.this.tags["Environment"] == "test-ops-tooling"
    error_message = "Environment tag must match the environment variable"
  }

  assert {
    condition     = aws_codeartifact_domain.this.tags["Project"] == "cc"
    error_message = "Project tag must match the project_name variable"
  }

  assert {
    condition     = aws_codeartifact_domain.this.tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag must be set to 'terraform'"
  }

  assert {
    condition     = aws_codeartifact_domain.this.tags["source-repo"] == "github.com/Home-Office-Digital/core-cloud-tooling-resources-terragrunt"
    error_message = "source-repo tag must match the source-repo variable"
  }
}

run "validate_additional_tags_merged" {
  command = plan

  variables {
    tags = {
      Environment  = "test"
      Project      = "testproject"
      cost-centre  = "1709155"
      account-code = "521835"
      portfolio-id = "CTO"
      project-id   = "CC"
      service-id   = "QE"
      CustomTag    = "CustomValue"
    }
  }

  assert {
    condition     = aws_codeartifact_domain.this.tags["cost-centre"] == "1709155"
    error_message = "Additional tags from var.tags must be merged into domain tags"
  }

  assert {
    condition     = can(aws_codeartifact_domain.this.tags["CustomTag"])
    error_message = "Custom tags from var.tags must be present on the domain"
  }
}

run "validate_repository_tags" {
  command = plan

  variables {
    repositories = {
      npm-store = {
        description = "npm store repository"
        tags = {
          RepoOwner = "platform-team"
        }
      }
    }
  }

  assert {
    condition     = aws_codeartifact_repository.this["npm-store"].tags["Environment"] == "test-ops-tooling"
    error_message = "Repository must inherit common tags"
  }

  assert {
    condition     = aws_codeartifact_repository.this["npm-store"].tags["RepoOwner"] == "platform-team"
    error_message = "Repository-specific tags must be merged with common tags"
  }
}

run "validate_kms_key_tags" {
  command = plan

  variables {
    kms_key_type = "CUSTOMER_MANAGED"
  }

  assert {
    condition     = contains(keys(aws_kms_key.codeartifact[0].tags), "Environment")
    error_message = "KMS key must have Environment tag"
  }

  assert {
    condition     = aws_kms_key.codeartifact[0].tags["ManagedBy"] == "terraform"
    error_message = "KMS key ManagedBy tag must be 'terraform'"
  }
}
