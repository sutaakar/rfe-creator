---
name: rfe.submit
description: Submit or update RFEs in Jira. Creates new RHAIRFE tickets for new RFEs, or updates existing tickets for RFEs fetched from Jira. Use after /rfe.review.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

You are an RFE submission assistant. Your job is to create or update RHAIRFE Jira tickets from reviewed RFE artifacts.

All submission goes through Python scripts that use the Jira REST API directly with Basic Auth (`JIRA_SERVER`, `JIRA_USER`, `JIRA_TOKEN` env vars), not the Atlassian MCP server. This ensures the exact sequence of Jira API calls is deterministic and not dependent on LLM tool-calling decisions.

**IMPORTANT**: These are YOUR instructions to execute NOW. Start with Step 0 immediately. Each step must produce tool calls, not text descriptions.

**This skill is non-interactive.** Do not prompt the user for confirmation before submitting. Run the script directly.

## Step 0: Check Credentials

Check if `JIRA_SERVER`, `JIRA_USER`, and `JIRA_TOKEN` environment variables are set. If not, tell the user:

> RFE submission requires Jira API credentials. Set these environment variables:
> ```
> export JIRA_SERVER=https://your-site.atlassian.net
> export JIRA_USER=your-email@example.com
> export JIRA_TOKEN=your-api-token
> ```
> To create an API token, go to https://id.atlassian.com/manage-profile/security/api-tokens
>
> After environment variables are set, re-run `/rfe.submit`.

## Step 1: Run Submission

Pass `--dry-run` if specified in `$ARGUMENTS`.

```bash
TIMESTAMP=$(python3 scripts/state.py timestamp)
python3 scripts/submit.py --artifacts-dir artifacts --generate-report --report-timestamp "$TIMESTAMP"
```

## Step 2: Report Results

After the script completes, read `artifacts/rfes.md` (rebuilt by the script) and report the results.

If the script fails, report the error and suggest the user check credentials or use `--dry-run` to validate locally.

## Labeling Scheme

The scripts automatically apply labels based on what happened during the pipeline:

| Label | When applied |
|-------|-------------|
| `rfe-creator-auto-created` | Ticket was created by the pipeline (new RFEs, not updates) |
| `rfe-creator-auto-revised` | Ticket content was modified by automation (review frontmatter `auto_revised: true`) |
| `rfe-creator-split-original` | Parent ticket that was decomposed into smaller RFEs |
| `rfe-creator-split-result` | Child ticket produced by splitting another RFE |
| `rfe-creator-needs-attention` | Automation couldn't fully resolve all issues — human review needed (review frontmatter `needs_attention: true`) |
| `rfe-creator-autofix-rubric-pass` | RFE passed review (recommendation = "submit") — excluded from future auto-fix JQL queries |
| `rfe-creator-feasibility-pass` | Technical feasibility check returned `feasible` |
| `rfe-creator-feasibility-fail` | Technical feasibility check returned `infeasible` |
| `rfe-creator-feasibility-unknown` | Technical feasibility check returned `indeterminate` |

The three `rfe-creator-feasibility-*` labels are mutually exclusive: on each submit, the matching label is added and any others present in the ticket's `original_labels` are removed. Rejected RFEs have any feasibility labels stripped (no add).

$ARGUMENTS
