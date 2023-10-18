# Backbone

## Development

Run `bb` to see what your options are:

``` sh
$ bb
Usage: bb
       [-c|--context CONTEXT]     Kubernetes context to work with (options: k3d-bunkbed sirver-k3s sirver-k8s)
       [-h|--help]                Display this message
       [-- all]                   Run entire terraform configuration in phases
       [-- ...]                   Options will be passed to terraform
```

Here are some common options:

1. `bb -- init` to initialize the terraform configuration
2. `bb -- plan` to dry run what the configuration will do
3. `bb -- apply -auto-approve` to automatically do what the new configuration will do
4. `bb -- state list` to see what resources are managed currently by the configuration
5. `bb -c sirver-k3s -- all` to spin up the entire configuration from nothing on the server

## Architecture

```text
bin/bb                             -- entrance script for everything, wrapper around 'terraform'
config/secrets/terraform.tfvars    -- sensitive terraform configuration
old/                               -- relevant old configuration in process of migration
run/terraform/                     -- terraform runtime directory with subdirectory for each cluster
src/cluster                        -- cluster source configuration in terranix
src/lib                            -- custom nix utilities
```

### Deploy local VM with SSH to test Ansible

```sh
docker run -d -p 2222:2222 \
    -e PUBLIC_KEY_FILE=/github.pub \
    -e USER_NAME=bunkbed \
    -e USER_PASSWORD=bunkbed \
    -e SUDO_ACCESS=true \
    -e PASSWORD_ACCESS=false \
    -v ~/.ssh/github.pub:/github.pub \
    linuxserver/openssh-server
ssh -i ~/.ssh/github bunkbed@127.0.0.1
```
