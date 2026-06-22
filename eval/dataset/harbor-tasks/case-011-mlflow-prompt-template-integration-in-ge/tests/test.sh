#!/bin/bash
# Harbor verifier: run the agent-eval-harness judge engine against the agent's
# workspace and write /logs/verifier/reward.json (the judge -> reward bridge).
# Bundled config travels with the task at /tests/eval.yaml.
set -o pipefail

mkdir -p /logs/verifier

# Make the agent transcript available to stdout-based judges (e.g. pipeline_flow):
# Harbor writes the agent's output under /logs/agent, not the workspace.
cat /logs/agent/*.txt > "/workspace/stdout.log" 2>/dev/null || true

python3 -m agent_eval.harbor.reward \
  --config /tests/eval.yaml \
  --case-dir "/workspace" \
  --out-dir /logs/verifier
rc=$?

# Surface the produced artifacts to the host: Harbor downloads /logs/verifier,
# so the run-mapper can render per-case Output files in the report.
# Only copy the output paths declared in eval.yaml (not scratch files).
mkdir -p "$(dirname /logs/verifier/artifacts/rfe-tasks)" && cp -r "/workspace/artifacts/rfe-tasks" /logs/verifier/artifacts/rfe-tasks 2>/dev/null || true
mkdir -p "$(dirname /logs/verifier/artifacts/rfe-reviews)" && cp -r "/workspace/artifacts/rfe-reviews" /logs/verifier/artifacts/rfe-reviews 2>/dev/null || true
mkdir -p "$(dirname /logs/verifier/artifacts/rfe-originals)" && cp -r "/workspace/artifacts/rfe-originals" /logs/verifier/artifacts/rfe-originals 2>/dev/null || true
mkdir -p "$(dirname /logs/verifier/artifacts/auto-fix-runs)" && cp -r "/workspace/artifacts/auto-fix-runs" /logs/verifier/artifacts/auto-fix-runs 2>/dev/null || true
mkdir -p "$(dirname /logs/verifier/artifacts/review-report.html)" && cp -r "/workspace/artifacts/review-report.html" /logs/verifier/artifacts/review-report.html 2>/dev/null || true

exit $rc
