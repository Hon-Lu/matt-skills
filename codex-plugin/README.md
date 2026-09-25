# Codex plugin packaging

This directory is an additive packaging layer for Codex. It does not modify the repository's original skills or Claude Code plugin.

## Sync after pulling upstream changes

The Claude Code plugin manifest remains the source of truth for the promoted skill list:

```bash
powershell -File codex-plugin/sync.ps1
powershell -File codex-plugin/sync.ps1 -Check
```

The sync command recreates only `plugins/mattpocock-skills` and `.agents/plugins/marketplace.json`.
It also removes Claude's `disable-model-invocation: true` key from generated copies; Codex keeps the same user-only behavior through each skill's `agents/openai.yaml` policy.

## Install in Codex

Add this repository's GitHub marketplace, then install the plugin:

```bash
codex plugin marketplace add Hon-Lu/matt-skills
codex plugin add mattpocock-skills@matt-skills
```

Start a new Codex thread after installing or updating so the refreshed skills are loaded.
