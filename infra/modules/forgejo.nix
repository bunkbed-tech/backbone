{ config, lib, pkgs, ... }:
let
  name = "forgejo";
  namespace = name;
in {
  resource.helm_release.forgejo = {
    depends_on = [ "kubernetes_storage_class.default" ];
    inherit name namespace;
    create_namespace = true;
    repository = "oci://codeberg.org/forgejo-contrib";
    chart = "forgejo";
    version = "0.8.6";
  };
}
