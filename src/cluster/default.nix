{ config, lib, pkgs, ... }:
{
  imports = [
    ./traefik.nix
    ./namecheap.nix
    ./forgejo.nix
  ];
  options.kubernetes.context = lib.mkOption {
    description = "The kubeconfig context to use for the kubernetes provider";
    type = lib.types.str;
  };
  config.provider.kubernetes = {
    config_path = "~/.kube/config";
    config_context = config.kubernetes.context;
  };
  config.provider.helm = { inherit (config.provider) kubernetes; };
  config.resource.kubernetes_storage_class.default = lib.mkIf (config.kubernetes.context == "sirver-k8s") {
    metadata.name = "default";
    metadata.annotations."storageclass.kubernetes.io/is-default-class" = true;
    storage_provisioner = "kubernetes.io/no-provisioner";
    volume_binding_mode = "WaitForFirstConsumer";
  };
}
