# Agent Instructions

This repository is a computational research project created from the
[CAPTURE](https://github.com/lasseignelab/capture) project template. CAPTURE
(Custom Analysis Pipelines Tailored for Universal Reproducibility and
Efficiency) is a framework and `cap` command line interface (CLI) that provides
conventions for project structure, job execution, verified results, version
control, and standardized environments so that pipelines are reproducible and
FAIR (Findable, Accessible, Interoperable, and Reusable).

Coding agents working in this repository must build pipelines that follow
CAPTURE conventions and must record every change in `AGENTS_CHANGELOG.md`.

`CLAUDE.md` is a symlink to this file so that all coding agents share the
same instructions. Edit `AGENTS.md`, never replace the symlink.

Shared agent skills live in `.agents/skills/<name>/SKILL.md`. `.claude` is a
symlink to `.agents` so Claude Code finds the same skills. Add or edit skills
under `.agents/`, never replace the symlink. Available skills:

- `slurm` - Writing, submitting, monitoring, and debugging Slurm jobs with
  `cap run`.

## Required: record all changes in AGENTS_CHANGELOG.md

Every time you create, modify, rename, or delete files in this repository, add
an entry to `AGENTS_CHANGELOG.md` before finishing your task. This includes
code, configuration, documentation, verifications, and container files. The
changelog lets researchers and reviewers see what was generated or changed by
an agent and why.

- Add new entries at the top of the file, below the `# Agents Changelog`
  heading (create the heading if the file is empty).
- Use one entry per task or session, not one per file.
- Never rewrite or delete existing entries. If an earlier change was wrong,
  add a new entry describing the correction.
- Do not record secrets, credentials, or private data in the changelog.
- When working on the CAPTURE project template repository itself, record
  changes in `TEMPLATE_CHANGELOG.md` instead, using the same format.

Use this format for each entry:

```markdown
## YYYY-MM-DD - Short summary of the change

- **Agent:** Agent name and model (e.g. Claude Code, Claude Opus 5.5)
- **Request:** One or two sentences describing what the user asked for.
- **Changes:**
  - `path/to/file` - Created/Modified/Deleted: what changed and why.
- **Verification:** Commands run to test the change (e.g. `cap run -n ...`,
  `cap verify ...`) and their outcome, or "Not run" with the reason.
- **Notes:** Assumptions, follow-up work, or anything a reviewer should check.
```

## CAPTURE overview

The `cap` CLI must be installed and on the `PATH` (check with `cap version`).
If it is missing, ask the user to install it rather than installing it
yourself:

```bash
curl -sSL https://raw.githubusercontent.com/lasseignelab/capture/refs/heads/main/install.sh | bash
source ~/.bash_profile
```

Full documentation:
[README.md](https://github.com/lasseignelab/capture/blob/main/README.md) and
[DOCUMENTATION.md](https://github.com/lasseignelab/capture/blob/main/DOCUMENTATION.md).
Use `cap help` and `cap help COMMAND` for the installed version's details.

All `cap` commands that operate on the project (`cap run`, `cap verify`,
`cap env`) must be executed from the project root directory.

## Project structure

Put files where CAPTURE expects them. Do not invent new top-level
directories without asking.

```
<project-root>/
|-- .agents/
|   `-- skills/        Shared coding agent skills (<name>/SKILL.md)
|-- .claude -> .agents Symlink so Claude Code uses the shared skills
|-- bin/
|   |-- container/     External containers (Dockerfiles, Singularity .sif files)
|   `-- env/           Conda and other runtime environment files
|-- config/
|   |-- pipeline.sh    Bootstraps CAP_PROJECT_NAME and CAP_RANDOM_SEED (set by cap new)
|   `-- environments/
|       |-- default.sh Reproducible configuration that works for everyone
|       `-- <lab>.sh   Optional author/lab specific configuration
|-- data/              Downloaded and intermediate data (not committed)
|-- doc/               Project documentation and images
|-- logs/              Job logs written by cap run (not committed)
|-- results/           Generated analysis results
|-- src/               Pipeline job scripts run with cap run
|-- verifications/     Verification scripts and their committed .out files
|-- AGENTS.md          These instructions (CLAUDE.md symlinks here)
|-- AGENTS_CHANGELOG.md
|-- DEVELOPMENT.md
`-- README.md
```

`src/example.sh` and `verifications/example.sh` are examples from the template.
Leave them alone unless the user asks to remove or replace them.

## Writing pipeline jobs (`src/`)

Pipeline steps are Bash job scripts in `src/` that are run with `cap run`.

- Name jobs with a numeric prefix in execution order and a descriptive name,
  e.g. `src/01_download.sh`, `src/02_align.sh`, `src/03_quantify.sh`.
- Start each job with `#!/bin/bash`. Add Slurm resource requests as
  `#SBATCH` lines directly after the shebang; `cap run` keeps them and
  injects the CAPTURE helper functions after them. Every job includes
  `#SBATCH --ntasks=1`, `#SBATCH --cpus-per-task=1`, and `#SBATCH --mem=...`
  by default (see the `slurm` skill). Do not set `--job-name`,
  `--output`, or `--error`; `cap run` sets these and writes logs to `logs/`.
- Reference project locations with the CAPTURE environment variables instead
  of hard-coded or relative paths. Batch jobs run with `src/` as the working
  directory, so relative paths like `data/...` will break:
  - `CAP_PROJECT_PATH`, `CAP_DATA_PATH`, `CAP_RESULTS_PATH`, `CAP_LOGS_PATH`,
    `CAP_VERIFICATIONS_PATH`, `CAP_CONTAINER_PATH`, `CAP_ENV_PATH`
  - `CAP_PROJECT_NAME`, `CAP_ENVIRONMENT`
  - `CAP_RANDOM_SEED` - use it to seed every random number generator
    (R `set.seed`, Python `random`/`numpy`, tool `--seed` options).
- Never hard-code user-specific paths (home directories, lab storage, scratch
  space) in `src/` scripts. Put them in a non-default environment file (see
  below).
- Jobs should be idempotent and safe to rerun.
- Larger R/Python code may live in `src/` alongside the job that calls it
  (e.g. `src/02_normalize.sh` running `Rscript "$CAP_PROJECT_PATH/src/02_normalize.R"`).

### Job helper functions

These are available inside any job run with `cap run`:

- `cap_data_download [options] URL` - Downloads into `CAP_DATA_PATH`; skips
  the download if the file/directory (or a `cap_data_link` symlink) already
  exists. Options: `--md5sum=SUM`, `--unzip`, `--subdirectory DIR`,
  `--source-file-name NAME`. Always use this for input data and provide
  `--md5sum` when the checksum is known.

  Do not use `--unzip` by default. Keep downloads compressed, since many
  tools read compressed files directly (e.g. `.fastq.gz`, `.fa.gz`, `.gtf.gz`)
  and compressed files save space. Use `--unzip` only when the next tool
  cannot read the compressed file or the download is an archive that must be
  extracted, such as a reference directory packaged as `.tar.gz`.

  ```bash
  cap_data_download \
    --subdirectory "reference" \
    "https://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.gtf.gz"

  # Exception: Cell Ranger needs the extracted reference directory.
  cap_data_download \
    --unzip \
    --subdirectory "reference" \
    --md5sum="37c51137ccaeabd4d151f80dc86ce0b3" \
    "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCm39-2024-A.tar.gz"
  ```

- `cap_container [-c singularity] REFERENCE` - Pulls a Docker image
  (`<namespace>/<repository>:<tag>`) or builds a Singularity `.sif` into
  `CAP_CONTAINER_PATH` if not already present. Prefer setting
  `CAP_CONTAINER_TYPE=singularity` in a `caprc` over `-c`. Always pin a
  specific tag, never `latest`.
- `cap_array_value FILE [INDEX]` - Returns the line at a zero-based index of
  an array file, defaulting to `SLURM_ARRAY_TASK_ID`. Use with
  `#SBATCH --array=...` for per-sample jobs:

  ```bash
  sample=$(cap_array_value "$CAP_DATA_PATH/sample_list.array")
  ```

### Running jobs

```bash
cap run -n src/01_download.sh        # Dry run: show environment and job code
cap run src/01_download.sh           # Run in the current terminal
cap run -s run src/01_download.sh    # Run on Slurm with srun (attached)
cap run -s batch src/01_download.sh  # Submit to Slurm with sbatch (logs in logs/)
cap run -e my_lab src/01_download.sh # Run in a specific environment
```

Prefer `cap run -n` to check a new or changed job. Ask the user before
submitting long-running or resource-heavy Slurm jobs or downloading large
datasets.

## Environments (`config/environments/`)

- `config/environments/default.sh` must contain only reproducible
  configuration that works for anyone in any Slurm environment. Reviewers
  should never have to modify it.
- Author- or lab-specific configuration (e.g. shared dataset locations) goes
  in another file such as `config/environments/my_lab.sh`, selected with
  `CAP_ENVIRONMENT` (usually set in `~/.caprc`) or `cap run -e my_lab`.
- Every pipeline must still work in the `default` environment.
- Use `cap_data_link PATH` in a lab environment file to symlink shared data
  into `CAP_DATA_PATH`; `cap_data_download` will then skip the download in
  that environment while still downloading it in the default environment.

  ```bash
  # config/environments/my_lab.sh
  cap_data_link "$MY_LAB/genome/mouse"
  ```

- Configuration load order: `config/pipeline.sh`, CAPTURE defaults,
  `/etc/caprc`, `~/.caprc`, project `.caprc`, then
  `config/environments/<CAP_ENVIRONMENT>.sh`.
- Use `cap env` (or `cap env -e NAME`) to inspect the resolved variables.

## Verifications (`verifications/`)

Each pipeline step that produces data or results should have a matching
verification script so others can confirm they reproduced the outputs.

- Name verifications after the job they check, e.g.
  `verifications/01_download.sh` for `src/01_download.sh`.
- Run with `cap verify verifications/01_download.sh`. Output is written to
  `verifications/01_download.out`. Commit both the `.sh` and `.out` files.
- Reproduction is confirmed when `git diff verifications/<name>.out` shows no
  differences.
- Helper functions:
  - `cap_verify_md5 [--select=PATTERN] [--ignore=PATTERN] FILE...` - Records
    MD5 checksums of files. Quote patterns, e.g. `cap_verify_md5 "data/*"`.
  - `cap_verify_append TEXT` - Appends text, e.g. section headings or output
    of a custom check:
    `cap_verify_append "$(python3 "$CAP_VERIFICATIONS_PATH/02_counts.py")"`.
    Custom scripts can check `CAP_VERIFICATION_DRY_RUN` (`"true"`/`"false"`).
- Only verify deterministic outputs. If a file legitimately varies between
  runs (timestamps, embedded paths), exclude it with `--ignore` or verify a
  stable summary of it with `cap_verify_append`.
- Use `cap verify -n` for a dry run and `cap md5 -n` to preview which files
  will be included.

## Containers and software environments

- Use containers (`cap_container`, Dockerfiles in `bin/container/`) or
  environment files in `bin/env/` (e.g. a conda `environment.yml`) so the
  software environment is reproducible. `bin/container/Dockerfile-template`
  is a starting point.
- Pin exact versions of tools, packages, and container tags.
- Externally obtained or locally compiled software goes in `bin/`.

## Version control

- Commit source, configuration, documentation, verification scripts, and
  verification `.out` files. Do not commit downloaded data, logs, large
  results, or secrets; respect the existing `.gitignore` files.
- Work on a feature branch and open pull requests for code review; see
  `DEVELOPMENT.md` for the recommended GitHub ruleset.
- Only commit or push when the user asks.
- MegaLinter runs on pull requests (`.mega-linter.yml`); keep shell scripts
  clean for ShellCheck.

## Documentation

When adding or changing pipeline steps, update `README.md` so its
"Dependencies OR Scripts" section describes how to reproduce the results
(the script tree with a description of each job and verification).
