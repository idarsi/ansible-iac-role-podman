# Maturity assessment

Assessed on 2026-11-15 for `update/molecule-secret-runtime-coverage`, working
tree over `8ecd455` (not the unchanged commit alone).

**RC Readiness: 57%** (57.5/100, rounded down). **Maturity State: Alpha**.
This reconstructs the evidence baseline using the Idarsi maturity rubric's
0, 0.5, and 1 criterion multipliers. The historical 84% had no criterion
breakdown and used point increments inconsistent with that rubric; the change
is a recalibration, not a code regression from the configuration compatibility
patch. The score is retained pending reassessment; the additional narrow
runtime evidence below does not establish complete contract coverage.

## Evidence and scorecard

**Review-fix verification boundary:** the seven passing runtime runs below
predate the latest nested-output censorship, legacy-diff protection,
direct orphan parent-path guard, and direct command compatibility fixes.
They are retained as prior evidence, not passes for the revised working tree.
The tester subsequently confirmed focused lifecycle and captured-output
regressions passed after the fixes on both minimum and current toolchains.
Lifecycle exited 0 with `ok=1024` / `ok=1041` respectively; both reported
`changed=62 failed=0 rescued=5`. The five expected rescues cover direct-create
failure, Quadlet failure, both parent symlink guards, and unowned orphan
preservation. Verification reported `ok=3 changed=0 failed=0` on both.
The `-vvv --diff` captured-output repeat/legacy-migration regression, including
actual-host completion-marker checks, exited 0 on both toolchains; destroy
also exited 0 on both. The tester confirmed source SHA-256 values for
tasks/scenarios/tests and the implementation diff were unchanged.
Lifecycle automated idempotence remains unconfigured: neither verification
`changed=0` nor repeated convergence establishes lifecycle zero-change
idempotence. Other scorecard runtime statements retain the historical
seven-run evidence; no complete current-toolchain matrix pass is claimed.

The tester reports `molecule test -s default` passed in the shared
`ansible-min` environment (Ansible Core 2.15.13 / Molecule 6.0.3) on Rocky Linux
9 and 10: initial convergence changed 13/14 respectively, automated idempotence
changed 0 on both, verification reported `ok=15 changed=0 failed=0` on both,
and destroy passed. This is actual baseline idempotence evidence, not an
aggregate `include_role` assertion.

All six scenario configurations passed configuration loading/schema and
unchanged effective-environment checks on shared minimum and current
(Core 2.20.8 / Molecule 26.8.0) environments. These are not runtime passes.
The tester subsequently confirmed all seven runtime runs passed with exit 0:
all six scenarios on the shared minimum toolchain and default on the shared
current toolchain. After activating the respective shared environment, the
commands were `molecule test -s default`, `molecule test -s lifecycle`,
`molecule test -s experimental`, `molecule test -s experimental-ip`,
`molecule test -s experimental-host-user`, and
`molecule test -s experimental-rhel9-preset` sequentially on minimum, then
`molecule test -s default` on current.

Default verification reported `ok=15` per Rocky 9/10 host on both toolchains;
minimum lifecycle reported `ok=3`, experimental `ok=14`, and each other
experimental scenario `ok=18`. Every verification reported `changed=0 failed=0`.
Automated idempotence reported zero changes for both default hosts on both
toolchains and all four minimum experimental scenarios. Lifecycle does not
configure automated idempotence: its convergence reported
`ok=806 changed=41 failed=0 rescued=2`, with the two intentional censored
direct/Quadlet failure tests and cleanup assertions passing.
The tester confirmed implementation/scenario diffs were unchanged at its
final check; only README and the new assessment had changed. These results
do not claim all current-toolchain scenarios passed.

| Category / criterion | Score / maximum | Evidence and remaining limitation |
|---|---:|---|
| **Scope and public contract** | **9.5 / 12** | |
| Purpose and boundaries | 3 / 3 | README and blueprint reference describe host resources, containers, and experimental boundaries. |
| Inputs and states | 2.5 / 5 | `docs/blueprint.md` documents inputs/states, but its `absent` and nullable-preset claims conflict with implementation; see below. |
| Support contract | 4 / 4 | `defaults/main.yml`, README, TESTING, and the pinned shared-task submodule identify platforms, prerequisites, dependencies, and runtime coverage boundaries. |
| **Functional completeness** | **14 / 20** | |
| Core convergence | 8 / 8 | Default scenario passes install, host resources, and running-container verification on Rocky 9/10. |
| Applicable lifecycle | 3 / 6 | Post-fix minimum/current lifecycle passes, including direct/Quadlet failure cleanup; full public-state lifecycle coverage remains incomplete. |
| Platform and dependency handling | 1.5 / 3 | Rocky baseline passes and shared dependencies are pinned; RHEL runtime paths remain unverified. |
| Failure and rerun behavior | 1.5 / 3 | Validation, cleanup, and repeat baseline convergence provide partial evidence; failure recovery is not comprehensively demonstrated. |
| **Validation and safety** | **7.5 / 20** | |
| Preflight validation | 3 / 6 | `tasks/main.yml` invokes blueprint validation before mutation; effective container-name uniqueness and safe bind-purge scope checks are missing. |
| Secure behavior | 3 / 6 | Post-fix minimum/current lifecycle and verbose captured-output tests verify protected environment handling, legacy migration, and failure cleanup; broader security and destructive-scope gaps remain. |
| Destructive guardrails | 0 / 5 | Explicit purge authorization and Quadlet ownership checks exist, but bind purge lacks a root/resolved unsafe-path guard; detailed evidence below. |
| Check and diff behavior | 1.5 / 3 | Validation-only checks and narrow secret diff protection exist; representative mutating-state check/diff evidence is incomplete. |
| **Convergence and recovery** | **6.5 / 13** | |
| Idempotent convergence | 2.5 / 5 | Default automated idempotence passes on both Rocky versions and toolchains, plus all four minimum experimental scenarios; lifecycle idempotence remains unconfigured. |
| State transitions | 2 / 4 | Minimum lifecycle verifies container states and Quadlet-to-direct cleanup; reverse transition and unmanaged-definition preservation coverage remain incomplete. |
| Operational recovery | 2 / 4 | Cleanup and SSH rollback paths are implemented; interruption and recovery evidence remains partial. |
| **Automated testing and CI** | **14 / 25** | |
| Static quality checks | 3 / 3 | `.github/workflows/ci.yml` configures production lint, syntax, and deterministic checks; recorded static evidence supports these checks. |
| Input validation tests | 2 / 4 | `tests/blueprint-validation.yml` covers accepted/rejected inputs and failure messages; uniqueness and destructive-path cases remain gaps. |
| Functional verification | 3 / 6 | All six minimum scenarios and current default pass observable verification; other current-toolchain scenarios and broader contract coverage remain unverified. |
| Idempotence tests | 2 / 4 | Default automated zero-change checks pass; lifecycle repeat convergence alone does not establish idempotence. |
| Lifecycle and guardrail tests | 2 / 4 | Post-fix minimum/current lifecycle, intentional failure cleanup, parent symlink rejection, and unowned orphan preservation pass; broader destructive boundary and full public-state coverage remain incomplete. |
| Supported-platform matrix | 1.5 / 3 | Rocky 9/10 baseline passes; declared RHEL 9/10 lack runtime evidence. |
| CI enforcement | 0.5 / 1 | Pull-request fast checks are configured; no passing result for this working tree is claimed and no failing CI is inferred. |
| **Documentation and release hygiene** | **6 / 10** | |
| Operator documentation | 2 / 4 | README, blueprint reference, and examples exist; state and preset inconsistencies need correction. |
| Test and limitation documentation | 1 / 2 | TESTING distinguishes runtime and static coverage; this assessment separates the seven historical runs from post-fix focused passes without extrapolating to broader coverage. |
| Contribution contract | 2 / 2 | CONTRIBUTING requires coordinated blueprint, example, documentation, and test updates. |
| Repository and release metadata | 1 / 2 | License and shared-task pin exist; complete role/release metadata and compatibility evidence remain incomplete. |
| **Total** | **57.5 / 100** | **57% after rounding down.** |

## Confirmed limitations and destructive-scope finding

- `docs/blueprint.md` says `absent` does not implicitly remove configured
  containers, but `tasks/absent.yml` invokes `loop_containers.yml` with
  `task_state: "container_absent"` before removing the package and host resources.
- The reference permits `preset: null`, whereas `tasks/validate_blueprint.yml`
  requires a defined preset to be a string. Effective names after preset
  resolution also lack uniqueness validation.
- Bind validation in `tasks/validate_blueprint.yml` accepts absolute sources
  using `^/` and a boolean `purge_on_absent`; it does not reject source `/`
  with `purge_on_absent: true`. The pinned `tasks/shared/bind_absent.yml`
  checks that an existing source is a directory and requires explicit purge
  authorization, but its purge task runs
  `find . -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +` with `chdir` set to
  the source, without a root or resolved unsafe-path guard. This is a
  specific pre-existing destructive-scope defect, not a claim that all
  deletion is unguarded: explicit authorization and Quadlet ownership
  protections are acknowledged. Remediation belongs in a separate scoped
  change; neither role runtime code nor the submodule is changed here.
- RHEL runtime, boot-time activation, complete lifecycle, and representative
  check/diff, recovery, and idempotence evidence remain incomplete.

The numeric band yields **Alpha**, which is also the final state. The
absent-idempotence mandatory cap does **not** apply: automated baseline
idempotence passed. Material coverage gaps and the destructive-scope finding
also prevent Release Candidate status. No new Critical/High severity rating
is assigned by this assessment. Production approval is neither established
nor inferred.

## Smallest next steps

1. Separately guard bind purge against root and unsafe resolved paths, with
   focused rejection and authorized-safe-path tests; review the shared-task
   dependency change before updating its pin.
2. Reconcile `absent` and nullable-preset documentation with intended behavior,
   then add effective-name uniqueness validation and regression cases.
3. Extend current-toolchain runtime verification beyond default and lifecycle; retain the
   seven prior passing results without extrapolating them to untested coverage.
   Preserve the post-fix focused lifecycle and verbose captured-output evidence
   separately from historical full-scenario results.
4. Add representative lifecycle idempotence, ownership/preservation, boot,
   check/diff, recovery, and RHEL evidence, then reassess the corresponding
   criteria and CI at the resulting ref.
