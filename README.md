# Happy for Kubernetes

> **AI pair programming from your phone** - Deploy Claude AI agents on Kubernetes, accessible anywhere via the Happy mobile app, with intelligent autoscaling that keeps one agent ready for instant response.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.24+-blue.svg)](https://kubernetes.io)
[![Helm](https://img.shields.io/badge/helm-v3-blue.svg)](https://helm.sh)
[![Happy](https://img.shields.io/badge/happy-engineering-blue.svg)](https://happy.engineering)

**Happy for Kubernetes** is a production-ready Kubernetes deployment for running [Claude Code](https://claude.ai/code) agents that you control from anywhere via the [Happy](https://happy.engineering) mobile app. Perfect for:

- **Solo developers** who want AI assistance on-the-go
- **Development teams** sharing AI agents across multiple repositories
- **Organizations** wanting secure, self-hosted AI development assistance

## ✨ Key Features

- 🚀 **Mobile Access** - Chat with Claude about your code from your phone
- 📦 **Persistent Agents** - Agents run 24/7 in Kubernetes, always ready to help
- 🔄 **Intelligent Autoscaling** - Automatically maintains one idle agent for instant response
- 🏗️ **Multi-Repository** - Deploy separate agents for each repository
- 🛠️ **Full Dev Environment** - Pre-installed tools: Node.js, Python, Docker, Maven, Git
- 🔐 **Secure** - Self-hosted on your infrastructure with proper isolation
- 📊 **Production-Ready** - Health checks, graceful shutdown, resource limits, monitoring

## 🎯 Why This Is Powerful

### Traditional Claude Code Limitations
- Must keep terminal open on your laptop
- Can't access when away from computer
- Single concurrent session per machine
- Manual process management

### With Claude Agents
- Access from anywhere via mobile app
- Multiple agents run concurrently
- Automatic scaling based on demand
- Always-available development assistance
- Share agents across team members
- Survives laptop reboots/network issues

### Real-World Use Cases

**On-the-Go Development**
```
You're at lunch and remember a bug. Pull out your phone, message your
Claude agent, and have it fix the issue and create a PR - all while
you're away from your desk.
```

**Multi-Repository Teams**
```
Deploy 5 agents across 5 repositories. Each team member can access
any agent via the Happy app. Autoscaling ensures there's always an
idle agent ready for instant response.
```

**Weekend Monitoring**
```
Get a production alert on Saturday. Message your agent from your phone
to investigate logs, identify the issue, and deploy a hotfix - no
laptop needed.
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (1.24+)
- `kubectl` and `helm` installed
- Claude Pro/Max subscription
- [Happy](https://happy.engineering) account (free via mobile app)
- GitHub PAT with repo access

### 1. Get Credentials

#### Claude Authentication

Generate a long-lived token (recommended for servers):

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Generate token (opens browser)
claude setup-token

# Copy the token (starts with sk-ant-oat01-...)
```

#### Happy Authentication

Authenticate via the Happy mobile app:

```bash
# Install Happy CLI
npm install -g happy-coder

# Run Happy (shows QR code)
happy

# In Happy mobile app:
# - Scan QR code or enter pairing code
# - Complete authentication

# Extract credentials
cat ~/.happy/access.key    # Copy this entire JSON
cat ~/.happy/settings.json  # Optional
```

### 2. Configure & Deploy

#### Option A: Terraform (Recommended for Multiple Repos)

```bash
cd terraform

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your credentials
nano terraform.tfvars

# Deploy
terraform init
terraform apply
```

**Example `terraform.tfvars`:**

```hcl
claude_max_token = "sk-ant-oat01-YOUR_TOKEN_HERE"
git_pat = "github_pat_YOUR_PAT_HERE"

agents = {
  "my-webapp" = {
    repository_url    = "https://github.com/yourorg/webapp"
    repository_branch = "main"
    namespace         = "happy-k8s"
    replica_count     = 2  # Autoscaling will manage this

    git_email = "claude@yourorg.com"
    git_name  = "Claude Agent"

    happy_access_key = <<-EOF
    {
      "encryption": {
        "publicKey": "YOUR_PUBLIC_KEY",
        "machineKey": "will-be-regenerated"
      },
      "token": "YOUR_HAPPY_TOKEN"
    }
    EOF
  }

  # Add more repositories here...
}
```

#### Option B: Helm (Direct Installation)

```bash
# Install for a single repository
helm install my-agent helm/happy-k8s \
  --set repository.name="my-repo" \
  --set repository.url="https://github.com/yourorg/repo" \
  --set credentials.claudeMaxToken="sk-ant-oat01-..." \
  --set credentials.gitPat="github_pat_..." \
  --set-file happy.accessKey=./access.key \
  --namespace happy-k8s \
  --create-namespace
```

### 3. Verify Deployment

```bash
# Check pods are running
kubectl get pods -n happy-k8s

# Should see:
# my-webapp-happy-k8s-0   2/2   Running   0   2m
# my-webapp-happy-k8s-1   2/2   Running   0   2m

# View startup logs
kubectl logs my-webapp-happy-k8s-0 -n happy-k8s

# Look for:
# ✓ Created Claude credentials from Max token
# ✓ Generated unique machineId
# ✓ Connection successful!
```

### 4. Use from Happy App

1. **Open Happy mobile app** - Your agents appear as online terminals
2. **Tap an agent** - Each repository shows as separate session
3. **Send a message**: `"List the files in this repository"`
4. **Claude responds** - It can read code, make changes, create commits

**Example conversation:**
```
You: Show me the recent commits
Claude: [Shows git log output]

You: There's a bug in api/users.ts where we're not validating emails.
     Can you fix it and create a PR?
Claude: I'll fix that now...
        [Creates fix, tests it, commits, pushes, creates PR]
        Done! Created PR #123 with the email validation fix.
```

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Happy Mobile App                      │
│                    (Your Phone/Tablet)                       │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ WebSocket
                             ▼
                   ┌──────────────────┐
                   │  Happy Server    │
                   │  (Cloud)         │
                   └────────┬─────────┘
                            │
                            │ Routes to pod by machineId
                            ▼
┌────────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ happy-k8s StatefulSet                            │  │
│  │                                                       │  │
│  │  ┌───────────────────┐  ┌───────────────────┐       │  │
│  │  │ Pod 0             │  │ Pod 1             │       │  │
│  │  │                   │  │                   │       │  │
│  │  │ ┌──────────────┐  │  │ ┌──────────────┐  │  ...  │  │
│  │  │ │ Claude Code  │  │  │ │ Claude Code  │  │       │  │
│  │  │ │ + Happy      │  │  │ │ + Happy      │  │       │  │
│  │  │ └──────────────┘  │  │ └──────────────┘  │       │  │
│  │  │ ┌──────────────┐  │  │ ┌──────────────┐  │       │  │
│  │  │ │ Metrics      │  │  │ │ Metrics      │  │       │  │
│  │  │ │ Exporter     │  │  │ │ Exporter     │  │       │  │
│  │  │ └──────────────┘  │  │ └──────────────┘  │       │  │
│  │  │                   │  │                   │       │  │
│  │  │ PVC: workspace    │  │ PVC: workspace    │       │  │
│  │  └───────────────────┘  └───────────────────┘       │  │
│  └──────────────────────────────────────────────────────┘  │
│                             │                               │
│                             ▼                               │
│                   ┌──────────────────┐                      │
│                   │  Prometheus      │                      │
│                   │  (Monitoring)    │                      │
│                   └────────┬─────────┘                      │
│                            │                                │
│                            ▼                                │
│                   ┌──────────────────┐                      │
│                   │       HPA        │                      │
│                   │  (Autoscaler)    │                      │
│                   └──────────────────┘                      │
│                                                              │
│  Scales pods to maintain 1 idle agent for instant response  │
└──────────────────────────────────────────────────────────────┘
```

### Component Overview

| Component | Purpose | Resource Usage |
|-----------|---------|----------------|
| **Claude Agent Container** | Runs Happy daemon and Claude Code on-demand | 100m-2 CPU, 256Mi-2Gi RAM |
| **Metrics Exporter Sidecar** | Monitors agent activity for autoscaling | 10m CPU, 16Mi RAM |
| **PersistentVolume** | Stores repository, git history, sessions | 2-10Gi per pod |
| **HPA** | Scales pods based on idle/active metrics | - |
| **Prometheus** | Collects and stores metrics | (cluster-level) |

## ⚙️ Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `repository.name` | Repository identifier (for metrics) | `"unknown"` |
| `repository.url` | Git repository URL | Required |
| `repository.branch` | Git branch to work with | `"main"` |
| `credentials.claudeMaxToken` | Claude long-lived token | Required |
| `credentials.gitPat` | GitHub PAT | Required |
| `happy.accessKey` | Happy authentication credentials | Required |
| `autoscaling.enabled` | Enable intelligent autoscaling | `true` |
| `autoscaling.minReplicas` | Minimum pods per repository | `2` |
| `autoscaling.maxReplicas` | Maximum pods per repository | `4` |
| `autoscaling.targetIdlePods` | Idle pods to maintain | `1` |
| `metricsExporter.idleTimeoutMinutes` | Minutes before marking idle | `10` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage per pod | `10Gi` |
| `resources.limits.cpu` | CPU limit per pod | `"2"` |
| `resources.limits.memory` | Memory limit per pod | `"2Gi"` |

See [`helm/happy-k8s/values.yaml`](helm/happy-k8s/values.yaml) for all options.

### Advanced Configuration Examples

#### Disable Autoscaling (Fixed Replicas)

```yaml
# values.yaml
autoscaling:
  enabled: false

replicaCount: 3
```

#### Aggressive Scaling (More Responsive)

```yaml
metricsExporter:
  idleTimeoutMinutes: 5  # Mark idle after 5 min

autoscaling:
  minReplicas: 1
  maxReplicas: 10
  targetIdlePods: 2  # Keep 2 agents ready
  scaleUpStabilizationWindowSeconds: 0    # Scale up immediately
  scaleDownStabilizationWindowSeconds: 180  # Wait 3 min to scale down
```

#### Resource-Constrained Cluster

```yaml
resources:
  limits:
    cpu: "1"
    memory: "1Gi"
  requests:
    cpu: "50m"
    memory: "128Mi"

persistence:
  size: "2Gi"

autoscaling:
  maxReplicas: 2  # Limit max pods
```

## 🔄 Intelligent Autoscaling

The system automatically scales pods to **maintain exactly 1 idle agent** for instant response.

### How It Works

1. **Activity Monitoring**: Sidecar watches file modifications in `~/.claude` and `~/.happy`
2. **Idle Detection**: Agent is "idle" if no activity for N minutes (default: 10)
3. **Scaling Decisions**:
   - **Scale Up** → All agents busy (0 idle)
   - **Scale Down** → Too many idle agents (>1 idle)
   - **Stable** → Exactly 1 idle agent ✓

### Example Scaling Scenario

```
Time  | Agents | Active | Idle | Action
------|--------|--------|------|---------------------------
00:00 |   2    |   0    |  2   | Scale down (too many idle)
00:05 |   1    |   0    |  1   | Stable ✓
00:10 |   1    |   1    |  0   | Scale up (all busy)
00:12 |   2    |   1    |  1   | Stable ✓
00:20 |   2    |   2    |  0   | Scale up (all busy)
00:22 |   3    |   2    |  1   | Stable ✓
00:40 |   3    |   0    |  3   | Scale down (too many idle)
00:45 |   2    |   0    |  2   | Scale down (too many idle)
00:50 |   1    |   0    |  1   | Stable ✓
```

### Monitoring Autoscaling

```bash
# Watch HPA in real-time
kubectl get hpa -n happy-k8s -w

# View current metrics
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090 and query: claude_session_active

# Check scaling events
kubectl get events -n happy-k8s --sort-by='.lastTimestamp' | grep HPA

# View metrics from a pod
kubectl port-forward my-webapp-happy-k8s-0 8080:8080 -n happy-k8s
curl http://localhost:8080/metrics
```

### Metrics Exposed

Each pod exposes Prometheus metrics:

- `claude_last_activity_timestamp_seconds` - Last activity time
- `claude_session_active` - Active (1) or idle (0)
- `claude_sessions_total` - Total Claude sessions
- `claude_minutes_since_last_activity` - Time since activity
- `claude_exporter_healthy` - Exporter health status

## 🎛️ Operations

### Managing Deployments

```bash
# List all agents
kubectl get statefulsets -n happy-k8s

# Check pod status
kubectl get pods -l app.kubernetes.io/name=happy-k8s -n happy-k8s

# View logs (main container)
kubectl logs my-webapp-happy-k8s-0 -n happy-k8s -f

# View metrics exporter logs
kubectl logs my-webapp-happy-k8s-0 -c metrics-exporter -n happy-k8s

# Access agent shell
kubectl exec -it my-webapp-happy-k8s-0 -n happy-k8s -- /bin/bash

# Check Claude history
kubectl exec my-webapp-happy-k8s-0 -n happy-k8s -- cat ~/.claude/history.jsonl

# Check Happy daemon logs
kubectl exec my-webapp-happy-k8s-0 -n happy-k8s -- tail -50 ~/.happy/logs/daemon.log
```

### Updating Agents

```bash
# Rebuild and push new image
docker build -t ghcr.io/yourorg/happy-k8s:latest .
docker push ghcr.io/yourorg/happy-k8s:latest

# Rolling update (Terraform)
cd terraform && terraform apply

# Rolling update (Helm)
helm upgrade my-agent helm/happy-k8s -f values.yaml

# Or force restart
kubectl rollout restart statefulset/my-webapp-happy-k8s -n happy-k8s
```

### Scaling Manually

```bash
# Scale to specific replica count (when autoscaling disabled)
kubectl scale statefulset/my-webapp-happy-k8s --replicas=5 -n happy-k8s

# Or via Helm
helm upgrade my-agent helm/happy-k8s --set replicaCount=5
```

### Managing Multiple Repositories

With Terraform, manage all repositories from one config:

```hcl
# terraform.tfvars
agents = {
  "frontend" = {
    repository_url = "https://github.com/org/frontend"
    replica_count  = 2
  }
  "backend" = {
    repository_url = "https://github.com/org/backend"
    replica_count  = 2
  }
  "mobile" = {
    repository_url = "https://github.com/org/mobile-app"
    replica_count  = 1
  }
}
```

```bash
# Deploy/update all at once
terraform apply

# Remove a repository
# Just delete from agents map, then:
terraform apply
```

## 🔧 Troubleshooting

### Agents Show Online But Don't Respond

**Symptoms**: Happy app shows agent online, but messages never complete

**Causes & Solutions**:

1. **Expired Claude credentials**
   ```bash
   # Check logs for auth errors
   kubectl logs <pod> -n happy-k8s | grep -i "auth\|token\|401"

   # Solution: Generate new token and redeploy
   claude setup-token
   # Update terraform.tfvars with new token
   terraform apply
   ```

2. **Projects directory not writable**
   ```bash
   # Check startup logs
   kubectl logs <pod> -n happy-k8s | grep "Created Claude"

   # Should see:
   # "Created Claude credentials from Max token"
   # "Created Claude settings.json"
   ```

3. **Machine ID conflicts**
   ```bash
   # Each pod should have unique ID
   kubectl logs <pod> -n happy-k8s | grep "Generated unique machineId"
   ```

### Pod Won't Start (CrashLoopBackOff)

```bash
# Check pod events
kubectl describe pod <pod-name> -n happy-k8s

# Check init container logs (git clone)
kubectl logs <pod> -c git-clone -n happy-k8s

# Common issues:
# - Invalid repository URL
# - GitHub PAT lacks repo access
# - Network connectivity blocked
```

### Git Push/Pull Failures

```bash
# Test git access from pod
kubectl exec <pod> -n happy-k8s -- git ls-remote https://github.com/yourorg/repo

# If fails, check:
# 1. PAT has 'repo' scope
# 2. PAT is not expired
# 3. Repository URL is correct
```

### Health Checks Failing

```bash
# Run health check manually
kubectl exec <pod> -n happy-k8s -- /healthcheck.sh

# Check Happy process
kubectl exec <pod> -n happy-k8s -- pgrep -a happy

# View Happy logs
kubectl exec <pod> -n happy-k8s -- tail -100 ~/.happy/logs/daemon.log
```

### Autoscaling Not Working

**HPA shows "Unknown" metrics**:

```bash
# Check Prometheus Adapter is running
kubectl get pods -n monitoring | grep prometheus-adapter

# Verify custom metrics API
kubectl get apiservice v1beta1.custom.metrics.k8s.io

# Check adapter logs
kubectl logs -n monitoring deployment/prometheus-adapter
```

**Metrics not in Prometheus**:

```bash
# Check ServiceMonitor exists
kubectl get servicemonitor -n happy-k8s

# Port-forward Prometheus and check targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets
# Look for happy-k8s-metrics job

# Check exporter logs
kubectl logs <pod> -c metrics-exporter -n happy-k8s
```

**Scaling doesn't trigger**:

```bash
# View HPA status
kubectl describe hpa <release-name>-happy-k8s -n happy-k8s

# Check for errors in conditions section

# Manually trigger activity
# Send commands to agents via Happy app
# Within 2-3 minutes, HPA should scale if needed
```

### Network Connectivity Issues

```bash
# Test Happy server connectivity from pod
kubectl exec <pod> -n happy-k8s -- curl -v https://api.cluster-fluster.com/v1/sessions

# Test GitHub connectivity
kubectl exec <pod> -n happy-k8s -- curl -v https://github.com

# Check DNS resolution
kubectl exec <pod> -n happy-k8s -- nslookup api.cluster-fluster.com

# If NetworkPolicy is enabled, verify it allows egress
kubectl get networkpolicy -n happy-k8s
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n happy-k8s

# If pending and no storage class available:
# Disable persistence in values:
persistence:
  enabled: false  # Uses emptyDir instead
```

### Viewing All Resources

```bash
# See everything for an agent deployment
kubectl get all,pvc,secret,configmap,servicemonitor -n happy-k8s -l app.kubernetes.io/instance=my-webapp
```

## 🔐 Security Considerations

### Credentials Management

- **Never commit secrets** - Use `.gitignore` for `terraform.tfvars` and `secrets.yaml`
- **Use Kubernetes Secrets** - Credentials stored encrypted in etcd
- **Consider External Secrets** - For production, use Vault or External Secrets Operator
- **Rotate regularly** - Update tokens and PATs periodically

### Pod Security

- **Non-root user** - Agents run as UID 1000
- **Resource limits** - Prevents resource exhaustion
- **Read-only mounts** - Credentials mounted read-only
- **Network policies** - Optional egress restrictions

### Repository Access

- **Least privilege PATs** - Grant only required scopes
- **Per-repo agents** - Isolate agents by repository
- **Git signed commits** - Configure GPG signing if required
- **Branch protection** - Enforce PR reviews for sensitive repos

### Multi-Tenancy

- **Namespace isolation** - Each tenant gets separate namespace
- **Resource quotas** - Limit resource usage per namespace
- **RBAC** - Control who can deploy/manage agents
- **Network policies** - Restrict pod-to-pod communication

## 🤝 Contributing

Contributions welcome! Areas we'd love help with:

- 📱 **Mobile app improvements** - Better Happy integration
- 📊 **Monitoring dashboards** - Grafana dashboards for metrics
- 🔧 **Tool additions** - More pre-installed dev tools
- 📚 **Documentation** - Usage examples, tutorials
- 🧪 **Testing** - Integration tests, load testing
- 🏗️ **Platform support** - AWS EKS, GKE, AKS examples

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Anthropic](https://anthropic.com)** - For Claude AI and Claude Code
- **[Happy](https://happy.engineering)** - For mobile terminal access
- **Kubernetes Community** - For the amazing ecosystem

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/ajbrown/happy-k8s/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ajbrown/happy-k8s/discussions)
- **Discord**: [Join our server](https://discord.gg/yourserver)

---

**Made with ❤️ for developers who want AI assistance everywhere**
