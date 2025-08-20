terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

# === Locals block (matches the screenshot exactly) ===
locals {
  repo_name        = "github-terraform-task-solution"
  user_name        = "softservedata"
  pr_tmplt_content = <<EOT
## Describe your changes

## Issue ticket number and link

## Checklist before requesting a review
- [ ] I have performed a self-review of my code
- [ ] If it is a core feature, I have added thorough tests
- [ ] Do we need to implement analytics?
- [ ] Will this be part of a product update? If yes, please write one phrase about this update
EOT
}

# Repository lookup (node_id is required for branch protection API)
data "github_repository" "this" {
  full_name = "${var.github_owner}/${local.repo_name}"
}

# Add collaborator
resource "github_repository_collaborator" "collab" {
  repository = local.repo_name
  username   = local.user_name
  permission = "push"
}

# Create 'develop' branch from 'main' and set as default
resource "github_branch" "develop" {
  repository    = local.repo_name
  branch        = "develop"
  source_branch = "main"
}

resource "github_branch_default" "default" {
  repository = local.repo_name
  branch     = "develop"
  depends_on = [github_branch.develop]
}

# CODEOWNERS on main (code owner for all files)
resource "github_repository_file" "codeowners" {
  repository          = local.repo_name
  file                = "CODEOWNERS"
  content             = "* @${local.user_name}"
  branch              = "main"
  commit_message      = "Add CODEOWNERS for all files"
  overwrite_on_create = true
}

# PR template in .github/ on main
resource "github_repository_file" "pr_template" {
  repository          = local.repo_name
  file                = ".github/pull_request_template.md"
  content             = local.pr_tmplt_content
  branch              = "main"
  commit_message      = "Add PR template"
  overwrite_on_create = true
}

# Protect 'develop' (PR required, 2 approvals)
resource "github_branch_protection" "develop" {
  repository_id  = data.github_repository.this.node_id
  pattern        = "develop"
  enforce_admins = true

  required_pull_request_reviews {
    required_approving_review_count = 2
  }

  depends_on = [
    github_repository_file.codeowners,
    github_repository_file.pr_template,
    github_branch_default.default
  ]
}

# Protect 'main' (PR required, code owners must approve)
resource "github_branch_protection" "main" {
  repository_id  = data.github_repository.this.node_id
  pattern        = "main"
  enforce_admins = true

  required_pull_request_reviews {
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }

  depends_on = [
    github_repository_file.codeowners,
    github_repository_file.pr_template,
    github_branch_default.default
  ]
}

# Deploy key named DEPLOY_KEY
resource "github_repository_deploy_key" "deploy_key" {
  repository = local.repo_name
  title      = "DEPLOY_KEY"
  key        = var.deploy_key_public
  read_only  = false
}

# Discord notifications on PR events (expects Discord webhook URL in secret)
resource "github_repository_webhook" "discord" {
  repository = local.repo_name
  active     = true
  events     = ["pull_request"]

  configuration {
    url          = var.discord_webhook_url
    content_type = "json"
    insecure_ssl = false
  }
}

# Actions secrets
resource "github_actions_secret" "pat" {
  repository      = local.repo_name
  secret_name     = "PAT"
  plaintext_value = var.pat
}

# Store the Terraform source itself in a secret named TERRAFORM (as required)
resource "github_actions_secret" "terraform_code" {
  repository  = local.repo_name
  secret_name = "TERRAFORM"
  plaintext_value = base64encode(join("\n---\n", [
    file("${path.module}/main.tf"),
    file("${path.module}/variables.tf"),
    file("${path.module}/outputs.tf")
  ]))
}
