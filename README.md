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
`tasks/shared`.

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
        command: "sleep infinity"
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

This role supports `directories:`, `files:`, and `binds:` through the shared
task library under `tasks/shared`.

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

- Operating system (tested on)
  - Red Hat Enterprise Linux 8
  - Rocky Linux 10

- Other components
  - Ansible 2.15 or higher

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
