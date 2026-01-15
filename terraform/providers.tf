# Kubernetes provider configuration
# Configure these based on your cluster access method

provider "kubernetes" {
  # Option 1: Use kubeconfig file (default)
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context

  # Option 2: Direct cluster access (uncomment and configure if needed)
  # host                   = var.cluster_endpoint
  # cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  # token                  = var.cluster_token
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context

    # Option 2: Direct cluster access (uncomment and configure if needed)
    # host                   = var.cluster_endpoint
    # cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    # token                  = var.cluster_token
  }
}
