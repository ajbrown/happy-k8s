# Example: Separate file for organizing deployments
# You can split your agents across multiple .tf files for organization
#
# This file shows an alternative way to define agents using locals
# instead of the `agents` variable, which can be useful for:
# - Better IDE support with type checking
# - Splitting large configurations across files
# - Per-team or per-project organization

locals {
  # Team A's repositories
  team_a_agents = {
    "team-a-frontend" = {
      repository_url    = "https://github.com/your-org/team-a-frontend.git"
      repository_branch = "main"
      namespace         = "happy-k8s-team-a"
      replica_count     = 2
      git_email         = "claude@team-a.your-org.com"
      git_name          = "Claude Agent (Team A)"
    }

    "team-a-backend" = {
      repository_url    = "https://github.com/your-org/team-a-backend.git"
      repository_branch = "main"
      namespace         = "happy-k8s-team-a"
      replica_count     = 2
      git_email         = "claude@team-a.your-org.com"
      git_name          = "Claude Agent (Team A)"
    }
  }

  # Team B's repositories
  team_b_agents = {
    "team-b-service" = {
      repository_url    = "https://github.com/your-org/team-b-service.git"
      repository_branch = "develop"
      namespace         = "happy-k8s-team-b"
      replica_count     = 1
      git_email         = "claude@team-b.your-org.com"
      git_name          = "Claude Agent (Team B)"
    }
  }

  # Merge all team agents (can be used to override the `agents` variable)
  # all_agents = merge(local.team_a_agents, local.team_b_agents)
}

# If you want to use locals instead of variables, you can create modules directly:
#
# module "team_a_agents" {
#   source   = "../modules/claude-agent"
#   for_each = local.team_a_agents
#
#   release_name       = each.key
#   namespace          = each.value.namespace
#   repository_url     = each.value.repository_url
#   repository_branch  = each.value.repository_branch
#   replica_count      = each.value.replica_count
#   git_email          = each.value.git_email
#   git_name           = each.value.git_name
#   claude_credentials = var.claude_credentials
#   git_pat            = var.git_pat
#   chart_path         = "${path.module}/../helm/happy-k8s"
# }
