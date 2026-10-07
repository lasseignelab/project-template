# Template Changelog

Changes to the CAPTURE project template itself are recorded here, newest
first. Changes made to projects created from this template belong in
AGENTS_CHANGELOG.md instead.

## 2026-10-07 - Keep the example FASTA download compressed

- **Agent:** Claude Code, Claude Opus 5.5
- **Request:** Remove `--unzip` from the example job to follow the new
  compressed-by-default download guidance.
- **Changes:**
  - `src/example.sh` - Modified: removed `--unzip` from the chromosome MT
    FASTA download so it stays as `.fa.gz`.
  - `verifications/example.out` - Modified: regenerated; the FASTA checksum
    now covers `Homo_sapiens.GRCh38.dna.chromosome.MT.fa.gz`.
- **Verification:** `cap run -e default src/example.sh` downloaded both files;
  `CAP_ENVIRONMENT=default cap verify verifications/example.sh` regenerated
  the `.out` file. The `samplesheet.csv` checksum is unchanged, and the
  decompressed FASTA matches the previous checksum
  (`91bd5b959db49ecbc2fdfa4b662b3e87`). The downloaded files were removed from
  `data/` afterwards.
- **Notes:** Supersedes the note in the previous entry that `src/example.sh`
  still used `--unzip`.

## 2026-10-07 - Keep cap_data_download files compressed by default

- **Agent:** Claude Code, Claude Opus 5.5
- **Request:** Make not using `--unzip` the default for `cap_data_download`,
  because many tools read compressed files and they save space.
- **Changes:**
  - `AGENTS.md` - Modified: told agents not to use `--unzip` by default and
    to use it only when a tool cannot read the compressed file or an archive
    must be extracted. Added a compressed GTF download as the main example and
    labeled the Cell Ranger `.tar.gz` reference as the exception.
- **Verification:** Checked that the example Ensembl GTF URL returns HTTP 200.
- **Notes:** `src/example.sh` still uses `--unzip`; changing it also changes
  `verifications/example.out`, so it was left for the user to decide.

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
