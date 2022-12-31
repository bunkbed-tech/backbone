{ domain, issuer }:
let service = "cert-manager";
in
{
  # resource.helm_release.${service} = {
  #   name = service;
  #   repository = "https://charts.jetstack.io";
  #   chart = service;
  #   version = "1.10.1";
  #   namespace = service;
  #   create_namespace = true;
  #   set = [
  #     { name = "installCRDs"; value = true; }
  #     { name = "global.leaderElection.namespace"; value = service; }
  #   ];
  # };
  resource.kubernetes_manifest.issuer.manifest = rec {
    apiVersion = "cert-manager.io/v1";
    kind = "ClusterIssuer";
    metadata = { name = "letsencrypt"; };
    spec.acme = {
      inherit (issuer) solvers;
      server = "https://acme-v02.api.letsencrypt.org/directory";
      email = "superadmin@${domain}";
      privateKeySecretRef.name = metadata.name;
    };
  };
}
