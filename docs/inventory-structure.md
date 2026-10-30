# Inventory structure

The role reads Podman configuration from `iac_blueprint.podman`.

## Top-level keys

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
        command: ["sleep", "infinity"]
        quadlet: true
```

Supported keys under `iac_blueprint.podman`:

- `configuration`: Podman host configuration rendered to
  `/etc/containers/containers.conf`
- `directories`: host-side directories managed by the role
- `files`: host-side files with inline `content`
- `cron`: host-side cron entries
- `containers`: list of container definitions

Each listed collection must be a YAML list; `configuration` and `network` must
be mappings. Unknown top-level fields are rejected during preflight before
package, filesystem, proxy, or container changes. Directory, file, bind, and
cron record fields are validated further by the pinned shared task library
when the corresponding resource operation runs.

## Container definition keys

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
        command: ["sleep", "infinity"]
        bootstrap_packages:
          - openssh-server
        bootstrap_services:
          - sshd
        bootstrap_ssh_root_access: true
        bootstrap_ssh_authorized_keys_contents:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBEXAMPLEcontrollerkey operator@example"
        bootstrap_ssh_authorized_keys_files:
          - "{{ playbook_dir }}/files/id_ed25519_controller.pub"
        bootstrap_ssh_private_key_path: "/home/automation/.ssh/id_ed25519_example_container"
        bootstrap_ssh_known_hosts_path: "/home/automation/.ssh/known_hosts"
```

Supported container keys:

- `preset`: optional preset resolved from `podman_container_presets`
- `image`: explicit image reference; may be omitted when `preset` provides it
- `parameters`: arguments rendered into `podman create`
- `environment`: optional environment variables passed with `--env`
- `command`: optional post-image command string
- `quadlet`: optional boolean; when `true`, use a rootful Quadlet `.container`
  unit at `/etc/containers/systemd/<name>.container` instead of direct
  `podman create`. The generated service is enabled at boot via Quadlet's
  `[Install] WantedBy=multi-user.target` handling. Supported translated
  parameters are `name`, `hostname`, `ip`, `publish`, `volume`, `network`,
  and `user`; other Podman create parameters are rejected for Quadlet records.
  Quadlet requires the distribution's Podman package to include its systemd
  generator and requires cgroup v2. Container bootstrap features are not
  supported with Quadlet.
- `bootstrap_packages`: optional experimental packages installed inside the
  running container
- `bootstrap_services`: optional experimental services enabled and started
  inside the running container
- `bootstrap_ssh_root_access`: optional experimental root SSH key bootstrap
- `bootstrap_ssh_authorized_keys_contents`: optional experimental literal
  public keys copied into container root `authorized_keys`
- `bootstrap_ssh_authorized_keys_files`: optional experimental controller-local
  public key file paths copied into container root `authorized_keys`
- `bootstrap_ssh_private_key_path`: optional override for the generated
  host-side private key path
- `bootstrap_ssh_known_hosts_path`: optional override for the host-side
  `known_hosts` path

Notes about `parameters`:

- scalar values become `--key value`
- boolean `true` values become flag-style `--key`
- boolean `false` values are omitted
- `volume` may be a list and is rendered as repeated `--volume` arguments
- `parameters.name` is required for container lifecycle states
- Accepted keys are `name`, `hostname`, `ip`, `publish`, `privileged`,
  `systemd`, `volume`, `network`, `tty`, `interactive`, and `user`; unknown
  keys are rejected. Values should be strings, booleans, or lists of scalar
  values as appropriate for their Podman option. `name` must follow the safe
  container-name grammar.

## States and preflight

The public `state` defaults to `present`. Supported values are `validate`,
`present`, `absent`, `install`, `uninstall`, `container_present`,
`container_absent`, `container_started`, and `container_stopped`. The complete
top-level and container input shape and state are checked before proxy checks
or state work. `validate` performs no target runtime checks or mutations.
Container lifecycle states require each record to supply `parameters.name`
(directly or through a preset). The built-in `rhel9` preset supplies image
`registry.access.redhat.com/ubi9-init` and the derived name `rhel9`; an
explicit container value overrides preset values.

Supported operating systems are Rocky Linux 9/10 and RHEL 9/10. Molecule
runtime coverage currently covers Rocky Linux 9/10 only, not RHEL.

Shared task library is pinned as submodule commit
`d70d58eeb31390d36975fb8d9c11dfab88fadc95`. File records select exactly one
of `content` and `src`, and the shared implementation passes through `mode`
without choosing a safe default. Sensitive file content may appear in task
diff/output; provide restrictive modes and avoid secret material in these
records.
