---
name: slurm
description: Write, submit, and monitor Slurm jobs for this CAPTURE project. Use when adding #SBATCH resource requests to src/ job scripts, building array jobs over samples, submitting jobs with `cap run -s`, checking job status or logs, or debugging failed, pending, or out-of-memory Slurm jobs.
---

# Slurm jobs in a CAPTURE project

Pipeline jobs in `src/` run on Slurm through `cap run`, never by calling
`sbatch` or `srun` directly. `cap run` loads the CAPTURE environment, injects
the helper functions, names the job, and writes logs to `logs/`. Run every
`cap` command from the project root.

## Resource requests

Put `#SBATCH` lines directly after `#!/bin/bash`, before any other code.
`cap run` keeps them in place and injects the helpers after them.

Every job script in `src/` starts with these default resource requests:

```bash
#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00

set -euo pipefail

threads="${SLURM_CPUS_PER_TASK:-1}"
```

- Never set `--job-name`, `--output`, or `--error`; `cap run` sets them.
- Always include `--ntasks=1`, `--cpus-per-task=1`, and `--mem`, even for
  jobs that are usually run in the terminal, so that `cap run -s` never falls
  back to cluster defaults. Also set `--time`.
- Keep `--ntasks=1`; jobs run one process, and multithreaded tools scale with
  `--cpus-per-task`. Use more tasks only for MPI programs, and ask first.
- Raise `--cpus-per-task` above 1 only when the tool is multithreaded and is
  given the thread count. Set `--mem` to the job's expected need (4G is the
  starting point) and adjust from `seff` results rather than requesting a
  whole node.
- Pass the allocation to tools instead of hard-coding thread counts:
  `"${SLURM_CPUS_PER_TASK:-1}"` keeps the job working outside Slurm too.
- For GPUs use `#SBATCH --gres=gpu:1` (add a type only if the user's cluster
  requires one).
- Keep `src/` portable. Partitions, accounts, and QOS names are
  cluster-specific, so do not hard-code them in `src/` scripts without asking
  the user. Researchers can set them for their own cluster with Slurm's input
  environment variables, e.g. `export SBATCH_PARTITION=short` or
  `SBATCH_ACCOUNT=my_lab` in their shell profile. When a time limit implies a
  partition, choose the time first and tell the user which partitions fit.
- Discover the local cluster rather than guessing:
  `sinfo -s` (partitions and time limits), `sinfo -o "%P %c %m %G"`
  (CPUs, memory in MB, GPUs per partition), `sacctmgr show assoc user=$USER`
  (accounts and QOS).

## Array jobs (one task per sample)

Use an array file in `CAP_DATA_PATH` (one value per line) with
`cap_array_value`, which reads the line at `SLURM_ARRAY_TASK_ID` (zero-based).

```bash
#!/bin/bash
#SBATCH --array=0-11%4
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=04:00:00

set -euo pipefail

sample=$(cap_array_value "$CAP_DATA_PATH/sample_list.array")
output_dir="$CAP_DATA_PATH/aligned/$sample"

if [[ -s "$output_dir/$sample.bam" ]]; then
  echo "Skipping $sample: output already exists"
  exit 0
fi
mkdir -p "$output_dir"
# ... run the tool with "${SLURM_CPUS_PER_TASK:-1}" threads ...
```

- The array range must be `0-(N-1)` for an N-line array file; count with
  `wc -l < data/sample_list.array`. `%4` limits concurrent tasks.
- Generate the array file in an earlier job (e.g. `src/01_download.sh`) so it
  is reproducible, not by hand.
- Keep each task idempotent, as above, so a partially failed array can simply
  be resubmitted.
- Test one task locally before submitting the whole array:
  `SLURM_ARRAY_TASK_ID=0 cap run src/02_align.sh`.

## Running and submitting

```bash
cap run -n src/02_align.sh           # Dry run: check environment and job code
cap run -s run src/02_align.sh       # srun, output stays in the terminal
cap run -s batch src/02_align.sh     # sbatch, output goes to logs/
cap run -e my_lab -s batch src/02_align.sh
```

- Always do a `cap run -n` dry run first.
- Ask the user before submitting long-running, large array, GPU, or otherwise
  resource-heavy jobs. Tell them the requested resources and how many tasks
  will be submitted.
- `cap run -s batch` prints the job ID and the `cat logs/...` command for the
  job's log; report both to the user.
- Chain dependent steps only when the user asks, by submitting the next step
  after the first finishes successfully, rather than guessing at dependencies.

## Monitoring and debugging

```bash
squeue -u "$USER"                                  # Pending and running jobs
squeue -j JOBID -o "%.18i %.9P %.8T %.10M %.20R"   # State and pending reason
sacct -j JOBID --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS
seff JOBID                                         # CPU and memory efficiency
scancel JOBID                                      # Cancel (ask the user first)
ls -t logs/ | head                                 # Newest job logs
```

Read the job's log in `logs/` before changing anything. Common failures:

| Symptom | Likely cause | Fix |
|---|---|---|
| State `OUT_OF_MEMORY`, or `oom-kill` in the log | `--mem` too low | Raise `--mem` using `MaxRSS` from `sacct` plus headroom |
| State `TIMEOUT` | `--time` too short | Raise `--time`; check the partition limit with `sinfo -s` |
| Pending with `Resources` or `Priority` | Cluster is busy | Wait, or request fewer resources |
| Pending with `PartitionTimeLimit` or `QOSMaxWallDurationPerJobLimit` | Time exceeds the partition limit | Lower `--time` or choose another partition |
| `No such file or directory` for `data/...` | Relative path; batch jobs run in `src/` | Use `$CAP_DATA_PATH` and the other `CAP_*` variables |
| `cap_array_value` returns nothing | Array range exceeds file lines | Match `--array` to `wc -l` of the array file |
| Array task failed | Single sample problem | Check that task's log, fix, and resubmit (idempotent tasks skip finished samples) |

After a successful run, record outputs with the matching verification
(`cap verify verifications/NN_name.sh`) as described in `AGENTS.md`, and
record the change in `AGENTS_CHANGELOG.md`.
