# Podman blueprint reference

The public input contract is `iac_blueprint.podman`. This page is the
authoritative schema and state reference; use the linked YAML files for
complete runnable examples.

## Top-level shape

```yaml
iac_blueprint:
  podman:
    configuration:
      network:
        network_backend: "netavark"
    directories: []
    files: []
    binds: []
    cron: []
    containers: []
```

Supported top-level keys are `configuration`, `directories`, `files`,
`binds`, `cron`, and `containers`. Unknown keys are rejected during preflight.
`configuration` and its optional `network` value must be mappings; each
resource collection must be a list. Network configuration is written to
`/etc/containers/containers.conf` while preserving unrelated sections.

Directory, file, bind, and cron records use the shared task library's
`iac_`-prefixed schemas. See [shared task documentation](../tasks/shared/README.md)
for those schemas. File records choose exactly one of `content` and `src`.
Shared file tasks pass through the requested mode without a secret-safe default
and may expose diffs; use restrictive modes and avoid inline secrets unless
that exposure is acceptable.

## Containers

Container records support `preset`, `image`, `parameters`, `environment`,
`command`, and the optional `quadlet` flag, plus the experimental bootstrap
fields listed below. The `parameters` mapping renders Podman create options.
Accepted option names are `name`, `hostname`, `ip`, `publish`, `privileged`,
`systemd`, `volume`, `network`, `tty`, `interactive`, and `user`. Unknown
options are rejected. Scalar values render as `--key value`, true booleans as
flags, false booleans are omitted, and `volume` accepts a list of scalar
values. Lifecycle operations require a safe `parameters.name` (directly or
from a preset). `command` accepts an argv list; legacy simple strings are
split on whitespace, but shell syntax and quoted arguments are rejected.

The built-in `rhel9` preset supplies image
`registry.access.redhat.com/ubi9-init` and name `rhel9`; explicit record values
override preset values. Custom presets may be configured through
`podman_container_presets`.

`quadlet: true` selects rootful Quadlet using
`/etc/containers/systemd/<name>.container`; boot activation is provided by
Quadlet's `[Install]` relationship. It requires the Podman systemd generator
and cgroup v2. Only `name`, `hostname`, `ip`, `publish`, `volume`, `network`,
and `user` parameters are translated, and bootstrap features are incompatible.
Switching to Quadlet fails if an existing container lacks a role-owned unit.
See [experimental features](experimental-features.md) for detailed lifecycle
and limitation notes.

Experimental bootstrap fields are `bootstrap_packages`, `bootstrap_services`,
`bootstrap_ssh_root_access`, `bootstrap_ssh_authorized_keys_contents`,
`bootstrap_ssh_authorized_keys_files`, `bootstrap_ssh_private_key_path`, and
`bootstrap_ssh_known_hosts_path`. Root SSH and privileged systemd containers
are high-risk compatibility features. Authorized-key management is additive;
removing a key from the blueprint does not revoke it.

## States

`state` defaults to `present`. Every invocation validates the complete
blueprint before state-specific work; `validate` does not inspect host runtime
state or mutate the host.

| State | Behavior |
|---|---|
| `validate` | Validate blueprint and state only. |
| `present` | Ensure Podman and declared host-side resources are present; does not create containers. |
| `absent` | Remove Podman and declared host-side resources; configured containers are not implicitly removed. |
| `install` | Complete install/configuration workflow, including configured host resources and containers. |
| `uninstall` | Reverse the role installation workflow for configured resources. |
| `container_present` | Create or converge the configured containers. |
| `container_absent` | Stop and remove only configured containers; unknown containers are not reconciled. |
| `container_started` | Start configured containers. |
| `container_stopped` | Stop configured containers while retaining their definitions. |

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
