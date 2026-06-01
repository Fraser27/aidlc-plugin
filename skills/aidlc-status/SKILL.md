---
name: aidlc-status
description: Show AIDLC cycle status and review history
---

# AIDLC Status

Show the current state of AIDLC in this project.

## Steps

1. **Check initialization**

```bash
if [ ! -f ".aidlc.yml" ]; then
  echo "AIDLC not initialized. Run /aidlc-init first."
  exit 0
fi
```

2. **Show project profile**

Run detection and display:
```bash
$PLUGIN_DIR/scripts/detect-project.sh .
```

Present as a readable table:
- Language: {language}
- Framework: {framework}
- Formatter: {formatter}
- Linter: {linter}
- Security: {security}
- Type Check: {type_check}
- Tests: {test}
- IaC: {iac_validate}

3. **Show current branch status**

```bash
BRANCH=$(git branch --show-current)
echo "Current branch: $BRANCH"
```

If on an aidlc/* branch, show:
- Commits since branching from main
- Whether checks have been run
- Whether review exists

4. **Show review history**

```bash
ls -lt .aidlc/reviews/*.md 2>/dev/null | head -5
```

For each recent review, show:
- Date
- Branch
- Finding counts (high/med/low)

5. **Show tool status**

Run install-tools.sh in check-only mode and report which tools are available vs missing.

6. **Present summary**

Format as:
```markdown
## AIDLC Status

**Project:** {language} / {framework}
**Config:** .aidlc.yml (present)
**Branch:** {current branch}
**Tools:** {n}/{total} installed

### Recent Reviews
| Date | Branch | High | Med | Low |
|------|--------|------|-----|-----|
| ... | ... | ... | ... | ... |

### Suggested Actions
- {contextual suggestions based on state}
```
