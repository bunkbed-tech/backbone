{ config, lib, pkgs, ... }:
let
  inherit (builtins) attrNames attrValues foldl' head map replaceStrings;
  inherit (lib.attrsets) recursiveUpdate;
  org = "bunkbed";
  project = "backbone";
  domain = "${org}.tech";
  domain-clean = replaceStrings [ "." ] [ "-" ] domain;
  users = map (n: "${n}@${domain}") [ "tristan" "tahoe" ];
  makeIp = name: "\${ google_compute_address.${name}.address }";
  billing_account = "\${ data.google_billing_account.tristan-united.id }";
  taint = { key = "dedicated"; value = "ingress"; effect = "NO_SCHEDULE"; };
  org_id = "\${ data.google_organization.${org}.org_id }";
  utils = import ./utils.nix { inherit pkgs lib; };
  modules = rec {
    variables = import ./variables.nix { };
    providers = import ./providers.nix {
      inherit org project;
      kubernetes = {
        host = "https://\${ google_container_cluster.${project}.endpoint }";
        token = "\${ data.google_client_config.default.access_token }";
        cluster_ca_certificate = "\${ base64decode(google_container_cluster.${project}.master_auth[0].cluster_ca_certificate) }";
      };
    };
    namecheap = import ./namecheap.nix {
      inherit domain;
      ips = map makeIp (attrNames kubeip.resource.google_compute_address);
      funcs = { inherit (lib.lists) concatMap; };
    };
    webserver = import ./webserver.nix { };
    nginx = import ./nginx.nix {
      inherit domain taint;
      ip = makeIp (head (attrNames kubeip.resource.google_compute_address));
      webserver = {
        inherit (webserver.resource.kubernetes_service.webserver.metadata) name namespace;
        inherit (head webserver.resource.kubernetes_service.webserver.spec.port) port;
      };
      ingress-pool = gke.resource.google_container_node_pool.ingress-pool.name;
#     tls.secret = cert-manager.resource.kubernetes_manifest.domain-clean.manifest.spec.secretName;
#     issuer = cert-manager.resource.kubernetes_manifest.issuer.manifest.metadata.name;
      funcs = { inherit (utils) importYaml toHCL; };
    };
#   cert-manager = import ./cert-manager.nix {
#     inherit domain domain-clean;
#     issuer.solvers = [
#       { selector = {}; http01.ingress.class = "nginx"; }
#     ];
#   };
  };
in
foldl' recursiveUpdate { } (attrValues modules)
