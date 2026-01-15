output "deployments" {
  description = "Information about all deployed Claude agents"
  value = {
    for name, agent in module.claude_agent : name => {
      release_name   = agent.release_name
      namespace      = agent.namespace
      release_status = agent.release_status
      statefulset    = agent.statefulset_name
      pods           = agent.pod_names
    }
  }
}

output "namespaces" {
  description = "Unique namespaces where agents are deployed"
  value       = distinct([for agent in module.claude_agent : agent.namespace])
}
