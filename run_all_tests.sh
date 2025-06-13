#!/usr/bin/env bash
# Automated regression test runner for DESeq workflows.
# See TESTS_README.md for details.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ROOT_DIR/test_logs"
mkdir -p "$LOG_DIR"
CWLTOOL_OPTS=${CWLTOOL_OPTS:-"--quiet"}

run_test() {
  local workflow=$1
  local yaml=$2
  local wf_name=$(basename "$workflow")
  local yaml_name=$(basename "$yaml" .yml)
  local outdir="$LOG_DIR/$wf_name/$yaml_name"
  mkdir -p "$outdir"
  echo "[RUN] $wf_name ← $yaml_name" | tee "$outdir/run.log"
  cwltool $CWLTOOL_OPTS --outdir "$outdir" "$workflow" "$yaml" &>> "$outdir/run.log"
  echo "[OK ] $wf_name ← $yaml_name" | tee -a "$outdir/run.log"
}

echo "=== Running DESeq Wald workflow tests ==="
for yaml in "$ROOT_DIR/my_local_test_data/deseq_standard_tests/inputs"/*.yml; do
  run_test "$ROOT_DIR/workflows/deseq.cwl" "$yaml"
done

echo "=== Running DESeq LRT Step-1 workflow tests ==="
if compgen -G "$ROOT_DIR/my_local_test_data/deseq_lrt_step_1_tests"/*.yml > /dev/null; then
  for yaml in "$ROOT_DIR/my_local_test_data/deseq_lrt_step_1_tests"/*.yml; do
    run_test "$ROOT_DIR/workflows/deseq-lrt-step-1-test.cwl" "$yaml"
  done
fi

echo "=== Running DESeq LRT Step-2 workflow tests ==="
for yaml in "$ROOT_DIR/my_local_test_data/deseq_lrt_step_2_tests/inputs"/*.yml; do
  run_test "$ROOT_DIR/workflows/deseq-lrt-step-2-test.cwl" "$yaml"
done

echo "=== All tests finished ===" 