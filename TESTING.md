# Testing

This role uses Molecule with the Podman driver for automated integration
testing. The scenarios use a Rocky Linux 10 init image and are divided into
baseline, lifecycle, and experimental coverage. Experimental scenarios are
included in the repository but are not a substitute for the baseline suite.

## Automated test matrix

Scenario                         | Platform/image                         | Main coverage
---------------------------------|----------------------------------------|------------------------------
`default`                        | Rocky Linux 10 init                    | Podman installation, network configuration, directories, files, cron, and a running container
`lifecycle`                      | Rocky Linux 10 init                    | `container_present`, `container_started`, `container_stopped`, and `container_absent`
`experimental`                   | Rocky Linux 10 init                    | Package and service bootstrap, generated root SSH access, controller and inline authorized keys, and published SSH access
`experimental-ip`                | Rocky Linux 10 init                    | Generated SSH access and login through the container IP address
`experimental-host-user`        | Rocky Linux 10 init                    | Generated SSH artifacts owned by a non-root host user and SSH login through that user
`experimental-rhel9-preset`     | Rocky Linux 10 init                    | The built-in `rhel9` preset, systemd container bootstrap, and generated SSH access

The scenarios use nested Podman test workarounds in their converge playbooks:
they force the `vfs` storage driver and set `podman_skip_container_guard` for
the test container. These settings are test-only and must not be copied into
production inventory examples.

## Scenario coverage

- `molecule/default` validates the `install` state, Podman network
  configuration, shared directory and file resources, controller and remote
  file sources, a managed cron entry, and a running container.
- `molecule/lifecycle` validates the container lifecycle states in sequence:
  create, start, stop, and remove. Its scenario configuration explicitly
  runs the lifecycle phases in that order.
- `molecule/experimental` validates package and `sshd` service bootstrap,
  generated host SSH keys and `known_hosts`, inline and controller-provided
  authorized keys, and SSH login through a published host port.
- `molecule/experimental-ip` validates the same generated SSH prerequisites
  and login through the container's discovered IP address.
- `molecule/experimental-host-user` validates SSH key and `known_hosts`
  ownership, permissions, and login from the configured `automation` host
  user.
- `molecule/experimental-rhel9-preset` validates the built-in `rhel9`
  container preset together with systemd, SSH package/service bootstrap, and
  generated SSH access.

## Running tests

Run the production-profile Ansible Lint check from the role directory:

```bash
ANSIBLE_ROLES_PATH=.. ansible-lint --profile production
```

Run the default Molecule scenario:

```bash
molecule test
```

Run an individual scenario:

```bash
molecule test -s <scenario>
```

Useful scenarios include:

```bash
molecule test -s default
molecule test -s lifecycle
molecule test -s experimental
molecule test -s experimental-ip
molecule test -s experimental-host-user
molecule test -s experimental-rhel9-preset
```

Run a syntax check when working only on task or scenario structure:

```bash
molecule syntax -s <scenario>
```

Run the relevant scenario and a syntax check before submitting changes. The
test scenarios use the Podman driver and pre-built images, so a working
Podman installation and access to the configured container registries are
required.
