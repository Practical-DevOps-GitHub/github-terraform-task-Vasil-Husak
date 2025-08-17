terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.repo_owner
}

# Репозиторій
data "github_repository" "repo" {
  name = var.repo_name
}

# Collaborator
resource "github_repository_collaborator" "collab" {
  repository = data.github_repository.repo.name
  username   = "softservedata"
  permission = "push"
}

# Гілка develop (якщо ще нема)
resource "github_branch" "develop" {
  repository = data.github_repository.repo.name
  branch     = "develop"
}

# Default branch = develop
resource "github_branch_default" "default" {
  repository = data.github_repository.repo.name
  branch     = github_branch.develop.branch
  depends_on = [github_branch.develop]
}

# Protect main branch
resource "github_branch_protection" "main" {
  repository_id  = data.github_repository.repo.node_id
  pattern        = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
    require_code_owner_reviews      = true
  }

  allows_deletions = false
  allows_force_pushes = false
  enforce_admins = true
}

# Protect develop branch  
resource "github_branch_protection" "develop" {
  repository_id  = data.github_repository.repo.node_id
  pattern        = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2
  }

  allows_deletions = false
  allows_force_pushes = false
  enforce_admins = true
  depends_on = [github_branch.develop]
}

# Deploy key
resource "github_repository_deploy_key" "deploy" {
  repository = data.github_repository.repo.name
  title      = "DEPLOY_KEY"
  key        = file(var.deploy_public_key_path)
  read_only  = true
}

# Pull Request Template
resource "github_repository_file" "pr_template" {
  repository     = data.github_repository.repo.name
  branch         = "main"
  file           = ".github/pull_request_template.md"
  content        = <<-EOF
## Describe your changes


## Issue ticket number and link


## Checklist before requesting a review

- [ ] I have performed a self-review of my code
- [ ] If it is a core feature, I have added thorough tests
- [ ] Do we need to implement analytics?
- [ ] Will this be part of a product update?

## If yes, please write one phrase about this update

EOF
  commit_message = "Add pull request template"
  commit_author  = "Terraform"
  commit_email   = "terraform@example.com"
}

resource "github_repository_webhook" "discord" {
  count      = var.discord_webhook_url != "" ? 1 : 0
  repository = data.github_repository.repo.name

  configuration {
    url          = var.discord_webhook_url
    content_type = "json"
  }

  active = true

  events = ["pull_request"]