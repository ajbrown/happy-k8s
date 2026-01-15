# Changelog

All notable changes to Claude Agents will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release
- Kubernetes-native deployment via Helm and Terraform
- Intelligent autoscaling based on agent activity
- Metrics exporter sidecar for Prometheus integration
- Multi-repository support with isolated agents
- Mobile app access via Happy integration
- Persistent storage for agent workspaces
- Production-ready health checks and graceful shutdown
- Comprehensive documentation and examples

### Features
- **Mobile Access**: Control agents from anywhere via Happy mobile app
- **Autoscaling**: Maintains one idle agent for instant response
- **Multi-Repo**: Deploy separate agents per repository
- **Persistent**: Agents survive pod restarts with PVCs
- **Secure**: Self-hosted with proper isolation and secrets management
- **Observable**: Prometheus metrics for monitoring and autoscaling

## [1.0.0] - TBD

### Added
- First stable release
- Production-ready Helm chart
- Terraform modules for multi-repo deployments
- Go-based metrics exporter
- HPA integration with custom metrics
- Complete documentation

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- Non-root container execution
- Read-only credential mounts
- Resource limits to prevent DoS
- Optional NetworkPolicy support

---

## Release Notes Template

Use this template for future releases:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

---

[Unreleased]: https://github.com/yourorg/happy-k8s/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourorg/happy-k8s/releases/tag/v1.0.0
