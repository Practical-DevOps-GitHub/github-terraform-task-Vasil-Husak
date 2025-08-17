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
}

# Protect main branch
resource "github_branch_protection" "main" {
  repository_id  = data.github_repository.repo.node_id
  pattern        = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
    require_code_owner_reviews      = true
  }
}

# Protect develop branch
resource "github_branch_protection" "develop" {
  repository_id  = data.github_repository.repo.node_id
  pattern        = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2
  }
}

# Deploy key
resource "github_repository_deploy_key" "deploy" {
  repository = data.github_repository.repo.name
  title      = "DEPLOY_KEY"
  key        = file(var.deploy_public_key_path)
  read_only  = true
}
