ANSIBLE-IAC-ROLE-PODMAN
=======================
**COPYRIGHT** 2026 ^(ida|arsi)$ collective  
**LICENSE** MIT License [LICENSE](LICENSE)  
**AUTHORS**
- Arsi Atomi <arsi@atomi.sh>  
- Arsi Atomi <arsi.atomi@valtori.fi>  

Overview
========

This role manages Podman host configuration, host-side support resources, and
Podman container lifecycle states.

The role uses only `ansible.builtin.*` modules and the `podman` CLI.

Supported states
================

State               | Purpose
--------------------|--------------------------------------------------------
`install`           | Install Podman and create all configured resources
`uninstall`         | Remove Podman and all resources managed by the role
`present`           | Ensure Podman package and host-side configuration exist
`absent`            | Remove Podman package and host-side configuration
`container_present` | Create configured containers without starting them
`container_absent`  | Remove configured containers
`container_started` | Start configured containers
`container_stopped` | Stop configured containers

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

Inventory model
===============

The role reads Podman configuration from `iac_blueprint.podman`.

Supported top-level keys:

- `configuration`
- `directories`
- `files`
- `cron`
- `containers`

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
