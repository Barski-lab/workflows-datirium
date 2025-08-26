#!/bin/bash
set -euo pipefail

declare -A TOOL_ENVS=(
  [Rscript]=r_base
  [r_argparse]=r_base
  [r_pheatmap]=r_base
  [r_plotly]=r_base
  [r_tidyverse]=r_base
  [r_devtools]=r_base
  [r_modules]=r_base
  [r_BiocParallel]=r_base
  [r_Glimma]=r_base
  [r_hopach]=r_base
  [r_cmapR]=r_base
  [r_sva]=r_base
  [r_DESeq2]=r_base
  [r_EnhancedVolcano]=r_base
  [r_morpheus]=r_base
  [run_deseq_lrt_step_1.sh]=none
  [run_deseq_lrt_step_2.sh]=none
)

MISSING=()
declare -A ENV_SIZES=()

for TOOL in "${!TOOL_ENVS[@]}"; do
  ENV_NAME="${TOOL_ENVS[$TOOL]}"
  if [[ "$ENV_NAME" == "none" ]]; then
    if ! command -v "$TOOL" >/dev/null 2>&1; then
      MISSING+=("$TOOL (global)")
    fi
  elif [[ "$TOOL" == r_* ]]; then
    PKG="${TOOL#r_}"
    if ! mamba run -n "$ENV_NAME" Rscript -e "if (!requireNamespace('$PKG', quietly=TRUE)) quit(status=1)" >/dev/null 2>&1; then
      MISSING+=("R package $PKG ($ENV_NAME)")
    fi
  else
    if ! mamba run -n "$ENV_NAME" which "$TOOL" >/dev/null 2>&1; then
      MISSING+=("$TOOL ($ENV_NAME)")
    fi
  fi
  if [[ -z "${ENV_SIZES[$ENV_NAME]:-}" ]]; then
    if [ -d "/opt/conda/envs/$ENV_NAME" ]; then
      SIZE=$(du -sh "/opt/conda/envs/$ENV_NAME" 2>/dev/null | awk '{print $1}')
      ENV_SIZES[$ENV_NAME]="$SIZE"
    fi
  fi
done

echo -e "\nMamba environment sizes:" >&2
for ENV in "${!ENV_SIZES[@]}"; do
  echo "  $ENV: ${ENV_SIZES[$ENV]}" >&2
done

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "All required tools and R packages are installed and available in their mamba environments."
  exit 0
else
  echo "Missing tools or R packages: ${MISSING[*]}" >&2
  exit 1
fi
