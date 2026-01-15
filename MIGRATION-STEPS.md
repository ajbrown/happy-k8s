# Migration Steps: Happy-K8s to Standalone Repository

This guide walks you through completing the migration from cybertron/workloads/happy-k8s to a standalone repository.

## ✅ Completed Steps

- [x] Created standalone repository structure
- [x] Added GitHub Actions workflows (CI/CD)
- [x] Updated documentation with correct URLs
- [x] Initial commit created

## 🚀 Next Steps

### 1. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `happy-k8s`
3. Description: `Production-ready Kubernetes deployment for Claude AI agents with intelligent autoscaling`
4. Visibility: **Public** (for open source)
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

### 2. Push to GitHub

```bash
cd /Users/ajbrown/Projects/happy-k8s-standalone

# Add remote
git remote add origin https://github.com/ajbrown/happy-k8s.git

# Push to main
git push -u origin main

# Create and push v1.0.0 tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial open-source release"
git push origin v1.0.0
```

### 3. Configure GitHub Repository Settings

After pushing:

1. **Enable GitHub Actions**:
   - Go to repository Settings → Actions → General
   - Enable "Allow all actions and reusable workflows"

2. **Enable GitHub Packages** (for Docker images):
   - Go to Settings → Packages
   - Enable package visibility

3. **Set Repository Topics** (for discoverability):
   - Click ⚙️ next to "About" on repo homepage
   - Add topics: `kubernetes`, `helm`, `claude`, `ai`, `chatops`, `terraform`, `autoscaling`, `prometheus`

4. **Enable Discussions** (optional but recommended):
   - Settings → Features → Check "Discussions"

5. **Update Repository Details**:
   - Settings → General
   - Add Website: `https://claude.ai/code`

### 4. Update Cybertron Repository

Now update your cybertron repo to reference the standalone version:

```bash
cd /Users/ajbrown/Projects/cybertron

# Remove the old workloads/happy-k8s directory
git rm -rf workloads/happy-k8s

# Add as submodule
git submodule add https://github.com/ajbrown/happy-k8s.git workloads/happy-k8s

# Commit the change
git commit --no-gpg-sign -m "refactor: Move happy-k8s to standalone repository

Replace local workloads/happy-k8s with git submodule reference.

The happy-k8s project is now a standalone open-source repository
at https://github.com/ajbrown/happy-k8s

Benefits:
- External users can easily discover and use the project
- Independent versioning and releases
- Dedicated issue tracking and discussions
- CI/CD via GitHub Actions
- Can still be used in cybertron via submodule

To update submodule:
  git submodule update --remote workloads/happy-k8s

To use specific version:
  cd workloads/happy-k8s
  git checkout v1.0.0

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>
"

# Push to cybertron
git push origin main
```

### 5. Document Submodule Usage in Cybertron

Create or update `cybertron/workloads/README.md`:

```markdown
# Workloads

## Claude Agents

**Repository**: [github.com/ajbrown/happy-k8s](https://github.com/ajbrown/happy-k8s)

Persistent Claude AI agents accessible via mobile app with intelligent autoscaling.

### Using the Submodule

The happy-k8s workload is maintained as a separate repository and included
as a git submodule.

#### First Time Setup

```bash
# Initialize submodules
git submodule update --init --recursive
```

#### Updating to Latest Version

```bash
# Update to latest main
git submodule update --remote workloads/happy-k8s

# Or checkout a specific version
cd workloads/happy-k8s
git checkout v1.0.0
cd ../..
git add workloads/happy-k8s
git commit -m "Update happy-k8s to v1.0.0"
```

#### Making Local Changes

If you need to modify happy-k8s:

1. Fork the repository
2. Update submodule URL to your fork
3. Make changes and push to your fork
4. Submit PR to upstream repository

### Deployment

See [happy-k8s documentation](workloads/happy-k8s/README.md) for
deployment instructions.
```

### 6. Verify Everything Works

```bash
# Clone cybertron fresh to test submodule
cd /tmp
git clone https://github.com/ajbrown/cybertron.git cybertron-test
cd cybertron-test

# Initialize submodules
git submodule update --init --recursive

# Verify happy-k8s is present
ls -la workloads/happy-k8s/

# Should see all files from standalone repo

# Clean up
cd ..
rm -rf cybertron-test
```

## 🎯 Alternative: Use Terraform Git Source (No Submodule)

If you prefer not to use submodules, you can reference the Terraform module directly:

```hcl
# In cybertron terraform
module "claude_agent" {
  source = "git::https://github.com/ajbrown/happy-k8s.git//terraform/modules/claude-agent?ref=v1.0.0"

  # Your configuration...
}
```

This approach:
- ✅ No submodule complexity
- ✅ Pin to specific versions
- ❌ Can't see/edit code locally
- ❌ Helm chart still needs to be referenced somehow

## 📋 Post-Migration Checklist

After completing all steps:

- [ ] New repository created and pushed
- [ ] GitHub Actions workflows running successfully
- [ ] v1.0.0 tag created and release published
- [ ] Cybertron updated with submodule
- [ ] Submodule working correctly
- [ ] Documentation updated
- [ ] Team notified of new structure
- [ ] Old local copies deleted

## 🎉 Success!

Your happy-k8s project is now:
- ✅ Open source and discoverable
- ✅ Independently versioned
- ✅ Has automated CI/CD
- ✅ Can be used by external users
- ✅ Still integrated with cybertron

## 📚 Next Steps

1. **Announce the release** on social media / communities
2. **Add badges** to README (build status, license, etc.)
3. **Write blog post** about the project
4. **Submit to awesome lists** (awesome-kubernetes, etc.)
5. **Create demo video** showing mobile usage
6. **Set up GitHub Sponsors** (optional)
