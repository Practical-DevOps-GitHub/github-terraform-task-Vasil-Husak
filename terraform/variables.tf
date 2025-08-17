variable "github_token" {
  type        = string
  description = "GitHub PAT"
}

variable "repo_owner" {
  type        = string
  description = "GitHub repo owner"
}

variable "repo_name" {
  type        = string
  description = "GitHub repo name"
}

variable "deploy_public_key_path" {
  type        = string
  description = "Path to deploy key public part"
}
