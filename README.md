# tf-state-refactoring

Renaming, moving, adopting and forgetting resources in Terraform state without destroying anything. A script walks one state through five refactors and asserts what `terraform plan` says at each step.

> **What is verified.** `demo.sh` ran on 2026-10-17 with Terraform 1.16.5 (Git Bash on Windows): **15 checks passed, 0 failed**. CI runs the same script on Linux. All resources are `hashicorp/local` files plus `terraform_data`, so no cloud account is involved. Real cloud resources have behaviours this does not model (see limits).

## The five stages (`stages/`)

| Stage | Change | What the plan shows |
|---|---|---|
| `01-initial` | three resources | created |
| `02a-rename-naive` | rename `config` to `app_config` with **no** `moved` block | `1 to add, 1 to destroy`: the mistake |
| `02b-rename-moved` | same rename **with** a `moved` block | `has moved to`, and `0 to add, 0 to change, 0 to destroy` |
| `03-into-module` | move that resource into `module.app` | a second `moved` block; the chain is followed; nothing recreated |
| `04-import` | resource lost from state, adopted back with an `import` block | `1 to import`, `0 to add` |
| `05-removed` | stop managing `legacy` without deleting it, using a `removed` block with `destroy = false` | "will no longer be managed by Terraform, but will not be destroyed"; the file stays on disk |

Run it: `./demo.sh` (Terraform 1.7+, bash). It works in a gitignored `work/` directory.

## Why declare it in code instead of `terraform state mv`

`moved`, `import` and `removed` blocks are reviewed in a pull request, show up in `plan` before anything changes, and apply the same way in every environment that shares the module. `state mv` is a one-off command on one state file that nobody reviews, so each environment must be remembered and run by hand.

## Honest limits

- **The import is a stand-in.** `local_file` does not support import, so stage 04 uses `terraform_data`: the script reads its generated id, runs `terraform state rm`, then imports the same id back. That proves the mechanics and that the id matches, but the plan also shows `1 to change` because the imported object has no `input` yet. With a real cloud resource the import block usually needs a matching config to reach a clean plan.
- **A bug caught while building it:** my first version of the id extraction produced a junk id and the import step still passed. The demo now asserts the imported id equals the original.
- State is local; remote backends, locking and state surgery on shared state are not covered.
- A `moved` block is kept in stage 03 for the old address too. When to delete old `moved` blocks (after every environment has applied them) is a team decision this repo does not make.
- `removed` needs Terraform 1.7+, `import` blocks 1.5+.
