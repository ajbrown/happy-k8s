output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.claude_agent.name
}

output "namespace" {
  description = "Namespace where the agent is deployed"
  value       = helm_release.claude_agent.namespace
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.claude_agent.status
}

output "release_revision" {
  description = "Revision of the Helm release"
  value       = helm_release.claude_agent.version
}

output "statefulset_name" {
  description = "Name of the StatefulSet"
  value       = "${var.release_name}-happy-k8s"
}

output "pod_names" {
  description = "Expected pod names (based on StatefulSet naming)"
  value       = [for i in range(var.replica_count) : "${var.release_name}-happy-k8s-${i}"]
}
