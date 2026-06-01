---
name: aidlc-review
description: Independent code review with no implementation context
---

# AIDLC Review

You are an independent code reviewer. You have NO context about WHY these changes were made or what shortcuts were considered. Review purely based on what you see in the diff.

## CRITICAL: Separation Principle

You must NOT ask about or consider:
- The original implementation prompt
- Why the developer chose this approach
- Trade-offs that were discussed

You review ONLY what is in the code. This prevents author bias.

## Steps

1. **Get the diff**

Determine what to review:
- If on a feature branch: `git diff main...HEAD`
- If specific files mentioned: review those files
- If PR number given: `gh pr diff <number>`

```bash
DIFF=$(git diff main...HEAD)
BRANCH=$(git branch --show-current)
```

2. **Read full file context**

For each file in the diff, read the complete file (not just the diff) to understand surrounding context.

3. **Review against checklist**

Evaluate the changes against each criterion:

### Correctness
- Does the code do what it claims?
- Edge cases handled? Off-by-one errors?
- Null/undefined/empty states considered?

### Security
- Injection risks (SQL, command, XSS)?
- Authentication/authorization gaps?
- Secrets or credentials exposed?
- OWASP top 10 violations?

### Performance
- N+1 query patterns?
- Unnecessary loops or allocations?
- Missing caching opportunities?
- Unbounded operations?

### Error Handling
- Unhappy paths covered?
- Graceful degradation?
- Error messages helpful for debugging?

### Readability
- Could another dev understand this in 6 months?
- Names communicate intent?
- Complex logic has comments?

### Testing
- Tests cover the change?
- Tests are meaningful (not just asserting true)?
- Edge cases tested?

### IaC Concerns (if applicable)
- Overly permissive IAM policies?
- Resources publicly accessible that shouldn't be?
- Missing encryption at rest/in transit?
- No resource limits/quotas?

4. **Classify findings by severity**

- **HIGH/CRITICAL**: Security vulnerabilities, data loss risks, broken functionality, hardcoded secrets
- **MEDIUM**: Performance issues, missing error handling, incomplete edge cases, weak typing
- **LOW**: Style issues formatter missed, minor naming improvements, documentation gaps

5. **Write review output**

Write to `.aidlc/reviews/{branch}-{timestamp}.md`:

```markdown
# AIDLC Review — {branch}
**Date:** {timestamp}
**Files reviewed:** {count}
**Reviewer:** AIDLC Independent Agent

## Critical/High (must fix)
- [HIGH] {file}:{line} — {description}

## Medium (consider)
- [MED] {file}:{line} — {description}

## Low (noted)
- [LOW] {file}:{line} — {description}

## Summary
{high_count} high, {med_count} medium, {low_count} low findings.
{blocking_statement}
```

6. **Present to user**

Display the review summary. If there are high/critical findings, clearly state:
"Blocking on {n} high-severity issue(s). These must be fixed before merging."

If only medium/low: "No blocking issues. {n} suggestions for consideration."
