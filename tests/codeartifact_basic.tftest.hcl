# Basic CodeArtifact domain/repository resource validation
# This test validates basic domain and repository creation, including upstream
# and external connection wiring. It serves as a sanity check to ensure the
# module can create resources with the expected properties.

# Import shared provider configuration for local testing
# This allows tests to run without real AWS credentials

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

run "validate_domain_creation" {
  command = plan

  assert {
    condition     = aws_codeartifact_domain.this.domain == "testdomain"
    error_message = "Domain name should match the domain_name variable"
  }
}

run "validate_no_repositories_by_default" {
  command = plan

  assert {
    condition     = length(aws_codeartifact_repository.this) == 0
    error_message = "No repositories should be created when var.repositories is empty"
  }
}

run "validate_repository_creation" {
  command = plan

  variables {
    repositories = {
      npm-store = {
        description = "npm store repository"
      }
    }
  }

  assert {
    condition     = aws_codeartifact_repository.this["npm-store"].repository == "npm-store"
    error_message = "Repository name should match the map key"
  }

  assert {
    condition     = aws_codeartifact_repository.this["npm-store"].description == "npm store repository"
    error_message = "Repository description should match the configured value"
  }
}

run "validate_repository_upstream" {
  command = plan

  variables {
    repositories = {
      npm-store = {
        description = "npm store repository"
      }
      npm-proxy = {
        description = "npm proxy repository"
        upstreams   = ["npm-store"]
      }
    }
  }

  assert {
    condition     = tolist(aws_codeartifact_repository.this["npm-proxy"].upstream)[0].repository_name == "npm-store"
    error_message = "Upstream repository_name should match the configured upstream"
  }
}

run "validate_repository_external_connection" {
  command = plan

  variables {
    repositories = {
      npm-store = {
        description         = "npm store repository"
        external_connection = "public:npmjs"
      }
    }
  }

  assert {
    condition     = tolist(aws_codeartifact_repository.this["npm-store"].external_connections)[0].external_connection_name == "public:npmjs"
    error_message = "External connection name should match the configured value"
  }
}

run "validate_multiple_repositories" {
  command = plan

  variables {
    repositories = {
      npm-store    = { description = "npm store" }
      python-store = { description = "python store" }
      maven-store  = { description = "maven store" }
    }
  }

  assert {
    condition     = length(aws_codeartifact_repository.this) == 3
    error_message = "All repositories defined in var.repositories should be created"
  }
}
