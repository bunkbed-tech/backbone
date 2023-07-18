{ config, lib, pkgs, ... }:
let
  name = "forgejo";
  namespace = name;
  user = name;
  database = name;
  postgres = "${name}-postgres";
  storage = "18Gi";
in {
  resource.kubernetes_persistent_volume.forgejo = lib.mkIf (config.kubernetes.version == "k8s") {
    depends_on = [ "kubernetes_storage_class.default" ];
    metadata.name = name;
    spec.storage_class_name = config.resource.kubernetes_storage_class.default.metadata.name;
    spec.capacity.storage = storage;
    spec.access_modes = [ "ReadWriteOnce" ];
    spec.persistent_volume_source.host_path.path = "/k8s/${name}";
    spec.node_affinity.required.node_selector_term = [
      {
        match_expressions = {
          key = "kubernetes.io/hostname";
          operator = "In";
          values = [ "sirver" ];
        };
      }
    ];
  };
  resource.kubernetes_persistent_volume_claim.forgejo = lib.mkIf (config.kubernetes.version == "k8s") {
    depends_on = [ "kubernetes_persistent_volume.forgejo" "kubernetes_namespace.forgejo" ];
    metadata = { inherit name namespace; };
    spec.access_modes = [ "ReadWriteOnce" ];
    spec.resources.requests.storage = storage;
    spec.volume_name = config.resource.kubernetes_persistent_volume.forgejo.metadata.name;
  };

  resource.kubernetes_namespace.forgejo = { metadata.name = namespace; };
  resource.random_password.forgejo-postgres = { length = 24; };
  resource.kubernetes_secret.forgejo-postgres = {
    depends_on = [ "kubernetes_namespace.forgejo" ];
    metadata.name = postgres;
    metadata.namespace = namespace;
    binary_data.password = "\${ base64encode(random_password.forgejo-postgres.result) }";
  };
  resource.helm_release.forgejo = {
    depends_on = [ "helm_release.forgejo-postgres" ] ++ (
      if (config.kubernetes.version == "k8s") then [ "kubernetes_persistent_volume_claim.forgejo" ] else []
    );
    inherit name namespace;
    repository = "oci://codeberg.org/forgejo-contrib";
    chart = "forgejo";
    version = "0.8.6";
    values = pkgs.lib.backbone.toYAML ({
      postgresql.enabled = false;
      gitea.config.database = {
        DB_TYPE = "postgres";
        HOST = "${postgres}-postgresql.${namespace}.svc.cluster.local";
        NAME = database;
        USER = user;
        PASSWD = "\${ random_password.forgejo-postgres.result }";
      };
    } // lib.mkIf (config.kubernetes.version == "k8s") {
      persistence.existingClaim = name;
    });
  };
  resource.helm_release.forgejo-postgres = {
    depends_on = [ "kubernetes_secret.forgejo-postgres" ] ++ (
      if (config.kubernetes.version == "k8s") then [ "kubernetes_persistent_volume_claim.forgejo" ] else []
    );
    name = postgres;
    namespace = namespace;
    repository = "oci://registry-1.docker.io/bitnamicharts";
    chart = "postgresql";
    version = "12.6.6";
    values = pkgs.lib.backbone.toYAML ({
      auth.enablePostgresUser = false;
      auth.username = user;
      auth.database = database;
      auth.existingSecret = postgres;
    } // lib.mkIf (config.kubernetes.version == "k8s") {
      primary.persistence.existingClaim = name;
      volumePermissions.enabled = true;
    });
  };
}
