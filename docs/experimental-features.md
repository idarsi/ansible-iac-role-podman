# Experimental features

The features in this document are intentionally marked experimental. They are
useful for fast iteration and testing, but less deterministic than prebuilt
images and fixed container presets.

## Container command arguments

Container definitions may include an optional top-level `command` string. When
set, the role appends it after the image name in `podman create`.

Example:

```yaml
iac_blueprint:
  podman:
    containers:
      - preset: rhel9
        parameters:
          name: "rhel9-init"
        command: "sleep infinity"
```

## Bootstrap packages

Container definitions may include an experimental top-level
`bootstrap_packages` list. When present, the role starts the container and
tries to install the listed packages inside the running container by using the
first available package manager from `dnf`, `microdnf`, or `yum`.

Notes:

- it modifies the container at runtime instead of using a prebuilt image
- package-manager behavior depends on the image
- it is less deterministic than using a dedicated preset or image

## Bootstrap services

Container definitions may include an experimental top-level
`bootstrap_services` list. When present, the role tries to enable and start
the listed systemd services inside the running container with
`systemctl enable --now`.

This requires that:

- the container image includes `systemctl`
- systemd is usable inside the container
- required service packages are already present, or were installed through
  `bootstrap_packages`

## Systemd inside container

If you want to run systemd-managed services inside the container, configure the
container explicitly through `parameters`. The practical minimum is:

- `systemd: always`
- `privileged: true`
- cgroup mount such as `"/sys/fs/cgroup:/sys/fs/cgroup:rw"`

See:

- [inventory-systemd-sshd.yml](inventory-systemd-sshd.yml)
- [inventory-ssh-controller-keys.yml](inventory-ssh-controller-keys.yml)

## Root SSH access with generated host keys

Container definitions may include `bootstrap_ssh_root_access: true`. When
enabled, the role:

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
ssh -i /home/automation/.ssh/id_ed25519_podman_rhel9-sshd root@10.168.0.100
```

Notes:

- use `-i` to point SSH at the generated private key on the host
- use `-p <port>` only when the container SSH port is published on the host
- when connecting directly to the container IP, use the container IP without
  `-p` unless you changed the SSH port inside the container

## Controller-side authorized keys

Container definitions may include controller-side public keys that are
installed into container root's `authorized_keys` without generating a new
host key pair.

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
