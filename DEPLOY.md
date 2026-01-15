# Quick Deployment Guide

Follow these steps to deploy happy-k8s to GitHub and integrate with cybertron.

## 🚀 Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. **Repository name**: `happy-k8s`
3. **Description**: `Your AI coding assistant in your pocket - Deploy Claude agents on Kubernetes, control from your phone via Happy`
4. **Visibility**: Public
5. **DO NOT** check any initialization options
6. Click "Create repository"

## 📤 Step 2: Push to GitHub

```bash
cd /Users/ajbrown/Projects/happy-k8s

# Add remote
git remote add origin https://github.com/ajbrown/happy-k8s.git

# Push main branch
git push -u origin main

# Create and push v1.0.0 tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial release of Happy for Kubernetes"
git push origin v1.0.0
```

## ⚙️ Step 3: Configure GitHub Repository

### Enable GitHub Actions
1. Go to: https://github.com/ajbrown/happy-k8s/settings/actions
2. Under "Actions permissions", select "Allow all actions and reusable workflows"
3. Click "Save"

### Set Repository Topics
1. Go to: https://github.com/ajbrown/happy-k8s
2. Click ⚙️ next to "About"
3. Add topics: `kubernetes`, `helm`, `claude`, `ai`, `happy`, `chatops`, `terraform`, `autoscaling`, `prometheus`, `mobile`
4. Set website: `https://happy.engineering`
5. Click "Save changes"

### Enable Discussions (Optional but Recommended)
1. Go to: https://github.com/ajbrown/happy-k8s/settings
2. Under "Features", check "Discussions"
3. Click "Set up discussions" if prompted

### Enable GitHub Packages
Docker images will automatically publish to ghcr.io when you push. No additional setup needed.

## 🔗 Step 4: Update Cybertron Repository

```bash
cd /Users/ajbrown/Projects/cybertron

# Commit the workloads README we already created
git commit --no-gpg-sign -m "docs: Add workloads README for happy-k8s submodule

Prepare for integrating happy-k8s as a git submodule.

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>
"

# Push to cybertron
git push origin main

# Now remove the old workloads/claude-agents and add happy-k8s submodule
git rm -rf workloads/claude-agents

# Add happy-k8s as submodule
git submodule add https://github.com/ajbrown/happy-k8s.git workloads/happy-k8s

# Commit the submodule
git commit --no-gpg-sign -m "refactor: Replace local claude-agents with happy-k8s submodule

Move claude-agents to standalone open-source repository as happy-k8s.

The project is now independently maintained at:
https://github.com/ajbrown/happy-k8s

Benefits:
- Open source and discoverable
- Independent versioning and releases
- Automated CI/CD via GitHub Actions
- Can be used by external users
- Still integrated with cybertron via submodule

To update: git submodule update --remote workloads/happy-k8s
To use specific version: cd workloads/happy-k8s && git checkout v1.0.0

Generated with [Claude Code](https://claude.ai/code)
via [Happy](https://happy.engineering)

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>
"

# Push to cybertron
git push origin main
```

## ✅ Step 5: Verify Everything Works

```bash
# Clone cybertron fresh to test
cd /tmp
git clone --recurse-submodules https://github.com/ajbrown/cybertron.git cybertron-test
cd cybertron-test

# Verify happy-k8s submodule is present
ls -la workloads/happy-k8s/

# Should see:
# - README.md
# - helm/happy-k8s/
# - terraform/
# - metrics-exporter/
# etc.

# Clean up
cd ..
rm -rf cybertron-test
```

## 🎉 You're Done!

Your happy-k8s project is now:
- ✅ Open source at github.com/ajbrown/happy-k8s
- ✅ Has automated CI/CD
- ✅ Builds Docker images automatically
- ✅ Integrated with cybertron via submodule
- ✅ Ready for external users

## 🌟 Next Steps (Optional)

1. **Create GitHub Release**
   - Go to: https://github.com/ajbrown/happy-k8s/releases/new
   - Tag: v1.0.0 (already created)
   - Title: "v1.0.0 - Initial Release"
   - Generate release notes automatically
   - Publish release

2. **Share on Social Media**
   - Post on Twitter/X
   - Share in Kubernetes communities
   - Post on Reddit (r/kubernetes, r/selfhosted)

3. **Add to Awesome Lists**
   - [awesome-kubernetes](https://github.com/ramitsurana/awesome-kubernetes)
   - [awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted)

4. **Create Demo Video**
   - Show mobile usage
   - Deploy walkthrough
   - Autoscaling demo

## 📚 Resources

- **Repository**: https://github.com/ajbrown/happy-k8s
- **Documentation**: See README.md in repo
- **Issues**: https://github.com/ajbrown/happy-k8s/issues
- **Discussions**: https://github.com/ajbrown/happy-k8s/discussions

## ❓ Need Help?

See MIGRATION-STEPS.md for detailed explanations and troubleshooting.
