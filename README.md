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
- generates an ed25519 key for the host SSH login user and adds it to container root
  `authorized_keys`
- adds explicit controller-side public keys to container root `authorized_keys`
- adds the container SSH host key to the host SSH login user's `known_hosts`
- installs an sshd drop-in that explicitly allows root public key login

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
        bootstrap_ssh_authorized_keys_files:
          - "{{ playbook_dir }}/files/id_ed25519_controller.pub"
```

Notes:

- `bootstrap_packages` and `bootstrap_services` are still experimental
- `bootstrap_ssh_root_access` is also experimental
- `bootstrap_ssh_authorized_keys_contents` and
  `bootstrap_ssh_authorized_keys_files` are also experimental
- `bootstrap_services` assumes that `systemctl` is actually usable inside the image
- generated private keys are stored under the host SSH login user's `.ssh/`
  directory by default
- explicit controller-side public keys are read on the Ansible controller and
  appended to container root `authorized_keys`
- published SSH endpoints such as `"2222:22"` are added to the host SSH login
  user's `known_hosts` as entries like `[127.0.0.1]:2222`
- if the SSH login user is `root`, the default paths still resolve under
  `/root/.ssh/`
- if you override the generated private key path, `known_hosts` defaults to the
  same directory unless `bootstrap_ssh_known_hosts_path` is also set
- generated private keys should be used with `ssh -i <private-key-path>`
- the role writes an sshd config drop-in for root public key access and
  restarts `sshd` when that policy changes
- for long-term stability, a prebuilt image is still the better choice than runtime mutation

Experimental Root SSH Access
----------------------------

Container definitions may include an experimental top-level
`bootstrap_ssh_root_access: true` flag. When enabled, the role:

- generates an ed25519 key pair on the host if one does not already exist
- stores the private key under the host SSH login user's `.ssh/` directory by
  default
- copies the public key into container root's `authorized_keys`
- records reachable container SSH host keys in the host SSH login user's
  `known_hosts`
- configures `sshd` inside the container for root public key login

Optional key-path override:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-ssh"
          publish: "2222:22"
        bootstrap_ssh_root_access: true
        bootstrap_ssh_private_key_path: "/home/automation/.ssh/id_ed25519_rhel9_ssh"
        bootstrap_ssh_known_hosts_path: "/home/automation/.ssh/known_hosts"
```

By default the generated private key path is:

```text
<ssh-login-user-home>/.ssh/id_ed25519_podman_<container-name>
```

Example SSH commands from the host:

```bash
ssh -i /home/automation/.ssh/id_ed25519_podman_rhel9-sshd -p 2222 root@127.0.0.1
ssh -i /home/automation/.ssh/id_ed25519_podman_rhel9-sshd root@10.108.0.100
```

Notes:

- use `-i` to point SSH at the generated private key on the host
- use `-p <port>` only when the container SSH port is published on the host
- when connecting directly to the container IP, use the container IP without
  `-p` unless you changed the SSH port inside the container

Experimental Controller-Side Authorized Keys
--------------------------------------------

Container definitions may include optional experimental controller-side public
keys that are installed into container root's `authorized_keys` without
generating a new host key pair.

Supported input forms:

- `bootstrap_ssh_authorized_keys_contents`: list of literal public key lines
- `bootstrap_ssh_authorized_keys_files`: list of controller-local file paths

Example:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-ssh"
          publish: "2222:22"
        bootstrap_services:
          - sshd
        bootstrap_ssh_authorized_keys_contents:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBEXAMPLEcontrollerkey operator@example"
        bootstrap_ssh_authorized_keys_files:
          - "{{ playbook_dir }}/files/id_ed25519_controller.pub"
```

Notes:

- file-path lookups happen on the Ansible controller, not on the Podman host
- the role appends only missing keys and keeps existing non-managed
  `authorized_keys` entries intact
- when controller-side keys are configured, the role also writes the same sshd
  root public key login policy as `bootstrap_ssh_root_access`
- use this path when you already manage the private key on the Ansible
  controller and do not want the role to generate an additional host-side key

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

Reference examples:

- Inventory example: [docs/inventory-example.yml](docs/inventory-example.yml)
- Playbook example: [docs/playbook-example.yml](docs/playbook-example.yml)

Inventory Structure
-------------------

The role reads Podman configuration from `iac_blueprint.podman`.

Top-level structure:

```yaml
iac_blueprint:
  podman:
    configuration:
      network:
        network_backend: "netavark"
        default_subnet: 10.168.0.0/24
        default_gateway: 10.168.0.1
    directories:
      - path: /opt/example
        owner: root
        group: root
        mode: "0750"
    files:
      - path: /opt/example/app.env
        content: |
          EXAMPLE=true
        owner: root
        group: root
        mode: "0640"
    cron:
      - name: podman_heartbeat
        user: root
        minute: "0"
        hour: "3"
        job: "/bin/true"
        cron_file: podman_heartbeat
    containers:
      - image: "docker.io/library/alpine:latest"
        parameters:
          name: "example-container"
        command: "sleep infinity"
```

Supported top-level keys under `iac_blueprint.podman`:

- `configuration`: Podman host configuration rendered to
  `/etc/containers/containers.conf`
- `directories`: filesystem directories managed on the host
- `files`: filesystem files with inline `content` managed on the host
- `cron`: cron entries managed on the host
- `containers`: list of container definitions managed by the role

Container definition structure:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        image: "docker.io/library/alpine:latest"
        parameters:
          name: "example-container"
          hostname: "example-container"
          ip: 10.168.0.100
          publish: "8080:80"
          privileged: true
          systemd: always
          volume:
            - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
        environment:
          APP_ENV: production
          APP_PORT: "8080"
        command: "sleep infinity"
        bootstrap_packages:
          - openssh-server
        bootstrap_services:
          - sshd
        bootstrap_ssh_root_access: true
        bootstrap_ssh_private_key_path: "/home/automation/.ssh/id_ed25519_example_container"
        bootstrap_ssh_known_hosts_path: "/home/automation/.ssh/known_hosts"
```

Supported container keys:

- `preset`: optional preset resolved from `podman_container_presets`
- `image`: explicit image reference; may be omitted when `preset` provides it
- `parameters`: arguments rendered into `podman create`
- `environment`: optional environment variables passed with `--env`
- `command`: optional post-image command string
- `bootstrap_packages`: optional experimental packages installed inside the
  running container
- `bootstrap_services`: optional experimental services enabled and started
  inside the running container
- `bootstrap_ssh_root_access`: optional experimental root SSH key bootstrap
- `bootstrap_ssh_authorized_keys_contents`: optional experimental literal
  public keys copied from inventory/playbook data into container root
  `authorized_keys`
- `bootstrap_ssh_authorized_keys_files`: optional experimental controller-local
  public key file paths copied into container root `authorized_keys`
- `bootstrap_ssh_private_key_path`: optional override for the generated host
  private key path
- `bootstrap_ssh_known_hosts_path`: optional override for the host-side
  `known_hosts` path used for container root SSH access

Notes about `parameters`:

- scalar values become `--key value`
- boolean `true` values become flag-style `--key`
- boolean `false` values are omitted
- `volume` may be a list and is rendered as repeated `--volume` arguments
- `parameters.name` is required for container lifecycle states

Typical inventory patterns:

- Minimal container:

```yaml
iac_blueprint:
  podman:
    containers:
      - image: "docker.io/library/alpine:latest"
        parameters:
          name: "minimal"
        command: "sleep infinity"
```

- Preset-based container:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-init"
          publish: "8080:80"
```

- Systemd-enabled service container:

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

Role Testing
------------

This role includes Molecule scenarios for both baseline and experimental
coverage:

- `molecule/default` validates the install path, managed filesystem resources,
  cron entries, and a basic running container
- `molecule/lifecycle` validates `container_present`, `container_started`,
  `container_stopped`, and `container_absent`
- `molecule/experimental` validates `bootstrap_packages`,
  `bootstrap_services`, and `bootstrap_ssh_root_access` through a published
  SSH port
- `molecule/experimental-ip` validates `bootstrap_ssh_root_access` through
  direct container IP access without `publish`
- `molecule/experimental-host-user` validates that `bootstrap_ssh_root_access`
  writes host-side key material and `known_hosts` under a non-root SSH login
  user home
- `molecule/experimental-rhel9-preset` validates `bootstrap_ssh_root_access`
  against the role's default `rhel9` preset image through direct container IP
  access

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

Recommended use cases:

- Use `molecule test -s default` when validating the baseline role behavior:
  package installation, rendered configuration, managed filesystem resources,
  cron entries, and a simple running container
- Use `molecule test -s lifecycle` when changing role state-routing or
  container lifecycle behavior and you need coverage for
  `container_present`, `container_started`, `container_stopped`, and
  `container_absent`
- Use `molecule test -s experimental` when touching experimental bootstrap
  features such as package installation inside the container, service enable
  and start operations, or generated root SSH access
- Use `molecule test -s experimental-ip` when touching direct container IP
  SSH access or `known_hosts` behavior without a published SSH port
- Use `molecule test -s experimental-host-user` when touching default
  host-side SSH key paths, ownership, or host login user behavior
- Use `molecule test -s experimental-rhel9-preset` when validating the
  default `rhel9` preset image behavior instead of the Rocky-based nested test
  image override
- Use `molecule test` when you want the broadest local regression check across
  all scenarios

The role normally stops early when executed inside a containerized host. The
Molecule scenario opts in to bypass that guard by setting:

```yaml
podman_skip_container_guard: true
```

Keep this override limited to test scenarios. Production inventories should
continue using the default `false` value.
