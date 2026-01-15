# Deploy Claude agents for each configured repository

module "claude_agent" {
  source   = "./modules/claude-agent"
  for_each = var.agents

  release_name = each.key
  namespace    = each.value.namespace

  # Repository configuration
  repository_name   = each.key  # Use the key as the repository name
  repository_url    = each.value.repository_url
  repository_branch = each.value.repository_branch

  # Credentials - use per-agent override if provided, otherwise use shared credentials
  # claude_max_token is preferred over claude_credentials
  claude_max_token   = try(coalesce(each.value.claude_max_token, var.claude_max_token), "")
  claude_credentials = try(coalesce(each.value.claude_credentials, var.claude_credentials), "")
  git_pat            = coalesce(each.value.git_pat, var.git_pat)

  # Additional environment variables
  env = each.value.env

  # Git identity
  git_email = each.value.git_email
  git_name  = each.value.git_name

  # Scaling
  replica_count = each.value.replica_count

  # Image configuration (shared)
  image_repository = var.image_repository
  image_tag        = var.image_tag

  # Resources
  resource_limits_cpu      = each.value.resource_limits_cpu
  resource_limits_memory   = each.value.resource_limits_memory
  resource_requests_cpu    = each.value.resource_requests_cpu
  resource_requests_memory = each.value.resource_requests_memory

  # Storage
  persistence_enabled       = each.value.persistence_enabled
  persistence_storage_class = each.value.persistence_storage_class
  persistence_size          = each.value.persistence_size

  # Scheduling
  node_selector = each.value.node_selector
  tolerations   = each.value.tolerations

  # Happy configuration
  happy_access_key                   = each.value.happy_access_key
  happy_settings                     = each.value.happy_settings
  happy_no_qr                        = each.value.happy_no_qr
  happy_server_url                   = each.value.happy_server_url
  happy_working_dir                  = each.value.happy_working_dir
  happy_yolo                         = each.value.happy_yolo
  happy_dangerously_skip_permissions = each.value.happy_dangerously_skip_permissions
  happy_continue_session             = each.value.happy_continue_session
  happy_debug                        = each.value.happy_debug

  # Network policy
  network_policy_create = each.value.network_policy_create

  # Chart location (helm directory is at parent level of terraform)
  chart_path = "${path.module}/../helm/happy-k8s"
}
