# Provider configuration

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use from kubeconfig"
  type        = string
  default     = null
}

# Shared credentials (used by all deployments unless overridden)

variable "claude_credentials" {
  description = "Default Claude/Happy credentials JSON for all agents (deprecated, use claude_max_token instead)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "claude_max_token" {
  description = "Claude Max/Pro long-lived token from 'claude setup-token' (preferred over claude_credentials)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "git_pat" {
  description = "Default GitHub PAT for all agents"
  type        = string
  sensitive   = true
}

# Image configuration (shared across deployments)

variable "image_repository" {
  description = "Docker image repository for happy-k8s"
  type        = string
  default     = "ghcr.io/ajbrown/happy-k8s"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

# Agent deployments configuration

variable "agents" {
  description = "Map of agent deployments to create"
  type = map(object({
    repository_url    = string
    repository_branch = optional(string, "main")
    namespace         = optional(string, "happy-k8s")
    replica_count     = optional(number, 2)
    git_email         = optional(string, "claude@example.com")
    git_name          = optional(string, "Claude Agent")
    env               = optional(map(string), {})

    # Override credentials per-agent if needed
    claude_credentials = optional(string)
    claude_max_token   = optional(string)
    git_pat            = optional(string)

    # Happy configuration
    happy_access_key                   = optional(string, "")
    happy_settings                     = optional(string, "")
    happy_no_qr                        = optional(bool, true)
    happy_server_url                   = optional(string, "")
    happy_working_dir                  = optional(string, "/workspace/repo")
    happy_yolo                         = optional(bool, true)
    happy_dangerously_skip_permissions = optional(bool, true)
    happy_continue_session             = optional(bool, true)
    happy_debug                        = optional(bool, false)

    # Network policy
    network_policy_create = optional(bool, false)

    # Claude plugins
    plugins = optional(list(string), [])

    # Resource configuration
    resource_limits_cpu      = optional(string, "2")
    resource_limits_memory   = optional(string, "2Gi")
    resource_requests_cpu    = optional(string, "100m")
    resource_requests_memory = optional(string, "256Mi")

    # Storage
    persistence_enabled       = optional(bool, true)
    persistence_storage_class = optional(string, "")
    persistence_size          = optional(string, "10Gi")

    # Scheduling
    node_selector = optional(map(string), {})
    tolerations = optional(list(object({
      key      = string
      operator = string
      value    = optional(string)
      effect   = string
    })), [])
  }))
  default = {}
}
