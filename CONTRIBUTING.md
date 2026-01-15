# Contributing to Claude Agents

Thank you for your interest in contributing to Claude Agents! This document provides guidelines and instructions for contributing.

## 🌟 Ways to Contribute

- **Bug Reports**: Found a bug? [Open an issue](https://github.com/ajbrown/happy-k8s/issues/new)
- **Feature Requests**: Have an idea? [Start a discussion](https://github.com/ajbrown/happy-k8s/discussions)
- **Documentation**: Improve docs, add examples, write tutorials
- **Code**: Fix bugs, add features, improve performance
- **Testing**: Write tests, test on different platforms
- **Community**: Help others in discussions and issues

## 🚀 Getting Started

### Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/yourusername/happy-k8s.git
   cd happy-k8s
   ```

2. **Set up a test Kubernetes cluster**
   ```bash
   # Using kind (Kubernetes in Docker)
   kind create cluster --name happy-k8s-dev

   # Or using minikube
   minikube start --profile happy-k8s-dev
   ```

3. **Install dependencies**
   ```bash
   # Helm
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update

   # Terraform (if modifying Terraform modules)
   cd terraform
   terraform init
   ```

4. **Build the Docker image**
   ```bash
   docker build -t happy-k8s:dev .

   # Load into kind cluster
   kind load docker-image happy-k8s:dev --name happy-k8s-dev
   ```

5. **Deploy for testing**
   ```bash
   helm install test-agent helm/happy-k8s \
     --set image.repository=happy-k8s \
     --set image.tag=dev \
     --set image.pullPolicy=Never \
     -f your-test-values.yaml
   ```

### Project Structure

```
happy-k8s/
├── Dockerfile                 # Main agent container image
├── helm/
│   └── happy-k8s/        # Helm chart
│       ├── templates/        # Kubernetes manifests
│       └── values.yaml       # Default configuration
├── terraform/                # Terraform modules
│   ├── modules/
│   │   └── claude-agent/    # Reusable module
│   └── deployments/         # Example deployments
├── metrics-exporter/         # Go metrics exporter
│   ├── main.go
│   └── Dockerfile
├── scripts/                  # Helper scripts
└── docs/                     # Additional documentation
```

## 📝 Contribution Guidelines

### Before You Start

1. **Check existing issues** - Someone might already be working on it
2. **Open an issue first** - For significant changes, discuss the approach first
3. **Keep changes focused** - One feature/fix per PR
4. **Write tests** - If applicable, add tests for your changes

### Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-number-description
   ```

2. **Make your changes**
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation if needed

3. **Test your changes**
   ```bash
   # Test Helm chart
   helm lint helm/happy-k8s
   helm template test helm/happy-k8s -f test-values.yaml

   # Test in cluster
   helm upgrade --install test-agent helm/happy-k8s \
     --set image.tag=dev -f test-values.yaml

   # Verify pods are running
   kubectl get pods -n happy-k8s
   kubectl logs <pod-name> -n happy-k8s
   ```

4. **Update documentation**
   - Update README.md if adding features
   - Add examples if helpful
   - Update values.yaml comments

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add support for X"

   # Follow conventional commits format:
   # feat: new feature
   # fix: bug fix
   # docs: documentation changes
   # refactor: code refactoring
   # test: adding tests
   # chore: maintenance tasks
   ```

6. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Pull Request Process

1. **Fill out the PR template** - Describe what and why
2. **Link related issues** - Use "Fixes #123" or "Relates to #456"
3. **Request review** - Tag relevant maintainers
4. **Address feedback** - Make requested changes
5. **Keep PR updated** - Rebase on main if needed

### PR Checklist

- [ ] Code follows the existing style
- [ ] Documentation updated (README, CHANGELOG, etc.)
- [ ] Helm chart lints successfully (`helm lint`)
- [ ] Tested in a real cluster
- [ ] No sensitive data in commits (tokens, credentials)
- [ ] Commit messages follow conventional commits
- [ ] PR description explains the changes

## 🐛 Reporting Bugs

When reporting bugs, please include:

1. **Description** - Clear description of the bug
2. **Steps to reproduce** - Exact steps to trigger the bug
3. **Expected behavior** - What should happen
4. **Actual behavior** - What actually happens
5. **Environment**:
   - Kubernetes version (`kubectl version`)
   - Helm version (`helm version`)
   - OS/platform
   - Cloud provider (if applicable)
6. **Logs** - Relevant pod logs or error messages
7. **Configuration** - Sanitized values.yaml or terraform.tfvars

**Example bug report:**

```markdown
**Bug**: Pods crash when persistence is disabled

**Steps to reproduce**:
1. Deploy with `persistence.enabled: false`
2. Wait for pods to start
3. Pods enter CrashLoopBackOff

**Expected**: Pods run successfully with emptyDir

**Actual**: Pods crash with "workspace not found"

**Environment**:
- Kubernetes 1.28.0
- Helm 3.12.0
- GKE 1.28.0-gke.1000

**Logs**:
```
Error: ENOENT: no such file or directory, mkdir '/workspace/.claude'
```

**Configuration**:
```yaml
persistence:
  enabled: false
```
```

## 💡 Feature Requests

For feature requests:

1. **Check existing requests** - Maybe it's already planned
2. **Describe the use case** - Why is this needed?
3. **Proposed solution** - How would you implement it?
4. **Alternatives considered** - Other approaches you thought about

## 🧪 Testing

### Manual Testing

```bash
# Test basic deployment
helm install test helm/happy-k8s -f test-values.yaml

# Test autoscaling
# 1. Deploy with autoscaling enabled
# 2. Send commands via Happy app to make agents active
# 3. Watch HPA: kubectl get hpa -w
# 4. Verify scaling: kubectl get pods -w

# Test updates
helm upgrade test helm/happy-k8s --set image.tag=dev2

# Test persistence
# 1. Create a file in the workspace
# 2. Delete the pod
# 3. New pod should have the file

# Cleanup
helm uninstall test
kubectl delete pvc --all -n happy-k8s
```

### Integration Testing

We welcome contributions to add automated testing:

- Helm chart validation tests
- Integration tests using kind/k3s
- Terraform module tests
- Metrics exporter unit tests

## 📚 Documentation

Documentation improvements are always welcome:

- Fix typos or unclear explanations
- Add examples for common scenarios
- Write tutorials or guides
- Improve code comments
- Add architecture diagrams

## 🎨 Code Style

### Go (Metrics Exporter)

- Follow standard Go formatting (`gofmt`)
- Add comments for exported functions
- Use meaningful variable names
- Handle errors explicitly

### YAML (Helm/Kubernetes)

- 2-space indentation
- Comments for complex logic
- Follow Helm best practices
- Use `_helpers.tpl` for repeated logic

### Terraform

- Use `terraform fmt`
- Add descriptions to variables
- Document module inputs/outputs
- Follow HashiCorp style guide

## 🔐 Security

If you discover a security vulnerability:

1. **Do NOT open a public issue**
2. **Email the maintainers** at [security@yourorg.com]
3. **Include details** - Steps to reproduce, impact
4. **Allow time** - We'll respond within 48 hours

## 📜 Code of Conduct

- **Be respectful** - Treat everyone with respect
- **Be constructive** - Provide helpful feedback
- **Be collaborative** - Work together towards solutions
- **Be patient** - Maintainers are volunteers

## 🎁 Recognition

Contributors are recognized:

- Listed in release notes
- Added to CONTRIBUTORS.md
- Mentioned in documentation for significant contributions

## 📞 Getting Help

- **Documentation**: Check README.md first
- **Discussions**: [GitHub Discussions](https://github.com/ajbrown/happy-k8s/discussions)
- **Discord**: [Join our server](https://discord.gg/yourserver)
- **Issues**: For bugs and features only

## 📅 Release Process

For maintainers:

1. Update CHANGELOG.md
2. Bump version in Chart.yaml
3. Create GitHub release
4. Tag with version: `git tag v1.0.0`
5. Push tags: `git push --tags`
6. Build and push Docker images
7. Update documentation

## ❓ Questions?

Feel free to:

- Ask in [Discussions](https://github.com/ajbrown/happy-k8s/discussions)
- Open an issue with the "question" label
- Reach out on Discord

---

**Thank you for contributing to Claude Agents! 🎉**
