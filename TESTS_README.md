# Automated Test Suite

This repository ships a minimal, self-contained test harness that executes the three main DESeq workflows against curated toy datasets.

---

## Prerequisites
* `cwltool` ≥ 3.1
* Docker daemon running (unless you pass `--no-container`)

Install if missing:
```bash
pip install cwltool
```

## Quick start
```bash
./run_all_tests.sh              # runs silently, logs to ./test_logs/
CWLTOOL_OPTS="--debug" ./run_all_tests.sh  # verbose mode
```

Logs and CWL outputs are stored under `test_logs/<workflow>/<yaml>/` so the repository stays tidy.

## Folder layout
```
my_local_test_data/
  deseq_standard_tests/
    inputs/      # Wald test YAMLs
    outputs/     # Example outputs (ignored by git & cursor)
  deseq_lrt_step_1_tests/
  deseq_lrt_step_2_tests/
```

## Adding a new case
1. Drop the input YAML into the relevant `inputs/` directory.
2. (Optional) Place trimmed expected outputs under `outputs/` for reference.
3. Re-run `./run_all_tests.sh` and confirm **[OK]** for the new entry.

## Continuous Integration
The same script can be called from GitHub Actions:
```yaml
- name: CWL regression tests
  run: ./run_all_tests.sh
```

You can extend the harness with `cwltest` manifests once output schemas stabilise. 