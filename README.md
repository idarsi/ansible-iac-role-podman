ANSIBLE-IAC-ROLE-PODMAN
=======================
**COPYRIGHT** 2025 ^(ida|arsi)$ collective  
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
Creating network                | network_present     |
Removing network                | network_absent      |
Creating container              | container_present   |
Removing container              | container_absent    |
Starting container              | container_started   |
Stopping container              | container_stopped   |
Restarting container            | container_restarted |

Configuration
-------------

Role configuration is driven by `iac_blueprint.podman`. The most important
configuration blocks are:

- `configuration.network`: Writes a `[network]` section to
  `/etc/containers/containers.conf` using key/value pairs.
- `networks`: Creates/removes Podman networks when using
  `state=network_present` or `state=network_absent`.
- `containers`: Creates/removes/starts/stops/restarts containers when using
  the container-related states. `parameters` are passed as `podman create`
  flags. `environment` becomes `--env KEY=VALUE` arguments.
- `directories` and `files`: Manages filesystem directories and inline file
  content when using `state=present` or `state=absent`.
- `cron`: Manages cron jobs when using `state=present` or `state=absent`.

Example inventory snippet:

```yaml
iac_blueprint:
  podman:
    configuration:
      network:
        default_subnet: 10.168.0.0/24
        default_gateway: 10.168.0.1
    networks:
      - name: "podnet0"
        subnet: 10.168.0.0/24
        gateway: 10.168.0.1
        driver: bridge
    containers:
      - image: "docker.io/ollama/ollama"
        parameters:
          name: "ollama"
          hostname: "ollama"
          ip: 10.168.0.100
          publish: 11434:11434
          volume:
            - "/srv/ollama:/root/.ollama:Z"
        environment:
          OLLAMA_HOST: "0.0.0.0"
    directories:
      - path: "/srv/ollama"
        owner: "root"
        group: "root"
        mode: "0750"
    files:
      - path: "/srv/ollama/README.txt"
        content: "Managed by ansible-iac-role-podman\n"
        mode: "0640"
    cron:
      - name: "podman-prune"
        user: "root"
        hour: "2"
        minute: "15"
        job: "podman system prune -f"
        cron_file: "podman-maintenance"
```

Requirements
------------

- Operating system (tested on)
  - Red Hat Enterprise Linux 8
  - Red Hat Enterprise Linux 9
  - Rocky Linux 10

- Other components
  - Ansible 2.15 or higher

Code Quality
------------

This project adheres to the [Ansible Lint](https://ansible-lint.readthedocs.io) **production** profile, ensuring high-quality and production-ready configuration management.
