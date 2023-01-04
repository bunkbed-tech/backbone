{ domain, domain-clean, issuer }:
let
  service = "cert-manager";
in
rec {
  resource.helm_release.${service} = {
    name = service;
    repository = "https://charts.jetstack.io";
    chart = service;
    version = "1.10.1";
    namespace = service;
    create_namespace = true;
    set = [
      { name = "installCRDs"; value = true; }
      { name = "global.leaderElection.namespace"; value = service; }
      { name = "clusterResourceNamespace"; value = "default"; }
    ];
  };
  resource.kubernetes_manifest.issuer = {
    manifest = rec {
      apiVersion = "cert-manager.io/v1";
      kind = "ClusterIssuer";
      metadata = { name = "letsencrypt"; };
      spec.acme = {
        inherit (issuer) solvers;
        server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        email = "superadmin@${domain}";
        privateKeySecretRef.name = metadata.name;
      };
    };
  };
  resource.kubernetes_secret.domain-clean = {
    metadata = { name = "${domain-clean}-tls"; namespace = "default"; };
    data = { "tls.crt" = ""; "tls.key" = ""; };
  };
  resource.kubernetes_manifest.domain-clean = {
    manifest = rec {
      apiVersion = "cert-manager.io/v1";
      kind = "Certificate";
      metadata = { name = domain-clean; namespace = "default"; };
      spec = {
        secretName = resource.kubernetes_secret.domain-clean.metadata.name;
        issuerRef = {
          inherit (resource.kubernetes_manifest.issuer.manifest.metadata) name;
          inherit (resource.kubernetes_manifest.issuer.manifest) kind;
        };
        commonName = domain;
        dnsNames = [ domain "www.${domain}" ];
      };
    };
  };
}
