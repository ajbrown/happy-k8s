terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

# Create namespace if requested
resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "happy-k8s"
    }
  }
}

# Deploy the Helm chart
resource "helm_release" "claude_agent" {
  name      = var.release_name
  namespace = var.namespace
  chart     = var.chart_path

  # Wait for namespace to be created if we're managing it
  depends_on = [kubernetes_namespace.this]

  # Core configuration
  set {
    name  = "replicaCount"
    value = var.replica_count
  }

  # Image configuration
  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "image.pullPolicy"
    value = var.image_pull_policy
  }

  # Repository configuration
  set {
    name  = "repository.name"
    value = var.repository_name
  }

  set {
    name  = "repository.url"
    value = var.repository_url
  }

  set {
    name  = "repository.branch"
    value = var.repository_branch
  }

  set {
    name  = "repository.clonePath"
    value = var.happy_working_dir
  }

  # Credentials and sensitive values using YAML values block
  # This handles complex JSON with special characters better than set_sensitive
  values = [
    yamlencode({
      credentials = {
        claudeMaxToken = var.claude_max_token
        claude         = var.claude_credentials
        gitPat         = var.git_pat
      }
      happy = {
        accessKey = var.happy_access_key
        settings  = var.happy_settings
      }
      env = var.env
    })
  ]

  # Git identity
  set {
    name  = "git.email"
    value = var.git_email
  }

  set {
    name  = "git.name"
    value = var.git_name
  }

  # Resource limits
  set {
    name  = "resources.limits.cpu"
    value = var.resource_limits_cpu
  }

  set {
    name  = "resources.limits.memory"
    value = var.resource_limits_memory
  }

  set {
    name  = "resources.requests.cpu"
    value = var.resource_requests_cpu
  }

  set {
    name  = "resources.requests.memory"
    value = var.resource_requests_memory
  }

  # Persistence
  set {
    name  = "persistence.enabled"
    value = var.persistence_enabled
  }

  set {
    name  = "persistence.storageClass"
    value = var.persistence_storage_class
  }

  set {
    name  = "persistence.size"
    value = var.persistence_size
  }

  # PodDisruptionBudget
  set {
    name  = "podDisruptionBudget.enabled"
    value = var.pdb_enabled
  }

  set {
    name  = "podDisruptionBudget.minAvailable"
    value = var.pdb_min_available
  }

  # Termination grace period
  set {
    name  = "terminationGracePeriodSeconds"
    value = var.termination_grace_period
  }

  # Node selector
  dynamic "set" {
    for_each = var.node_selector
    content {
      name  = "nodeSelector.${set.key}"
      value = set.value
    }
  }

  # Tolerations
  dynamic "set" {
    for_each = { for idx, t in var.tolerations : idx => t }
    content {
      name  = "tolerations[${set.key}].key"
      value = set.value.key
    }
  }

  dynamic "set" {
    for_each = { for idx, t in var.tolerations : idx => t }
    content {
      name  = "tolerations[${set.key}].operator"
      value = set.value.operator
    }
  }

  dynamic "set" {
    for_each = { for idx, t in var.tolerations : idx => t if t.value != null }
    content {
      name  = "tolerations[${set.key}].value"
      value = set.value.value
    }
  }

  dynamic "set" {
    for_each = { for idx, t in var.tolerations : idx => t }
    content {
      name  = "tolerations[${set.key}].effect"
      value = set.value.effect
    }
  }

  # Happy configuration
  set {
    name  = "happy.noQr"
    value = var.happy_no_qr
  }

  set {
    name  = "happy.serverUrl"
    value = var.happy_server_url
  }

  # Note: happy.accessKey and happy.settings are passed via values_sensitive above

  set {
    name  = "happy.workingDir"
    value = var.happy_working_dir
  }

  set {
    name  = "happy.yolo"
    value = var.happy_yolo
  }

  set {
    name  = "happy.dangerouslySkipPermissions"
    value = var.happy_dangerously_skip_permissions
  }

  set {
    name  = "happy.continueSession"
    value = var.happy_continue_session
  }

  set {
    name  = "happy.debug"
    value = var.happy_debug
  }

  # Network policy
  set {
    name  = "networkPolicy.create"
    value = var.network_policy_create
  }

  # Wait for deployment to be ready
  wait    = true
  timeout = 600
}
