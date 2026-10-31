# Podman blueprint reference

The public input contract is `iac_blueprint.podman`. This page documents its
accepted shape and state behavior; use the linked YAML files for complete
runnable examples. Optional collections may be omitted or supplied as empty
lists. Unknown root keys are rejected during preflight. Container records may
include extra keys; only fields consumed by the role affect its behavior.

## Root blueprint

| YAML path | Type / shape | Required, default, or condition | Accepted values / validation | Purpose and observable behavior |
|---|---|---|---|---|
| `iac_blueprint.podman` | Mapping | Required by role entry point | Unknown root keys are rejected during preflight | Root contract for Podman configuration and resources. |
| `iac_blueprint.podman.configuration` | Mapping | Optional | If present, must be a mapping | Host-level Podman configuration. |
| `iac_blueprint.podman.directories` | List of shared directory records | Optional; defaults to `[]` | Must be a list; record schema below/shared docs | Declared directories are managed in host-resource states. |
| `iac_blueprint.podman.files` | List of shared file records | Optional; defaults to `[]` | Must be a list; record schema below/shared docs | Declared files are managed in host-resource states. |
| `iac_blueprint.podman.binds` | List of shared bind records | Optional; defaults to `[]` | Must be a list; record schema below/shared docs | Declares persistent directory bind mounts. |
| `iac_blueprint.podman.cron` | List of shared cron records | Optional; defaults to `[]` | Must be a list; record schema below/shared docs | Declares cron jobs managed by host-resource states. |
| `iac_blueprint.podman.containers` | List of container records | Optional; defaults to `[]` | Must be a list | Declares containers managed by container lifecycle states. |

### Configuration and network

| YAML path | Type / shape | Required, default, or condition | Accepted values / validation | Purpose and observable behavior |
|---|---|---|---|---|
| `configuration.network` | Mapping of setting names to values | Optional under `configuration` | Must be a mapping; null-valued entries are skipped | Each non-null entry is rendered under `[network]` in `/etc/containers/containers.conf`, preserving unrelated sections and refusing an unmanaged duplicate `[network]` section. |
| `configuration.network.<setting>` | String, scalar, or null | Optional | String values are quoted; other non-null values are rendered as supplied | Sets one Podman network configuration entry; for example `network_backend: "netavark"`. |

The role manages the resulting host configuration rather than replacing
unrelated container configuration.

## Shared host-resource collections

The four collections below use the `iac_`-prefixed shared-task record schemas.
The [shared task documentation](../tasks/shared/README.md) is authoritative for
the complete optional fields and their shared-task behavior.

| Blueprint collection | Record shape | Required / conditions | Role-specific validation and effect |
|---|---|---|---|
| `directories` | Mapping per record; shared `iac_fs_directories` record | Each record requires non-empty string `path`; optional `selinux` must be a mapping | Managed as host directories. |
| `files` | Mapping per record; shared `iac_fs_files` record | Preflight requires non-empty string `path` and exactly one of `content` or absolute-path `src`; optional `mode` is string and `selinux` is a mapping | `src` normally identifies a controller-side source; when `remote_src: true`, it identifies a source path on the target host. See [shared file documentation](../tasks/shared/README.md). Shared file handling may expose diffs and has no secret-safe mode default; use restrictive modes and avoid inline secrets unless exposure is acceptable. |
| `binds` | Mapping per record; shared `iac_fs_binds` record | Requires absolute string `source` and `target`; `purge_on_absent` and `move_from_target`, if present, are booleans | Manages a persistent bind mount; migration and removal effects are defined by shared docs. |
| `cron` | Mapping per record; shared `iac_cron` record | Requires non-empty string `name` and `cron_file`; `job` is required for `present` and `install` states | Manages cron entries; shared docs define scheduling fields and absent behavior. |

Directory and file records additionally inherit the shared fields such as
ownership, group, mode, and SELinux options described in the linked schema.
Bind mount data migration or purge is consequential; review shared-task
behavior before setting those options.

## Containers

### Container record fields

| Field | Type / shape | Required, default, or condition | Accepted values / validation | Purpose and observable behavior |
|---|---|---|---|---|
| `preset` | String or null | Optional | Must name a configured `podman_container_presets` entry; empty strings are invalid | Supplies preset image and parameters; explicit record values override preset values. |
| `image` | Non-empty string | Optional if a preset supplies an image; otherwise required | Cannot be blank | Image used to create the container. |
| `parameters` | Mapping | Optional | Keys are limited to options in the nested table; this is checked during preflight | Podman create options; effective `name` is required for lifecycle operations. |
| `environment` | Mapping of variable names to scalar values | Optional | Keys match `^[A-Za-z_][A-Za-z0-9_]*$`; values may be strings, numbers, booleans, or null, but not lists/mappings | Non-null entries become `--env KEY=value` arguments. |
| `command` | String, sequence, or null | Optional | Preflight checks only that the value is a string, sequence, or null; it does not require a non-empty sequence or string items, nor reject quoting/shell metacharacters in simple strings | Command and arguments after the image. Prefer argv lists; simple strings are split on whitespace. |
| `quadlet` | Boolean | Optional; false when omitted | `true` selects Quadlet; otherwise ordinary container handling | Uses a rootful Quadlet unit at `/etc/containers/systemd/<name>.container`; requires the Podman systemd generator and cgroup v2. |

### `parameters` options

Accepted option names are deliberately allow-listed. Mapping values are not
accepted. Scalar values render as `--key value`; `true` renders as a flag,
`false` and null are omitted. `volume` may be a scalar or list of scalar
values; list options are emitted as repeated flags.

| Option | Type / shape | Required, default, or condition | Accepted values / validation | Purpose / Quadlet behavior |
|---|---|---|---|---|
| `name` | String | Required for container lifecycle states, directly or from preset | Matches `^[A-Za-z0-9][A-Za-z0-9_.-]*$` | Container identity. |
| `hostname` | Scalar | Optional | Mapping and non-volume/publish sequence values rejected | Sets container hostname; supported by Quadlet. |
| `ip` | Scalar | Optional | Mapping and non-volume/publish sequence values rejected | Requests container IP; supported by Quadlet. |
| `publish` | Scalar or list | Optional | Scalar values; list entries are rendered as repeated `--publish` values | Publishes ports; supported by Quadlet. |
| `privileged` | Scalar/boolean | Optional | A true boolean emits the flag; false/null omitted | Requests privileged container mode; not translated by Quadlet. |
| `systemd` | Scalar/boolean | Optional | A true boolean emits the flag; false/null omitted | Controls Podman's systemd-container option; not translated by Quadlet. |
| `volume` | Scalar or list of scalars | Optional | Nested mappings/lists rejected | Adds volume arguments; supported by Quadlet. |
| `network` | Scalar | Optional | Mapping and unsupported sequence values rejected | Selects/attaches network; supported by Quadlet. |
| `tty` | Scalar/boolean | Optional | A true boolean emits the flag; false/null omitted | Requests a TTY; not translated by Quadlet. |
| `interactive` | Scalar/boolean | Optional | A true boolean emits the flag; false/null omitted | Requests interactive mode; not translated by Quadlet. |
| `user` | Scalar | Optional | Mapping and unsupported sequence values rejected | Sets container user; supported by Quadlet. |

Quadlet additionally supports only `name`, `hostname`, `ip`, `publish`,
`volume`, `network`, and `user`. Switching to Quadlet fails if an existing
container lacks a role-owned unit. Bootstrap options are incompatible with
Quadlet.

### Experimental bootstrap fields

These options are experimental and apply when starting a regular container;
they cannot be combined with `quadlet: true`.

| Field | Type / shape | Required, default, or condition | Accepted values / validation | Purpose and observable behavior |
|---|---|---|---|---|
| `bootstrap_packages` | Sequence | Optional | Preflight requires a sequence (not a string), but does not validate its items as strings; package-manager availability is checked/used during bootstrap | Installs packages inside the container. |
| `bootstrap_services` | Sequence | Optional | Preflight requires a sequence (not a string), but does not validate its items as strings; working `systemctl` is needed during bootstrap | Enables and starts named services. |
| `bootstrap_ssh_root_access` | Boolean-like value | Optional; false when omitted | Preflight does not enforce a boolean type; enabling is a high-risk compatibility feature | Sets up root SSH access and generated host SSH key artifacts. |
| `bootstrap_ssh_authorized_keys_contents` | Value consumed as string or sequence | Optional | Preflight does not validate its type or list items | Adds controller-supplied public keys to root's `authorized_keys`. Additive only; removing a key from input does not revoke it. |
| `bootstrap_ssh_authorized_keys_files` | Value consumed as string or sequence of controller-side file paths | Optional | Preflight does not validate its type or list items; file contents are read on the controller | Adds public keys read from controller-side files. |
| `bootstrap_ssh_private_key_path` | Path-like value | Optional; derived per container under the resolved SSH directory | Preflight does not validate its type, absoluteness, whitespace, or path components; path handling occurs during bootstrap | Overrides the private key artifact path used by root SSH bootstrap. |
| `bootstrap_ssh_known_hosts_path` | Path-like value | Optional; defaults beside the private key | Preflight does not validate its type, absoluteness, whitespace, or path components; path handling occurs during bootstrap | Overrides the known-hosts artifact path used by root SSH bootstrap. |

Root SSH access and privileged systemd containers are high-risk compatibility
features. Review [experimental feature details](experimental-features.md) for
their workflows and limitations.

## States

`state` defaults to `present`. Every invocation validates the complete
blueprint before state-specific work; `validate` does not inspect host runtime
state or mutate the host.

| State | Default / condition | Validation scope | Observable behavior |
|---|---|---|---|
| `validate` | Explicit | Validates blueprint and state | Does not inspect host runtime state or mutate the host. |
| `present` | Default | Complete blueprint; cron records require `job` | Ensures Podman and declared host-side resources; does not create containers. |
| `absent` | Explicit | Complete blueprint | Removes Podman and declared host-side resources; configured containers are not implicitly removed. |
| `install` | Explicit | Complete blueprint; cron records require `job` | Runs complete installation/configuration workflow, including configured host resources and containers. |
| `uninstall` | Explicit | Complete blueprint | Reverses role installation workflow for configured resources. |
| `container_present` | Explicit | Container lifecycle records need effective `parameters.name` | Creates or converges configured containers. |
| `container_absent` | Explicit | Container lifecycle records need effective `parameters.name` | Stops and removes only configured containers; unknown containers are not reconciled. |
| `container_started` | Explicit | Container lifecycle records need effective `parameters.name` | Starts configured containers and requested bootstrap behavior. |
| `container_stopped` | Explicit | Container lifecycle records need effective `parameters.name` | Stops configured containers while retaining their definitions. |

## Platforms and examples

Declared support: Rocky Linux 9/10 and Red Hat Enterprise Linux 9/10. Current
Molecule runtime coverage is Rocky Linux 9/10 only.

Examples: [minimal](examples/inventory-minimal.yml), [host configuration](examples/inventory-host-config.yml),
[basic container](examples/inventory-container-basic.yml), [multiple containers](examples/inventory-multi-container.yml),
[preset](examples/inventory-preset-rhel9.yml), [systemd/SSH](examples/inventory-systemd-sshd.yml),
[controller SSH keys](examples/inventory-ssh-controller-keys.yml), and
[proxy/SSH/PostgreSQL](examples/inventory-proxy-ssh-postgresql.yml). Runnable playbook
examples are also available: [states](examples/playbook-states.yml) and
[proxy/SSH/PostgreSQL](examples/playbook-proxy-ssh-postgresql.yml).
