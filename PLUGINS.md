# Claude MCP Plugins

This document explains how to install and configure MCP (Model Context Protocol) plugins for Claude agents running in happy-k8s.

## What are MCP Plugins?

MCP (Model Context Protocol) is a standard that allows Claude to interface with external tools and data sources. MCP plugins are npm packages that implement MCP servers, extending Claude's capabilities with features like:

- **File System Access**: Read/write files, search directories
- **GitHub Integration**: Repository management, PR creation, issue tracking
- **Memory/Knowledge**: Persistent storage across sessions
- **Database Access**: Query databases directly
- **API Integrations**: Connect to external services

## Installation

### Quick Start

Add plugins to your Helm values file:

```yaml
plugins:
  - "@modelcontextprotocol/server-filesystem"
  - "@modelcontextprotocol/server-github"
  - "@modelcontextprotocol/server-memory"
```

Deploy or upgrade your release:

```bash
helm upgrade my-agent helm/happy-k8s -f my-values.yaml
```

Plugins will be automatically installed when the pod starts.

### How It Works

1. **Installation**: Plugins are installed as global npm packages during pod startup
2. **Location**: Installed to `~/.npm-global/lib/node_modules/`
3. **Timing**: Installation happens after Claude credentials setup, before Happy starts
4. **Permissions**: Uses user-writable npm prefix (non-root compatible)

The installation process:
```bash
# Configure npm for user installation
npm config set prefix ~/.npm-global

# Install each plugin
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-github
```

## Available Plugins

### Official MCP Plugins

**File System** (`@modelcontextprotocol/server-filesystem`)
- Read and write files
- Search directory contents
- Navigate file structures
- Use case: Code editing, documentation updates

**GitHub** (`@modelcontextprotocol/server-github`)
- Repository management
- Pull request creation/review
- Issue tracking
- Code search
- Use case: CI/CD integration, automated workflows

**Memory** (`@modelcontextprotocol/server-memory`)
- Persistent knowledge storage
- Cross-session context retention
- Information retrieval
- Use case: Long-term project context

**Brave Search** (`@modelcontextprotocol/server-brave-search`)
- Web search capabilities
- Real-time information
- Research assistance
- Use case: Current events, documentation lookup

**Puppeteer** (`@modelcontextprotocol/server-puppeteer`)
- Browser automation
- Screenshot capture
- Web scraping
- Use case: Testing, content extraction

### Third-Party Plugins

Many community MCP plugins are available on npm. Search for packages with `mcp-server` or `modelcontextprotocol` in the name.

## Configuration Examples

### Basic Setup

```yaml
# values.yaml
plugins:
  - "@modelcontextprotocol/server-filesystem"
  - "@modelcontextprotocol/server-github"
```

### Specific Versions

```yaml
plugins:
  - "@modelcontextprotocol/server-filesystem@1.0.0"
  - "@modelcontextprotocol/server-github@2.1.3"
```

### Development/Testing

```yaml
plugins:
  - "git+https://github.com/myorg/custom-mcp-plugin.git"
  - "file:/path/to/local/plugin"  # Requires plugin in image
```

## Per-Repository Configuration

Configure different plugins for different repositories using Terraform:

```hcl
# terraform.tfvars
agents = {
  "frontend-repo" = {
    # ... other config ...
    plugins = [
      "@modelcontextprotocol/server-filesystem",
      "@modelcontextprotocol/server-github"
    ]
  }

  "backend-repo" = {
    # ... other config ...
    plugins = [
      "@modelcontextprotocol/server-filesystem",
      "@modelcontextprotocol/server-memory",
      "@modelcontextprotocol/server-postgres"
    ]
  }
}
```

## MCP Settings Configuration

After plugins are installed, you may need to configure them in Claude's MCP settings. MCP settings are stored in `~/.claude/settings.json`.

### Example MCP Configuration

```json
{
  "theme": "dark",
  "hasCompletedOnboarding": true,
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": [
        "/home/agent/.npm-global/lib/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js"
      ],
      "env": {}
    },
    "github": {
      "command": "node",
      "args": [
        "/home/agent/.npm-global/lib/node_modules/@modelcontextprotocol/server-github/dist/index.js"
      ],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

### Automatic Configuration (Future Enhancement)

Currently, plugins are installed but must be manually configured in MCP settings. A future enhancement could automatically generate MCP server configurations based on installed plugins.

## Troubleshooting

### Plugin Installation Failures

**Check pod logs:**
```bash
kubectl logs <pod-name> -n happy-k8s | grep -A 10 "Installing Claude MCP plugins"
```

**Common issues:**
- **Network connectivity**: Ensure pod can reach npm registry
- **Invalid package name**: Verify package exists on npm
- **Version not found**: Check if specified version exists

**Failed installations don't block startup** - the pod will continue starting even if plugin installation fails.

### Verify Installed Plugins

```bash
# List installed global npm packages
kubectl exec <pod-name> -n happy-k8s -c happy-k8s -- \
  npm list -g --depth=0

# Check plugin location
kubectl exec <pod-name> -n happy-k8s -c happy-k8s -- \
  ls -la ~/.npm-global/lib/node_modules/@modelcontextprotocol/
```

### Plugin Not Available in Claude

If a plugin is installed but not available in Claude:

1. **Check MCP settings**: Verify plugin is configured in `~/.claude/settings.json`
2. **Restart Claude**: Some plugins require Claude restart to be recognized
3. **Check plugin compatibility**: Ensure plugin supports your Claude version
4. **Review logs**: Check Happy daemon logs for MCP-related errors

### Permission Errors

If you see permission errors during installation:
- Ensure the StatefulSet is using the updated image with npm prefix configuration
- Verify the container runs as non-root user (agent)
- Check that `~/.npm-global` directory is writable

## Best Practices

### 1. Version Pinning

Pin plugin versions for reproducible deployments:

```yaml
plugins:
  - "@modelcontextprotocol/server-filesystem@1.0.0"  # ✓ Good
  - "@modelcontextprotocol/server-github"            # ✗ Avoid (uses latest)
```

### 2. Minimal Plugin Set

Only install plugins you need:
- Reduces startup time
- Minimizes attack surface
- Simplifies troubleshooting

### 3. Test Before Production

Test new plugins in development first:
```bash
# Test in a single pod
helm upgrade test-agent helm/happy-k8s \
  --set plugins[0]=@modelcontextprotocol/server-new-plugin \
  --reuse-values
```

### 4. Monitor Installation

Watch pod startup logs to verify successful installation:
```bash
kubectl logs -f <pod-name> -n happy-k8s -c happy-k8s
```

### 5. Documentation

Document which plugins each repository uses and why:
```yaml
# Repository-specific plugins
# - filesystem: Required for code editing
# - github: Automated PR workflows
# - memory: Project context retention
plugins:
  - "@modelcontextprotocol/server-filesystem"
  - "@modelcontextprotocol/server-github"
  - "@modelcontextprotocol/server-memory"
```

## Security Considerations

### Plugin Trust

- **Only install trusted plugins**: Plugins run with full access to the container
- **Review plugin code**: Check the npm package before installing
- **Monitor plugin activity**: Watch for unexpected behavior

### Environment Variables

Some plugins require sensitive credentials (API tokens, etc.):

```yaml
# Pass credentials via env variables
env:
  GITHUB_TOKEN: "ghp_xxxxxxxxxxxx"
  DATABASE_URL: "postgresql://..."
```

These are stored in Kubernetes Secrets and mounted securely.

### Network Access

Plugins may need outbound network access:
- Ensure network policies allow required connections
- Consider using private npm registry for internal plugins

## Advanced Usage

### Custom Plugin Development

Create your own MCP plugin:

1. **Initialize npm package:**
   ```bash
   mkdir my-mcp-plugin
   cd my-mcp-plugin
   npm init
   ```

2. **Implement MCP server interface:**
   ```typescript
   import { Server } from "@modelcontextprotocol/sdk/server/index.js";
   // ... implement your MCP server
   ```

3. **Publish to npm or use git URL:**
   ```yaml
   plugins:
     - "git+https://github.com/myorg/my-mcp-plugin.git"
   ```

### Plugin Updates

Update plugins by changing versions:

```yaml
# Before
plugins:
  - "@modelcontextprotocol/server-filesystem@1.0.0"

# After
plugins:
  - "@modelcontextprotocol/server-filesystem@1.1.0"
```

Then restart pods:
```bash
kubectl rollout restart statefulset/<name> -n happy-k8s
```

## Examples

### Full Configuration Example

```yaml
# values.yaml for a full-stack development repository
replicaCount: 2

repository:
  name: my-fullstack-app
  url: https://github.com/myorg/my-app.git
  branch: main

credentials:
  claudeMaxToken: "sk_ant_..."
  gitPat: "ghp_..."

# Install plugins for full-stack development
plugins:
  - "@modelcontextprotocol/server-filesystem@1.0.0"  # Code editing
  - "@modelcontextprotocol/server-github@2.0.0"      # PR automation
  - "@modelcontextprotocol/server-memory@1.0.0"      # Project context
  - "@modelcontextprotocol/server-postgres@1.0.0"    # Database access

# Provide credentials for plugins
env:
  GITHUB_TOKEN: "ghp_xxxxxxxxxxxx"
  DATABASE_URL: "postgresql://user:pass@localhost:5432/mydb"

happy:
  yolo: true
  continueSession: true
```

## Resources

- **MCP Specification**: https://modelcontextprotocol.io/
- **Official MCP Plugins**: https://github.com/modelcontextprotocol/servers
- **Plugin Development Guide**: https://modelcontextprotocol.io/docs/creating-servers
- **Claude Code Documentation**: https://docs.anthropic.com/claude/docs/claude-code

## Contributing

Have a plugin to recommend? Found an issue? Contribute to the documentation:
https://github.com/ajbrown/happy-k8s/issues
