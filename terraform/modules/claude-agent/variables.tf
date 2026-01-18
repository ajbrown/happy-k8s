# Required variables

variable "release_name" {
  description = "Name for the Helm release (used as prefix for all resources)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "repository_url" {
  description = "Git repository URL (e.g., https://github.com/org/repo.git)"
  type        = string
}

variable "repository_name" {
  description = "Repository name (used for metrics labels and identification)"
  type        = string
}

variable "claude_credentials" {
  description = "Contents of ~/.claude/.credentials.json for Happy/Claude authentication (deprecated)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "claude_max_token" {
  description = "Claude Max/Pro long-lived token from 'claude setup-token' (preferred)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "git_pat" {
  description = "GitHub Personal Access Token with repo access"
  type        = string
  sensitive   = true
}

# Optional variables with defaults

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "repository_branch" {
  description = "Git branch to checkout"
  type        = string
  default     = "main"
}

variable "replica_count" {
  description = "Number of agent replicas to run"
  type        = number
  default     = 2
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "ghcr.io/ajbrown/happy-k8s"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Image pull policy (Always, IfNotPresent, Never)"
  type        = string
  default     = "Always"
}

variable "env" {
  description = "Additional environment variables to set in the container"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "git_email" {
  description = "Git author/committer email for commits made by the agent"
  type        = string
  default     = "claude@example.com"
}

variable "git_name" {
  description = "Git author/committer name for commits made by the agent"
  type        = string
  default     = "Claude Agent"
}

variable "resource_limits_cpu" {
  description = "CPU limit for each agent pod"
  type        = string
  default     = "2"
}

variable "resource_limits_memory" {
  description = "Memory limit for each agent pod"
  type        = string
  default     = "2Gi"
}

variable "resource_requests_cpu" {
  description = "CPU request for each agent pod"
  type        = string
  default     = "100m"
}

variable "resource_requests_memory" {
  description = "Memory request for each agent pod"
  type        = string
  default     = "256Mi"
}

variable "persistence_enabled" {
  description = "Enable persistent storage (disable for clusters without dynamic provisioning)"
  type        = bool
  default     = true
}

variable "persistence_storage_class" {
  description = "Storage class for persistent volumes (empty string uses cluster default)"
  type        = string
  default     = ""
}

variable "persistence_size" {
  description = "Size of persistent volume per pod"
  type        = string
  default     = "10Gi"
}

variable "pdb_enabled" {
  description = "Enable PodDisruptionBudget"
  type        = bool
  default     = true
}

variable "pdb_min_available" {
  description = "Minimum number of pods that must be available"
  type        = number
  default     = 1
}

variable "termination_grace_period" {
  description = "Termination grace period in seconds"
  type        = number
  default     = 300
}

variable "node_selector" {
  description = "Node selector for pod placement"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for pod scheduling"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

variable "chart_path" {
  description = "Path to the Helm chart (relative to Terraform root or absolute)"
  type        = string
  default     = "../../helm/happy-k8s"
}

# Happy configuration

variable "happy_access_key" {
  description = "Contents of ~/.happy/access.key for pre-configured authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "happy_settings" {
  description = "Contents of ~/.happy/settings.json for pre-configured authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "happy_no_qr" {
  description = "Use --no-qr flag for headless pairing (shows text code in logs)"
  type        = bool
  default     = true
}

variable "happy_server_url" {
  description = "Custom Happy server URL (for self-hosted setups)"
  type        = string
  default     = ""
}

variable "happy_working_dir" {
  description = "Working directory to run Happy from (typically the repository root)"
  type        = string
  default     = "/workspace/repo"
}

variable "happy_yolo" {
  description = "Enable yolo mode (--yolo flag) - allows Claude to run without confirmations"
  type        = bool
  default     = true
}

variable "happy_dangerously_skip_permissions" {
  description = "Skip permission checks (--dangerously-skip-permissions flag)"
  type        = bool
  default     = true
}

variable "happy_continue_session" {
  description = "Continue from previous session (--continue flag)"
  type        = bool
  default     = true
}

variable "happy_debug" {
  description = "Enable debug logging for Happy (sets DEBUG=1 environment variable)"
  type        = bool
  default     = false
}

# Network policy configuration

variable "network_policy_create" {
  description = "Create a NetworkPolicy for the pods (useful if cluster has default-deny)"
  type        = bool
  default     = false
}

# Claude plugins configuration

variable "plugins" {
  description = "List of Claude plugins to install (supports both MCP plugins and Claude plugins)"
  type        = list(string)
  default     = []
}
