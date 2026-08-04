All notable changes to this project will be documented in this file. This will provide a record of all notable module updates with each new release. Semantic versioning (https://semver.org/) must be adhered to for all Core Cloud modules.

eg:

### [0.0.1] 2026-07-28

  * Initial tag created for the Core Cloud CodeArtifact Terraform module

### [1.0.1] 2026-08-04

  * Fixed `aws_codeartifact_repository` creation ordering: repositories that declare `upstreams` are now created in a separate resource from the repositories they reference, so Terraform can build a real dependency edge instead of relying on a plain string match. Previously the first `apply` after adding an upstream reference could fail because the referenced repository didn't exist yet, requiring a second `apply` to succeed.
  * Added a validation on `repositories` requiring that `upstreams` entries reference a repository with no upstreams of its own (single-level chaining only).
