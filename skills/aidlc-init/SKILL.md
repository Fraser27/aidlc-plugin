---
name: aidlc-init
description: Detect project and scaffold .aidlc.yml config
---

# AIDLC Init

Initialize AIDLC for the current project. Detects language, framework, and tools, then generates a `.aidlc.yml` configuration file.

## Steps

1. **Detect project type**

Run the detection script to identify the project:
```bash
PLUGIN_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
PROFILE=$($PLUGIN_DIR/scripts/detect-project.sh .)
```

Present the detected profile to the user:
- Language: {detected language}
- Framework: {detected framework}
- Tools: formatter, linter, security, type_check, dep_audit, test, iac_validate

2. **Check for missing tools**

Run:
```bash
$PLUGIN_DIR/scripts/install-tools.sh --profile "$PROFILE"
```

If tools are missing, ask the user if they want to install them. If yes, run:
```bash
$PLUGIN_DIR/scripts/install-tools.sh --profile "$PROFILE" --auto
```

3. **Generate .aidlc.yml**

Read the template from `$PLUGIN_DIR/templates/aidlc.yml.template`.

Customize based on detected profile:
- Uncomment the tools section and fill in detected values
- Set exclude paths appropriate to the detected language/framework
- If CDK project, add `cdk.out/` to excludes
- If Node project, add `node_modules/` and `dist/` to excludes

Present the generated config to the user for approval before writing.

4. **Write config**

After user approves, write `.aidlc.yml` to the project root.

5. **Create .aidlc/ directory**

```bash
mkdir -p .aidlc/reviews
echo "reviews/" > .aidlc/.gitignore
```

6. **Summary**

Tell the user:
- AIDLC initialized for {language} {framework} project
- Config written to `.aidlc.yml`
- Use `/aidlc-ship "description"` to start the full lifecycle
- Use `/aidlc-review` for standalone code review
