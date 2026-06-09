ANSIBLE-IAC-ROLE-PODMAN
=======================
**COPYRIGHT** 2026 ^(ida|arsi)$ collective  
**LICENSE** MIT License [LICENSE](LICENSE)  
**AUTHORS**
- Arsi Atomi <arsi@atomi.sh>  
- Arsi Atomi <arsi.atomi@valtori.fi>  

Overview
========

This Ansible role is designed to simplify and enhance the flexibility of Podman management.

This role uses only ansible.builtin.* ansible modules and podman shell command.

These operations are supported:

Operation                       | State               |
--------------------------------|---------------------|
Installing and creating all     | install             |
Uninstalling all                | uninstall           |
Installing Podman               | present             |
Uninstalling Podman             | absent              |
Creating container              | container_present   |
Removing container              | container_absent    |
Starting container              | container_started   |
Stopping container              | container_stopped   |

Container command arguments
---------------------------

Container definitions may include an optional top-level `command` string. When
set, the role appends it after the image name in `podman create`, which is
useful for images such as vLLM that are configured primarily through
post-image CLI arguments.

Experimental bootstrap packages
--------------------------------

Container definitions may include an experimental top-level
`bootstrap_packages` list. When present, the role starts the container and then
tries to install the listed packages inside the running container by using the
first available package manager from `dnf`, `microdnf`, or `yum`.

This is intentionally experimental:

- it modifies the container at runtime instead of using a prebuilt image
- package-manager behavior depends on the image
- it is less deterministic than using a dedicated preset or image

Example:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-sshd"
        command: "sleep infinity"
        bootstrap_packages:
          - openssh-server
```

Experimental bootstrap services
-------------------------------

Container definitions may include an experimental top-level
`bootstrap_services` list. When present, the role tries to enable and start the
listed systemd services inside the running container with `systemctl enable
--now`.

This requires that:

- the container image actually includes `systemctl`
- systemd is usable inside the container
- required service packages are already present, or were installed through
  `bootstrap_packages`

Example:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-sshd"
        command: "sleep infinity"
        bootstrap_packages:
          - openssh-server
        bootstrap_services:
          - sshd
```

Container presets
-----------------

Container definitions may also use an optional top-level `preset` key instead
of repeating a fixed image reference in every inventory entry. The role resolves
the preset from `podman_container_presets` and then merges the explicit
container definition on top of it.

Example:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-init"
          publish: "8080:80"
```

Default built-in presets:

- `rhel9` -> `registry.access.redhat.com/ubi9-init`

Requirements
------------

- Operating system (tested on)
  - Red Hat Enterprise Linux 8
  - Rocky Linux 10

- Other components
  - Ansible 2.15 or higher

Code Quality
------------

This project adheres to the [Ansible Lint](https://ansible-lint.readthedocs.io) **production** profile, ensuring high-quality and production-ready configuration management.
