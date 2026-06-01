---
name: aidlc-ship
description: Full lifecycle orchestrator - develop, check, review, fix, PR
---

# AIDLC Ship

Full AI Development Life Cycle orchestrator. Takes a feature description and handles the entire workflow: branch creation, implementation, checks, independent review, fixing, and PR creation.

## Usage

```
/aidlc-ship "description of what to implement"
```

## Prerequisites

- Project must have `.aidlc.yml` (run `/aidlc-init` first if not present)
- Must be on a clean working tree (no uncommitted changes)

## Orchestration Flow

### Phase 1: SETUP

```bash
# Verify clean state
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash changes first."
  exit 1
fi

# Determine base branch
BASE_BRANCH=$(git branch --show-current)

# Read config
AIDLC_CONFIG=".aidlc.yml"
BRANCH_PREFIX="aidlc"
if [ -f "$AIDLC_CONFIG" ]; then
  PREFIX=$(grep "branch_prefix:" "$AIDLC_CONFIG" | awk '{print $2}' | tr -d '"')
  [ -n "$PREFIX" ] && BRANCH_PREFIX="$PREFIX"
fi

# Create feature branch
SLUG=$(echo "{description}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-40)
BRANCH="${BRANCH_PREFIX}/${SLUG}"
git checkout -b "$BRANCH"
```

### Phase 2: DEVELOP

Implement the requested change:

1. Understand the request from the user's description
2. Read relevant existing code to understand the codebase
3. If tests exist in the project, use TDD:
   - Write failing test first
   - Implement minimal code to pass
   - Refactor if needed
4. If no test infrastructure exists, implement directly
5. Run format and lint (auto-fix):
   ```bash
   $PLUGIN_DIR/scripts/run-checks.sh --dir .
   ```
6. Commit working code:
   ```bash
   git add -A
   git commit -m "feat: {description}"
   ```

### Phase 3: SELF-CHECK

Run the full check suite:

```bash
RESULTS=$($PLUGIN_DIR/scripts/run-checks.sh --dir .)
HIGH_FINDINGS=$(echo "$RESULTS" | $PLUGIN_DIR/scripts/severity-filter.sh --level high)
```

- If HIGH findings exist -> go to Phase 4 (FIX) targeting these findings
- If only MEDIUM/LOW -> proceed to Phase 4 (REVIEW)

### Phase 4: REVIEW

Spawn an independent reviewer subagent:

**CRITICAL:** The reviewer subagent must:
- Receive ONLY the git diff (`git diff $BASE_BRANCH...HEAD`)
- Have NO access to this orchestration prompt or the original feature request
- Use the `/aidlc-review` skill

Use the Agent tool to spawn the reviewer:
```
Agent tool:
  prompt: "You are an independent code reviewer. Run /aidlc-review on the current branch. Review the diff against the base branch. Write findings to .aidlc/reviews/. You have NO context about why these changes were made."
  subagent_type: "general-purpose"
```

After the reviewer completes, read the review file from `.aidlc/reviews/`.

### Phase 5: FIX (if needed)

Read the review findings. If HIGH/CRITICAL findings exist:

1. Fix each high/critical finding
2. Re-run checks
3. Commit fixes
4. Track fix iterations:

```
FIX_CYCLE=1
MAX_CYCLES=3  # from .aidlc.yml review.max_fix_cycles
```

If after fixing, re-review still finds HIGH issues:
- Increment FIX_CYCLE
- If FIX_CYCLE > MAX_CYCLES: **ESCALATE TO HUMAN**
  - Present all remaining findings
  - Ask for guidance
  - Do NOT continue automatically

If all HIGH findings resolved -> proceed to Phase 6.

### Phase 6: HUMAN GATE

**STOP HERE. Present to the user:**

```markdown
## AIDLC Ship Summary — {branch}

### Changes Made
- {summary of implementation}

### Check Results
- Format: PASS
- Lint: PASS
- Types: PASS
- Tests: PASS (coverage: X%)
- Security: {PASS or N warnings}
- Deps: PASS
- IaC: PASS

### Review Findings
- High/Critical: 0 (all resolved)
- Medium: {count} (noted below)
  - {list of medium findings}
- Low: {count}

### Ready to create PR?
Approve to create PR, or provide feedback for changes.
```

**Wait for user response.** Do NOT proceed without explicit approval.

### Phase 7: PR CREATION

After user approves:

```bash
git push -u origin "$BRANCH"

gh pr create --title "{short description}" --body "$(cat <<'EOF'
## Summary
{1-3 bullet points of what was implemented}

## AIDLC Check Results
- Format: PASS
- Lint: PASS
- Types: PASS
- Tests: PASS (coverage: X%)
- Security: PASS
- Deps: PASS
- IaC: PASS

## Review Notes
{medium findings listed as "known considerations"}

## Test Plan
- {how to verify this works}

---
Shipped with [AIDLC](https://github.com/Fraser27/aidlc-plugin)
EOF
)"
```

Present the PR URL to the user.

## Error Handling

- If implementation fails: present the error, ask user for guidance
- If checks can't run (missing tools): offer to install via `install-tools.sh`
- If review subagent fails: fall back to self-review (note this to user)
- If PR creation fails: show the error, suggest manual steps
