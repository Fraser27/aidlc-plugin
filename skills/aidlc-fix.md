---
name: aidlc-fix
description: Fix findings from AIDLC review
---

# AIDLC Fix

Address findings from an AIDLC review. Focus on high/critical findings first, then medium if time permits.

## Steps

1. **Load review findings**

Read the latest review file:
```bash
LATEST_REVIEW=$(ls -t .aidlc/reviews/*.md 2>/dev/null | head -1)
```

If no review exists, tell the user to run `/aidlc-review` first.

2. **Parse findings by severity**

Extract all HIGH/CRITICAL findings — these MUST be fixed.
Extract MEDIUM findings — these SHOULD be fixed if straightforward.
Ignore LOW findings.

3. **Fix high/critical findings**

For each high/critical finding:
- Read the referenced file and line
- Understand the issue
- Implement the fix
- Ensure the fix doesn't introduce new issues

4. **Fix medium findings (if straightforward)**

For each medium finding:
- If the fix is < 5 lines and clearly correct, fix it
- If the fix requires design decisions, skip and note it

5. **Run checks after fixing**

```bash
$PLUGIN_DIR/scripts/run-checks.sh --dir .
```

Verify no new high/critical findings were introduced by the fixes.

6. **Commit fixes**

```bash
git add -A
git commit -m "fix: address AIDLC review findings

Fixed:
- {list of HIGH findings fixed}

Acknowledged (medium):
- {list of MEDIUM findings noted but not fixed, with reasoning}
"
```

7. **Report**

Tell the user what was fixed, what was acknowledged, and whether re-review is needed.
