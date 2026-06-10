# ansible-iac-role-podman Agent Guide

## Purpose

This role manages Podman host configuration, host-side support resources, and
Podman container lifecycle states.

## Testing

- Keep Molecule scenarios under `molecule/` aligned with real role behavior.
- Use `molecule/default` for baseline coverage.
- Use `molecule/lifecycle` for container lifecycle state coverage.
- Use `molecule/experimental` for `bootstrap_packages`,
  `bootstrap_services`, and `bootstrap_ssh_root_access`.
- Keep experimental paths idempotent. If Molecule idempotence fails, fix the
  role logic instead of weakening the scenario.

## Nested Podman Test Notes

- Molecule scenarios in this role are expected to support nested Podman test
  environments.
- Keep the test-only nested Podman workarounds in Molecule scenarios, not in
  production inventory examples.
- Keep the container guard bypass test-only by using
  `podman_skip_container_guard: true` only in Molecule scenarios.

## Documentation Sync

- Keep `README.md`, `docs/inventory-example.yml`, and
  `docs/playbook-example.yml` consistent with each other.
- When inventory keys or supported patterns change, update all three in the
  same change.
- Keep examples compact but representative of real supported usage.

## Inventory Compatibility

- Treat `iac_blueprint.podman` keys as stable unless an intentional breaking
  change is being made.
- Prefer documenting new behavior through examples before adding more prose.
