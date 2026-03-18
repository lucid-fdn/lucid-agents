# Lucid Agent Catalog

Official and community agent catalog for the Lucid verified AI network. Deploy agents in one click.

## Quick Start

```bash
# Browse catalog
lucid marketplace list

# Deploy an agent
lucid launch --agent base-runtime
lucid launch --agent trading-analyst
lucid launch --agent code-reviewer
lucid launch --agent openclaw
```

## Official Agents

| Agent | Description | Trust |
|-------|-------------|-------|
| **base-runtime** | Configurable AI agent — set model, prompt, tools via env vars | Official |
| **trading-analyst** | Market analysis with risk assessment | Official |
| **code-reviewer** | Code review for bugs, security, best practices | Official |
| **openclaw** | Personal AI assistant with 22+ messaging channels | Official |

## Contributing

1. Fork this repo
2. Create `community/<your-agent>/manifest.yaml` + `Dockerfile`
3. Submit a PR

### Trust Tiers

| Tier | Badge | Description |
|------|-------|-------------|
| **Official** | Lucid-maintained, audited | Only Lucid team can set |
| **Verified** | Reviewed publisher, security scanned | Requires identity verification |
| **Community** | PR-reviewed, manifest-valid | Default for contributions |

### Manifest Format

See `manifest.schema.json` for the full schema. Required fields:

```yaml
name: my-agent          # lowercase, hyphens only
display_name: "My Agent"
version: "1.0.0"        # semver
author: "Your Name"
image: ghcr.io/you/my-agent:v1
```

## License

Apache-2.0
