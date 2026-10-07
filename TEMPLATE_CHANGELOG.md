# Template Changelog

Changes to the CAPTURE project template itself are recorded here, newest
first. Changes made to projects created from this template belong in
AGENTS_CHANGELOG.md instead.

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
