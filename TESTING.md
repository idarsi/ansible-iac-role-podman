# Testing

This role uses Molecule with the Podman driver for automated integration
testing. The baseline scenario covers Rocky Linux 9 and 10 init images; other
scenarios currently use Rocky Linux 10 and are divided into
baseline, lifecycle, and experimental coverage. Experimental scenarios are
included in the repository but are not a substitute for the baseline suite.
The declared support targets are Rocky Linux 9/10 and RHEL 9/10. Runtime
coverage includes Rocky Linux 9 and 10 only; RHEL 9/10 are documented
supported targets but are not present in the current test matrix.

Pull requests run a fast CI gate for production-profile lint, syntax checks,
and deterministic controller-side fixtures. CI checks out the shared-task
submodule recursively. Runtime/Molecule scenarios are not part of this fast
gate; run them separately with the approved Idarsi test environment.

## Automated test matrix

Scenario                         | Platform/image                         | Main coverage
---------------------------------|----------------------------------------|------------------------------
`default`                        | Rocky Linux 9 and 10 init              | Podman installation, network configuration, directories, files, cron, and a running container
`lifecycle`                      | Rocky Linux 10 init                    | `container_present`, `container_started`, `container_stopped`, and `container_absent`
`experimental`                   | Rocky Linux 10 init                    | Package and service bootstrap, generated root SSH access, controller and inline authorized keys, and published SSH access
`experimental-ip`                | Rocky Linux 10 init                    | Generated SSH access and login through the container IP address
`experimental-host-user`        | Rocky Linux 10 init                    | Generated SSH artifacts owned by a non-root host user and SSH login through that user
`experimental-rhel9-preset`     | Rocky Linux 10 init                    | The built-in `rhel9` preset, systemd container bootstrap, and generated SSH access

The scenarios use nested Podman test workarounds in their converge playbooks:
they force the `vfs` storage driver and set `podman_skip_container_guard` for
the test container. These settings are test-only and must not be copied into
production inventory examples.

The installed Molecule schema requires `ansible.env` for provisioner
environment variables and string values such as `systemd: "true"`; the
scenario files intentionally retain those schema-compatible forms.

## Scenario coverage

- `molecule/default` validates the `install` state, Podman network
  configuration, shared directory and file resources, controller and remote
  file sources, a managed cron entry, and a running container.
- Podman network configuration preserves unrelated `containers.conf` content,
  creates a missing file, and rejects an unmanaged duplicate `[network]`
  section before mutation; runtime coverage is exercised by the baseline
  scenario when Podman is available.
- `molecule/lifecycle` validates the container lifecycle states in sequence:
  create, start, stop, start, and remove. The final removal deliberately
  starts the container again so the role's safe stop-before-remove behavior is
  exercised.
- The lifecycle fixture uses a simple scalar command and the role's argv
  builder also accepts list-valued Podman parameters; static YAML checks cover
  the task structure, while full argv/runtime coverage remains Molecule-only.
- The standalone argv fixture uses the canonical list form and verifies that
  command arguments remain separate argv elements.
- Removal policy explicitly permits `initialized` containers and rejects
  `paused` or unknown states; inspect failures are treated as absent and never
  trigger removal. These guardrails are validated statically here and require
  a disposable runtime scenario for full execution coverage.
- Root-SSH policy checks include effective `AuthorizedKeysFile` alongside the
  other settings, providing a precedence regression guard through `sshd -T`.
- Root-SSH migration preserves an old `50-idarsi-bootstrap-root.conf` unless
  it exactly matches the former role-managed policy; the late `99-` drop-in is
  then validated as the effective policy.
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

The argv fixture exercises argv construction; the blueprint fixture exercises
the public `validate` state through `tasks/main.yml`, which bypasses runtime
checks and state mutation. Both run controller-side without Podman:

```bash
ansible-playbook tests/argv-construction.yml
ansible-playbook tests/blueprint-validation.yml
```

The argv fixture imports `container_create_argv.yml` and
`container_bootstrap_package_argv.yml` and covers scalar, repeated list,
boolean, null, environment, and bootstrap package argv values. Blueprint tests
cover preset-derived lifecycle-name acceptance without specifying
`parameters.name`, plus exact failure messages for malformed container
parameters and unknown blueprint keys. This does not prove every task's
check-mode behavior: package, filesystem, and Podman command tasks do not
uniformly support check mode. Runtime behavior requires disposable Molecule
coverage. Local checks do not install dependencies.

Run the production-profile Ansible Lint check from the role directory:

```bash
ANSIBLE_ROLES_PATH=.. ansible-lint --profile production --exclude tasks/shared
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
