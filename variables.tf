variable "domain_name" {
  description = "Name of the CodeArtifact domain to create"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "AWS Account ID for the KMS key policy"
  type        = string
}

variable "source-repo" {
  description = "The GitHub repository that made the AWS CodeArtifact resources"
  type        = string
}

variable "kms_key_type" {
  description = "Type of KMS key used to encrypt the domain. Either 'AWS_MANAGED' (uses the AWS owned aws/codeartifact key) or 'CUSTOMER_MANAGED'."
  type        = string
  default     = "AWS_MANAGED"

  validation {
    condition     = contains(["AWS_MANAGED", "CUSTOMER_MANAGED"], var.kms_key_type)
    error_message = "kms_key_type must be either 'AWS_MANAGED' or 'CUSTOMER_MANAGED'."
  }
}

variable "customer_managed_kms_key_arn" {
  description = "ARN of an existing customer-managed KMS key to encrypt the domain. Only used when kms_key_type is 'CUSTOMER_MANAGED'. If left null, the module creates its own KMS key."
  type        = string
  default     = null
}

variable "kms_alias" {
  description = "KMS key alias suffix used when the module creates its own customer-managed KMS key (i.e. kms_key_type is 'CUSTOMER_MANAGED' and customer_managed_kms_key_arn is null). The 'alias/' prefix is added automatically."
  type        = string
  default     = "codeartifact"
}

variable "repositories" {
  description = "Map of CodeArtifact repositories to create in the domain, keyed by repository name"
  type = map(object({
    description         = optional(string)
    upstreams           = optional(list(string), [])
    external_connection = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Project"),
      contains(keys(var.tags), "cost-centre"),
      contains(keys(var.tags), "account-code"),
      contains(keys(var.tags), "portfolio-id"),
      contains(keys(var.tags), "project-id"),
      contains(keys(var.tags), "service-id")
    ])
    error_message = "Tags must include all mandatory fields."
  }
}
