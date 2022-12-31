{ config, lib, pkgs, ... }:
let
  inherit (builtins) attrNames attrValues foldl' map;
  inherit (lib.attrsets) recursiveUpdate;
  org = "bunkbed";
  project = "backbone";
  domain = "${org}.tech";
  users = map (n: "${n}@${domain}") [ "tristan" "tahoe" ];
  makeIp = name: "\${ google_compute_address.${name}.address }";
  billing_account = "\${ data.google_billing_account.tristan-united.id }";
  org_id = "\${ data.google_organization.${org}.org_id }";
  utils = import ./utils.nix { inherit lib; };
  modules = rec {
    variables = import ./variables.nix {};
    backend = import ./backend.nix { inherit org project; };
    providers = import ./providers.nix {
      inherit org project;
      kubernetes = {
        host = "https://\${ google_container_cluster.${project}.endpoint }";
        token = "\${ data.google_client_config.default.access_token }";
        cluster_ca_certificate = "\${ base64decode(google_container_cluster.${project}.master_auth[0].cluster_ca_certificate) }";
      };
    };
    data = import ./data.nix { inherit org domain; };
    _project = import ./project.nix {
      inherit billing_account org_id;
      google_project.project_id = providers.provider.google.project;
    };
    budget = import ./budget.nix {
      inherit domain billing_account;
      inherit (providers.provider.google) billing_project;
      funcs = { inherit (lib.attrsets) genAttrs; };
    };
    vpc = import ./vpc.nix {
      inherit project;
      subnetwork.region = providers.provider.google.region;
    };
    gke = import ./gke.nix {
      inherit project users;
      cluster = {
        location = providers.provider.google.zone;
        network = vpc.resource.google_compute_network.vpc.name;
        subnetwork = vpc.resource.google_compute_subnetwork.${project}.name;
      };
    };
    kubeip = import ./kubeip.nix {
      inherit (providers.provider.google) project;
      funcs = { inherit (lib.lists) range; inherit (utils) listToAttrsWithKeyFunc; };
      cluster = gke.resource.google_container_cluster.${project}.name;
      address_count = gke.resource.google_container_node_pool.ingress-pool.node_count;
      ingress-pool = gke.resource.google_container_node_pool.ingress-pool.name;
      web-pool = gke.resource.google_container_node_pool.web-pool.name;
    };
    namecheap = import ./namecheap.nix {
      inherit domain;
      ips = map makeIp (attrNames kubeip.resource.google_compute_address);
      funcs = { inherit (lib.lists) concatMap; };
    };
    webserver = import ./webserver.nix {
      #inherit domain;
      #webserver.tls.issuer = cert-manager.resource.kubernetes_manifest.issuer.manifest.metadata.name;
      #static-ip-name = vpc.resource.google_compute_global_address.base.name;
      #cert-manager.namespace = cert-manager.resource.helm_release.cert-manager.namespace;
    };
    #   nginx = import ./nginx.nix {
    #     inherit domain;
    #     webserver = {
    #       inherit (webserver.resource.kubernetes_service.webserver.metadata) name namespace;
    #     };
    #     ingress-pool = gke.resource.google_container_node_pool.ingress-pool.name;
    #   };
    #   cert-manager = import ./cert-manager.nix {
    #     inherit domain;
    #     issuer.solvers = [
    #       { http01.ingress.name = webserver.resource.kubernetes_ingress_v1.webserver-ingress.metadata.name; }
    #     ];
    #   };
    #   gitlab = import ./gitlab.nix { inherit domain ip; }
  };
in
foldl' recursiveUpdate { } (attrValues modules)
