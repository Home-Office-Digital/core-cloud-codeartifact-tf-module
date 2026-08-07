# Cross-account resource-based policy validation for CodeArtifact
#
# Assertions target local.domain_policy_statements / local.repository_policy_statements
# (the fully-resolved statement lists, including the auto-injected aws:PrincipalOrgID
# condition) rather than data.aws_iam_policy_document.*.json. The rendered .json
# depends on aws_codeartifact_domain.this.arn / repository ARNs, which are unknown
# until apply - asserting on it turns every one of these into an apply-only test for
# no benefit, since the actual logic under test (principal/action/condition
# resolution) lives entirely in the locals, upstream of anything AWS-assigned.

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

run "validate_no_domain_policy_by_default" {
  command = plan

  assert {
    condition     = length(aws_codeartifact_domain_permissions_policy.this) == 0
    error_message = "No domain permissions policy should be created when domain_permissions_policy is empty"
  }
}

run "validate_domain_policy_created" {
  command = plan

  variables {
    domain_permissions_policy = [
      {
        sid        = "AllowCrossAccountAuth"
        principals = ["arn:aws:iam::123456789012:root"]
        actions    = ["codeartifact:GetAuthorizationToken"]
      }
    ]
  }

  assert {
    condition     = length(aws_codeartifact_domain_permissions_policy.this) == 1
    error_message = "A domain permissions policy should be created when domain_permissions_policy is set"
  }

  assert {
    condition     = contains(local.domain_policy_statements[0].principals, "arn:aws:iam::123456789012:root")
    error_message = "The resolved domain policy statement should contain the configured principal"
  }

  assert {
    condition     = contains(local.domain_policy_statements[0].actions, "codeartifact:GetAuthorizationToken")
    error_message = "The resolved domain policy statement should contain the configured action"
  }
}

run "validate_no_repository_policy_by_default" {
  command = plan

  variables {
    repositories = {
      npm-store = {
        description = "npm store repository"
      }
    }
  }

  assert {
    condition     = length(aws_codeartifact_repository_permissions_policy.this) == 0
    error_message = "No repository permissions policy should be created when repository_permissions_policies is empty"
  }
}

run "validate_repository_policy_created" {
  command = plan

  variables {
    repositories = {
      npm-store = {
        description = "npm store repository"
      }
    }

    repository_permissions_policies = {
      npm-store = [
        {
          sid        = "AllowCrossAccountPull"
          principals = ["arn:aws:iam::123456789012:root"]
          actions    = ["codeartifact:ReadFromRepository", "codeartifact:GetRepositoryEndpoint"]
        }
      ]
    }
  }

  assert {
    condition     = length(aws_codeartifact_repository_permissions_policy.this) == 1
    error_message = "A repository permissions policy should be created for the configured repository"
  }

  assert {
    condition     = aws_codeartifact_repository_permissions_policy.this["npm-store"].repository == "npm-store"
    error_message = "The repository permissions policy should target the configured repository"
  }

  assert {
    condition     = contains(local.repository_policy_statements["npm-store"][0].actions, "codeartifact:ReadFromRepository")
    error_message = "The resolved repository policy statement should contain the configured action"
  }
}

run "validate_domain_policy_rejects_invalid_effect" {
  command = plan

  variables {
    domain_permissions_policy = [
      {
        effect     = "Permit"
        principals = ["arn:aws:iam::123456789012:root"]
        actions    = ["codeartifact:GetAuthorizationToken"]
      }
    ]
  }

  expect_failures = [var.domain_permissions_policy]
}

run "validate_wildcard_domain_principal_gets_org_id_condition" {
  command = plan

  override_data {
    target = data.aws_organizations_organization.current
    values = {
      id = "o-exampleorgid12"
    }
  }

  variables {
    domain_permissions_policy = [
      {
        sid        = "AllowOrgWideAuth"
        principals = ["*"]
        actions    = ["codeartifact:GetAuthorizationToken"]
        conditions = [
          {
            test     = "StringLike"
            variable = "aws:PrincipalArn"
            values   = ["arn:aws:iam::*:role/cc-bootstrap-example-role"]
          }
        ]
      }
    ]
  }

  assert {
    condition     = anytrue([for c in local.domain_policy_statements[0].conditions : c.variable == "aws:PrincipalOrgID"])
    error_message = "A \"*\" domain principal should automatically get an aws:PrincipalOrgID condition appended"
  }

  assert {
    condition     = anytrue([for c in local.domain_policy_statements[0].conditions : c.variable == "aws:PrincipalOrgID" && contains(c.values, "o-exampleorgid12")])
    error_message = "The auto-appended aws:PrincipalOrgID condition should use the resolved AWS Organization ID"
  }

  assert {
    condition     = anytrue([for c in local.domain_policy_statements[0].conditions : c.variable == "aws:PrincipalArn"])
    error_message = "The explicitly configured aws:PrincipalArn condition should still be present alongside the auto-appended one"
  }
}

run "validate_non_wildcard_domain_principal_has_no_org_id_condition" {
  command = plan

  variables {
    domain_permissions_policy = [
      {
        sid        = "AllowSpecificAccount"
        principals = ["arn:aws:iam::123456789012:root"]
        actions    = ["codeartifact:GetAuthorizationToken"]
      }
    ]
  }

  assert {
    condition     = length(data.aws_organizations_organization.current) == 0
    error_message = "A non-wildcard principal should never trigger an AWS Organization lookup"
  }

  assert {
    condition     = !anytrue([for c in local.domain_policy_statements[0].conditions : c.variable == "aws:PrincipalOrgID"])
    error_message = "A non-wildcard principal should not have an aws:PrincipalOrgID condition injected"
  }
}

run "validate_wildcard_repository_principal_gets_org_id_condition" {
  command = plan

  override_data {
    target = data.aws_organizations_organization.current
    values = {
      id = "o-exampleorgid12"
    }
  }

  variables {
    repositories = {
      npm-store = {
        description = "npm store repository"
      }
    }

    repository_permissions_policies = {
      npm-store = [
        {
          sid        = "AllowOrgWidePull"
          principals = ["*"]
          actions    = ["codeartifact:ReadFromRepository"]
          conditions = [
            {
              test     = "StringLike"
              variable = "aws:PrincipalArn"
              values   = ["arn:aws:iam::*:role/cc-bootstrap-example-role"]
            }
          ]
        }
      ]
    }
  }

  assert {
    condition     = anytrue([for c in local.repository_policy_statements["npm-store"][0].conditions : c.variable == "aws:PrincipalOrgID"])
    error_message = "A \"*\" repository principal should automatically get an aws:PrincipalOrgID condition appended"
  }
}
