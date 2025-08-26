#!/bin/bash
mamba run -n r_base Rscript /usr/local/bin/run_deseq_lrt_step_1.R "$@"
