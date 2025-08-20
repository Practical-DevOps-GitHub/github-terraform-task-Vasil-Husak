variable "github_owner" {
  type        = string
  description = "GitHub owner or organization that hosts the repository"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token with repo and admin:repo_hook scopes (read from secret/environment)"
}

variable "deploy_key_public" {
  type        = string
  sensitive   = true
  description = "Public SSH key value for the DEPLOY_KEY (ssh-rsa/ecdsa/ed25519 ...)"
}

variable "discord_webhook_url" {
  type        = string
  sensitive   = true
  description = "Discord channel webhook URL to receive PR notifications"
}

variable "pat" {
  type        = string
  sensitive   = true
  description = "PAT to store in GitHub Actions secret named PAT"
}
