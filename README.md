> **Maturity State: Beta**<br>
> **RC Readiness: 78%**

ANSIBLE-IAC-ROLE-PODMAN
=======================

**COPYRIGHT** 2026 ^(ida|arsi)$ collective  
**LICENSE** MIT License [LICENSE](LICENSE)  
**AUTHORS**
- Arsi Atomi <arsi@atomi.sh>  
- Arsi Atomi <arsi.atomi@valtori.fi>  

Overview
========

This Ansible role provides a declarative way to deploy and manage Podman hosts,
host-side support resources, and Podman containers.

Its development goal is to make repeatable Podman host and container
deployments possible with as little manual work as possible. The role uses the
`iac_blueprint` model to keep the desired state in one structured inventory
while Ansible handles the host-specific implementation.

The role manages Podman installation and configuration, shared filesystem
resources, cron entries, container creation and lifecycle, and optional
container bootstrap operations such as package installation, service startup,
and SSH root access.

The `present` and `install` states also ensure common Podman network helper
packages are installed on the host, including `slirp4netns` and `passt`. The
role uses only `ansible.builtin.*` modules and the `podman` CLI.

These operations are supported:

Operation                              | State
---------------------------------------|--------------------
Installing and configuring all         | install
Uninstalling all                        | uninstall
Ensuring Podman and host resources     | present
Removing Podman and host resources     | absent
Creating configured containers         | container_present
Removing configured containers         | container_absent
Starting configured containers         | container_started
Stopping configured containers         | container_stopped

The role supports container presets and optional bootstrap configuration for
systemd-based containers, including SSH package and service setup and
controller-provided authorized keys.

Repository checkout
===================

This role includes the shared task library as a Git submodule under
`tasks/shared`, pinned at `d70d58eeb31390d36975fb8d9c11dfab88fadc95`.

Clone the repository with submodules:

```bash
git clone --recurse-submodules https://github.com/idarsi/ansible-iac-role-podman.git
```

If you already cloned the repository without submodules, initialize them with:

```bash
git submodule update --init --recursive
```

Quick start
===========

Minimal container:

```yaml
iac_blueprint:
  podman:
    containers:
      - image: "docker.io/library/alpine:latest"
        parameters:
          name: "minimal"
        command: ["sleep", "infinity"]
```

Preset-based systemd container with SSH:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-sshd"
          publish: "2222:22"
          systemd: always
          privileged: true
          volume:
            - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
        bootstrap_packages:
          - openssh-server
        bootstrap_services:
          - sshd
        bootstrap_ssh_root_access: true
```

The systemd/root-SSH example is intentionally an explicit high-risk example:
it requires a privileged container, a host cgroup bind, and exposes SSH. Use a
non-root SSH account and an unprivileged container for normal workloads. Images
are mutable unless an immutable digest is supplied; production inventories
should pin image digests.

Documentation map
=================

Use case examples:

- [docs/inventory-minimal.yml](docs/inventory-minimal.yml)
- [docs/inventory-host-config.yml](docs/inventory-host-config.yml)
- [docs/inventory-container-basic.yml](docs/inventory-container-basic.yml)
- [docs/inventory-preset-rhel9.yml](docs/inventory-preset-rhel9.yml)
- [docs/inventory-systemd-sshd.yml](docs/inventory-systemd-sshd.yml)
- [docs/inventory-ssh-controller-keys.yml](docs/inventory-ssh-controller-keys.yml)
- [docs/inventory-proxy-ssh-postgresql.yml](docs/inventory-proxy-ssh-postgresql.yml)
- [docs/inventory-multi-container.yml](docs/inventory-multi-container.yml)

Reference and operations:

- [docs/inventory-structure.md](docs/inventory-structure.md)
- [docs/playbook-states.yml](docs/playbook-states.yml)
- [docs/playbook-proxy-ssh-postgresql.yml](docs/playbook-proxy-ssh-postgresql.yml)
- [docs/experimental-features.md](docs/experimental-features.md)
- [TESTING.md](TESTING.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)

Inventory model
===============

The role reads Podman configuration from `iac_blueprint.podman`.

Supported top-level keys:

- `configuration`
- `directories`
- `files`
- `binds`
- `cron`
- `containers`

Shared filesystem helpers
=========================

This role supports `directories:`, `files:`, `binds:`, and `cron:` through the shared
task library under `tasks/shared` (pin above). Shared file tasks pass through
the requested mode and do not set a secret-safe default mode or suppress diffs.
Set restrictive `mode` values (for example `"0600"`) for sensitive content;
do not put credentials in inline content unless the task output/diff exposure
is acceptable.

For the exact `binds:` record structure and examples, see:

- `tasks/shared/README.md`

Supported container keys:

- `preset`
- `image`
- `parameters`
- `environment`
- `command`
- `bootstrap_packages`
- `bootstrap_services`
- `bootstrap_ssh_root_access`
- `bootstrap_ssh_authorized_keys_contents`
- `bootstrap_ssh_authorized_keys_files`
- `bootstrap_ssh_private_key_path`
- `bootstrap_ssh_known_hosts_path`

Other top-level container record keys are not a supported extension point and
are currently ignored. Put Podman create options under `parameters`.

Container presets
=================

Container definitions may use an optional top-level `preset` key instead of
repeating a fixed image reference in every inventory entry. The role resolves
the preset from `podman_container_presets` and then merges the explicit
container definition on top of it.

Default built-in presets:

- `rhel9` -> `registry.access.redhat.com/ubi9-init`

Requirements
============

- Supported target operating systems (declared): Rocky Linux 9 and 10, and
  Red Hat Enterprise Linux 9 and 10.
- Runtime-tested by this repository's Molecule scenarios: Rocky Linux 9 and
  10. The current runtime matrix does not cover RHEL 9 or 10.
- Other requirements:
  - Ansible 2.15 or higher
  - Git with submodule support; initialize `tasks/shared` at the checked-in
    commit before invoking states that manage shared filesystem, bind, or cron
    resources.
- Target host requires a supported Rocky Linux or RHEL 9/10 system with package-manager
  access; container lifecycle states require the Podman CLI. Cron requires
  `cronie`; shared SELinux context records require enabled SELinux and
  `semanage`.

Code quality
============

This project adheres to the [Ansible Lint](https://ansible-lint.readthedocs.io)
production profile.

Role testing
============

This role includes Molecule scenarios for both baseline and experimental
coverage:

- `default`: install path, host-side resources, cron, and a basic container
- `lifecycle`: `container_present`, `container_started`,
  `container_stopped`, and `container_absent`
- `experimental`: runtime package install, service bootstrap, and generated
  SSH root access
- `experimental-ip`: SSH root access through direct container IP access
- `experimental-host-user`: host-side SSH artifacts under a non-root SSH login
  user home
- `experimental-rhel9-preset`: SSH root access with the built-in `rhel9`
  preset image

Run locally from the role directory:

```bash
molecule test
```

Run a specific scenario:

```bash
molecule test -s default
molecule test -s lifecycle
molecule test -s experimental
molecule test -s experimental-ip
molecule test -s experimental-host-user
molecule test -s experimental-rhel9-preset
```

Security audit residual risks
=============================

The 2026 security audit findings are tracked here so that limitations are not
hidden by the hardening changes:

- **P01/P02:** Host Podman operations use `command` argv and container names
  are restricted to a safe identifier grammar. Podman create parameter keys
  are constrained to the documented allowlist; inventories using other keys
  must migrate or extend the role allowlist deliberately.
- **P03:** Authorized-key material and generated private-key operations have
  narrow `no_log`/diff protection. Public host keys are not secrets and remain
  observable in normal task output where applicable.
- **P04:** Container removal now stops a running configured container before
  removing it. Containers not present in the configured list are intentionally
  not reconciled or removed; the role has no ownership inventory for them.
- **P05:** The proxy example now requires strict host-key checking and a real
  known-hosts file. Operators must provision and verify that file out of band.
- **P06:** Privileged systemd containers and root SSH remain supported as
  experimental, high-risk compatibility features; they are not made safe by
  the role and must be explicitly reviewed.
- **P07:** Authorized-key management is additive for compatibility. Removing a
  key from inventory does not revoke it from an existing container. Rebuild or
  revoke keys separately when revocation is required.
- **P08:** The managed SSH drop-in is ordered late. Effective settings are
  checked with `sshd -t` and `sshd -T` on every root-SSH convergence, and
  restart occurs only after the settings match. A failed change attempts to
  restore the previous policy and service state, verifies that restoration, and
  fails explicitly if verification fails; rollback is not silently guaranteed.
  During migration, the old `50-idarsi-bootstrap-root.conf` is removed only
  when its content exactly matches the role's former policy; unrelated content
  is preserved.
- **P09:** Podman configuration is updated through a managed block with
  `create: true`, so unrelated sections are preserved and an absent file is
  created. Existing unmanaged duplicate `[network]` sections are rejected;
  operators must merge them before convergence.
- **P10:** Container commands use an argv list as the secure canonical form,
  for example `["sh", "-c", "echo safe"]`. Simple legacy strings are still
  accepted and split on whitespace. Quoted arguments and shell metacharacters
  are rejected with an actionable validation error; shell execution is never
  used by the role.
- **P11:** Known-hosts entries use per-container markers, preserving entries
  for other managed containers. The old shared marker is deliberately left
  untouched because its ownership and container association cannot be proven;
  operators must migrate it explicitly after review.
- **P12/P14:** Running containers are stopped before removal; inspect failures,
  paused states, and unknown states are refused and never removed. The
  `initialized` state is removable. These are guardrails, not runtime-tested
  guarantees in this environment. Command argument state is rebuilt per
  container and statically type-checked; runtime argv behavior remains
  unverified without Ansible.
- **P13:** The shared filesystem task library is a submodule and is not changed
  by this patch. Its default mode and secret diff behavior remain an external
  dependency; use restrictive modes and `diff: false` in filesystem records
  carrying secrets.
