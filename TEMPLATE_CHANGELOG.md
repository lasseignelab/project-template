# Template Changelog

Changes to the CAPTURE project template itself are recorded here, newest
first. Changes made to projects created from this template belong in
AGENTS_CHANGELOG.md instead.

## 2026-10-07 - Add default Slurm resource requests to the examples

- **Agent:** Claude Code, Claude Opus 5.5
- **Request:** Add the default Slurm options to the example scripts.
- **Changes:**
  - `src/example.sh` - Modified: added `#SBATCH` lines for `--ntasks=1`,
    `--cpus-per-task=1`, `--mem=4G`, and `--time=00:30:00`.
  - `verifications/example.sh` - Modified: added the same `#SBATCH` lines,
    since `cap verify -s` can also run on Slurm.
- **Verification:** `cap run -n -e default src/example.sh` showed the
  `#SBATCH` lines kept before the injected helpers.
  `CAP_ENVIRONMENT=default cap verify -n verifications/example.sh` completed
  without errors. `verifications/example.out` is unchanged.
- **Notes:** A 30 minute time limit is enough for the small example
  downloads.

## 2026-10-07 - Require default Slurm resource requests

- **Agent:** Claude Code, Claude Opus 5.5
- **Request:** Make sure all Slurm scripts have `--cpus-per-task=1`, `--mem`,
  and `--ntasks=1` options by default.
- **Changes:**
  - `.agents/skills/slurm/SKILL.md` - Modified: every job script now starts
    with `--ntasks=1`, `--cpus-per-task=1`, `--mem=4G`, and `--time`; both
    examples use these defaults, with guidance on when to raise CPUs and
    memory.
  - `AGENTS.md` - Modified: the job script rules require the default
    `--ntasks`, `--cpus-per-task`, and `--mem` requests.
- **Verification:** Not run; documentation-only change. No existing `src/`
  scripts contain `#SBATCH` lines.
- **Notes:** 4G was chosen as the default memory request. `src/example.sh`
  was left unchanged per the instructions about template examples.

## 2026-10-07 - Add TEMPLATE_CHANGELOG.md for template changes

- **Agent:** Claude Code, Claude Opus 5.5
- **Request:** Create a changelog just for changes to the project template and
  move the template change entry out of `AGENTS_CHANGELOG.md`.
- **Changes:**
  - `TEMPLATE_CHANGELOG.md` - Created: changelog for template changes.
  - `AGENTS_CHANGELOG.md` - Modified: moved the `.agents`/Slurm skill entry
    here so that file only records changes to projects created from the
    template.
  - `AGENTS.md` - Modified: told agents working on the template itself to
    record changes in `TEMPLATE_CHANGELOG.md`.
- **Verification:** Not run; documentation-only change.
- **Notes:** None.

## 2026-10-07 - Add shared .agents directory and Slurm skill

- **Agent:** Claude Code, Claude Opus 5.5
- **Request:** Add a `.agents` directory with a `.claude` symlink to it, then
  add a Slurm skill.
- **Changes:**
  - `.agents/skills/slurm/SKILL.md` - Created: skill covering `#SBATCH`
    resource requests, array jobs with `cap_array_value`, submitting with
    `cap run -s`, and monitoring/debugging with `squeue`, `sacct`, and `seff`.
  - `.claude` - Created: symlink to `.agents` so Claude Code loads the shared
    skills.
  - `AGENTS.md` - Modified: documented `.agents/`, the `.claude` symlink, and
    the available skills in the instructions and project structure.
- **Verification:** Not run; documentation-only change. Checked that
  `.claude` resolves to `.agents`.
- **Notes:** The skill avoids cluster-specific partitions and accounts so it
  works in any Slurm environment; it suggests `SBATCH_PARTITION` and
  `SBATCH_ACCOUNT` for per-user cluster settings.
