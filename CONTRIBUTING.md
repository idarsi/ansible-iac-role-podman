# Contributing

## Documentation and inventory changes

Keep `README.md`, the use-case examples under `docs/`, and the reference
documents under `docs/` aligned with the role implementation.

Every new or changed `iac_blueprint.podman` key must be handled in all
relevant documentation locations:

- Update the matching inventory example when the inventory shape is
  user-visible.
- Update `docs/inventory-structure.md` for changes to the inventory model.
- Update `docs/playbook-states.yml` when the supported state surface changes.
- Update `README.md` when supported states, inventory structure, or required
  behavior changes.

Keep examples compact and use-case driven. Treat existing
`iac_blueprint.podman` keys as stable unless the change is intentionally
breaking.

## Tests

Run the default scenario after changes affecting normal installation,
configuration, host resources, or basic containers:

```bash
molecule test -s default
```

Run the lifecycle scenario after changes affecting container state handling:

```bash
molecule test -s lifecycle
```

Run the relevant experimental scenario after changes affecting bootstrap,
SSH key generation, SSH service setup, presets, or non-root host users:

```bash
molecule test -s experimental
molecule test -s experimental-ip
molecule test -s experimental-host-user
molecule test -s experimental-rhel9-preset
```

Before submitting changes, run the relevant Molecule scenarios, a syntax
check, and the production-profile lint check from the role directory:

```bash
molecule syntax -s <scenario>
ANSIBLE_ROLES_PATH=.. ansible-lint --profile production
```

The role's Molecule scenarios run in nested Podman containers. Keep the
scenario-only `vfs` storage configuration and `podman_skip_container_guard`
override in Molecule files; do not add them to production examples merely to
make a test pass.

## Scenario design

Use `molecule/default` for baseline role behavior and `molecule/lifecycle`
for explicit container lifecycle states. Use the `experimental` scenarios
for bootstrap and SSH paths. Experimental paths must remain idempotent; fix
role behavior when idempotence fails instead of weakening the scenario.

When adding a scenario, document its purpose in `TESTING.md` and keep its
platform, converge inputs, and verify assertions representative of supported
role behavior.
