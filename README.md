# Core Cloud CodeArtifact Module

This CodeArtifact Child Module is written and maintained by the Core Cloud Platform team and includes the following checks and scans:
Terraform validate, Terraform fmt, TFLint, Checkov scan, Sonarqube scan and Semantic versioning - MAJOR.MINOR.PATCH.

## Module Structure

<strong>---| .github</strong>  
&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [dependabot.yaml](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/.github/dependabot.yaml)</strong> - Checks repository daily for any dependency updates and raises a PR into main for review.  \
&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| workflows</strong> \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-sast.yaml](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/.github/workflows/pull-request-sast.yaml)</strong> - Workflow containing terraform init, terraform validate, terraform fmt - referencing Core Cloud TFLint, Checkov scan and Sonarqube scan shared workflows. Runs on pull request and merge to main branch. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-semver-label-check.yaml](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/.github/workflows/pull-request-semver-label-check.yaml)</strong> - Verifies all PRs to main raised in the module must have an appropriate semver label: major/minor/patch. \
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>---| [pull-request-semver-tag-merge.yaml](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/.github/workflows/pull-request-semver-tag-merge.yaml)</strong> - Calculates the new semver value depending on the PR label and tags the repository with the correct tag. \
<strong>---| tests</strong> \
&nbsp;&nbsp;<strong>---| [codeartifact_basic.tftest.hcl](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/tests/codeartifact_basic.tftest.hcl)</strong> \
&nbsp;&nbsp;<strong>---| [codeartifact_security.tftest.hcl](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/tests/codeartifact_security.tftest.hcl)</strong> \
&nbsp;&nbsp;<strong>---| [codeartifact_tagging.tftest.hcl](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/tests/codeartifact_tagging.tftest.hcl)</strong> \
<strong>---| [CHANGELOG.md](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/CHANGELOG.md)</strong> - Contains all significant changes in relation to a semver tag made to this module. \
<strong>---| [CODEOWNERS](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/CODEOWNERS)</strong> \
<strong>---| [CONTRIBUTING.md](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/LICENSE.md)</strong>  \
<strong>---| [LICENSE.md](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/LICENSE.md)</strong>  \
<strong>---| [README.md](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/README.md)</strong>  \
<strong>---| [locals.tf](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/locals.tf)</strong> - Contains common tag merging and KMS key selection logic for the domain.  \
<strong>---| [main.tf](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/main.tf)</strong> - Contains the main set of configuration for this module.  \
<strong>---| [outputs.tf](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/outputs.tf)</strong> - Contain the output definitions for this module.  \
<strong>---| [variables.tf](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/variables.tf)</strong> - Contains the declarations for module variables, all variables have a defined type and short description outlining their purpose.  \
<strong>---| [versions.tf](https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module/blob/main/versions.tf)</strong> - Contains the providers needed by the module.  

## Terraform Tests

All module tests are located in the test/ folder and uses Terraform test. These are written and maintained by the Core Cloud QA team.  \
The test files found in this folder validate the CodeArtifact module configuration.  \
Please refer to the [Official Hashicorp Terraform Test documentation](https://developer.hashicorp.com/terraform/language/tests).

## Usage

This module will create the following:
- A CodeArtifact domain.
- A CodeArtifact repository, with the option of selecting an upstream connection like `public:npmjs`.
- A KMS key, alias and key policy (only when a customer-managed key is requested).

Recommended settings:

- Adhere to Core Cloud mandatory tags
- Use a customer-managed KMS key (`kms_key_type = "CUSTOMER_MANAGED"`) where the domain requires auditable, account-scoped key control
- Chain repositories via `upstreams` rather than duplicating external connections on every repository

See the below example configuration (We recommend one file per environment containing all CodeArtifact resources using this module):

```
terraform {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-codeartifact-tf-module.git?ref={tag}"
}

inputs = {
  domain_name  = "my-project-artifacts"
  project_name = "my-project"
  environment  = "test"
  account_id   = "xxxxxxxxxxxx"
  source-repo  = "github.com/Home-Office-Digital/my-project-terragrunt"

  # AWS_MANAGED (default) uses the AWS-owned aws/codeartifact key.
  # CUSTOMER_MANAGED either creates a module-managed key, or reuses
  # customer_managed_kms_key_arn if supplied.
  kms_key_type = "CUSTOMER_MANAGED"
  kms_alias    = "my-project-codeartifact-kms-key"

  repositories = {
    example-npm-store = {
      description = "A repository for storing npm packages"
    }
    example-npm-proxy = {
      description         = "A proxy repository with upstream and a public npm connection"
      upstreams            = ["npm-store"]
      external_connection = "public:npmjs"
    }
  }

  # Tags for all resources
  tags = {
    Environment      = "test"
    Project           = "my-project"
    cost-centre       = "xxx"
    account-code      = "xxx"
    portfolio-id      = "xxx"
    project-id        = "xxx"
    service-id        = "xxx"
    environment-type  = "xxx"
    owner-business    = "xxx"
    budget-holder     = "xxx"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.88.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.88.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_codeartifact_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codeartifact_domain) | resource |
| [aws_codeartifact_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codeartifact_repository) | resource |
| [aws_kms_key.codeartifact](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.codeartifact](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_alias.codeartifact](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the CodeArtifact domain to create | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | `""` | no |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS Account ID for the KMS key policy | `string` | n/a | yes |
| <a name="input_source-repo"></a> [source-repo](#input\_source-repo) | The GitHub repository that made the AWS CodeArtifact resources | `string` | n/a | yes |
| <a name="input_kms_key_type"></a> [kms\_key\_type](#input\_kms\_key\_type) | Type of KMS key used to encrypt the domain. Either 'AWS\_MANAGED' (uses the AWS owned aws/codeartifact key) or 'CUSTOMER\_MANAGED'. | `string` | `"AWS_MANAGED"` | no |
| <a name="input_customer_managed_kms_key_arn"></a> [customer\_managed\_kms\_key\_arn](#input\_customer\_managed\_kms\_key\_arn) | ARN of an existing customer-managed KMS key to encrypt the domain. Only used when kms\_key\_type is 'CUSTOMER\_MANAGED'. If left null, the module creates its own KMS key. | `string` | `null` | no |
| <a name="input_kms_alias"></a> [kms\_alias](#input\_kms\_alias) | KMS key alias suffix used when the module creates its own customer-managed KMS key (i.e. kms\_key\_type is 'CUSTOMER\_MANAGED' and customer\_managed\_kms\_key\_arn is null). The 'alias/' prefix is added automatically. | `string` | `"codeartifact"` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Map of CodeArtifact repositories to create in the domain, keyed by repository name | <pre>map(object({<br/>    description         = optional(string)<br/>    upstreams           = optional(list(string), [])<br/>    external_connection = optional(string)<br/>    tags                = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources. Must include Environment, Project, cost-centre, account-code, portfolio-id, project-id and service-id | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The name of the CodeArtifact domain |
| <a name="output_domain_arn"></a> [domain\_arn](#output\_domain\_arn) | The ARN of the CodeArtifact domain |
| <a name="output_domain_owner"></a> [domain\_owner](#output\_domain\_owner) | The AWS account ID that owns the CodeArtifact domain |
| <a name="output_domain_encryption_key"></a> [domain\_encryption\_key](#output\_domain\_encryption\_key) | The KMS key ARN used to encrypt the domain (null when using the AWS-managed key) |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the customer-managed KMS key used by the domain, if any |
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | Map of repository name to repository ARN |
| <a name="output_repository_admins"></a> [repository\_admins](#output\_repository\_admins) | Map of repository name to the AWS account ID that administers the repository |

