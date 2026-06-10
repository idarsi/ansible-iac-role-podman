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
          systemd: always
          privileged: true
          volume:
            - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
        bootstrap_packages:
          - openssh-server
        bootstrap_services:
          - sshd
```

Systemd Inside Container
------------------------

If you want to run systemd-managed services inside the container, configure the
container for systemd explicitly through `parameters`. The practical minimum is:

- `systemd: always`
- `privileged: true`
- cgroup mount such as `"/sys/fs/cgroup:/sys/fs/cgroup:rw"`

Example:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-systemd"
          systemd: always
          privileged: true
          volume:
            - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
```

SSHD Example
------------

The following example shows a more complete container that:

- uses the built-in `rhel9` preset
- enables systemd mode
- installs `openssh-server`
- starts `sshd` through `systemctl`
- generates a host-side ed25519 key and adds it to container root
  `authorized_keys`

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-sshd"
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

Notes:

- `bootstrap_packages` and `bootstrap_services` are still experimental
- `bootstrap_ssh_root_access` is also experimental
- `bootstrap_services` assumes that `systemctl` is actually usable inside the image
- generated private keys are stored on the host under `/root/.ssh/` by default
- for long-term stability, a prebuilt image is still the better choice than runtime mutation

Experimental Root SSH Access
----------------------------

Container definitions may include an experimental top-level
`bootstrap_ssh_root_access: true` flag. When enabled, the role:

- generates an ed25519 key pair on the host if one does not already exist
- stores the private key on the host under `/root/.ssh/` by default
- copies the public key into container root's `authorized_keys`

Optional key-path override:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-ssh"
        bootstrap_ssh_root_access: true
        bootstrap_ssh_private_key_path: "/root/.ssh/id_ed25519_rhel9_ssh"
```

By default the generated private key path is:

```text
/root/.ssh/id_ed25519_podman_<container-name>
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
