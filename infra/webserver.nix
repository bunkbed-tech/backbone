{ domain, webserver, static-ip-name, cert-manager }:
let service = "webserver";
in
rec {
  resource.kubernetes_deployment.${service} = rec {
    metadata = rec {
      name = service;
      labels = { app = name; };
      namespace = name;
    };
    spec = {
      replicas = 1;
      selector.match_labels = metadata.labels;
      template = {
        metadata.labels = metadata.labels;
        spec.containers = [
          {
            name = "hello-app";
            image = "gcr.io/google-samples/hello-app:1.0";
            ports = [{ containerPort = 8080; }];
          }
        ];
      };
    };
  };
  resource.kubernetes_service.${service} = rec {
    inherit (resource.kubernetes_deployment.${service}) metadata;
    spec = {
      type = "ClusterIP";
      ports = [{ port = 8080; }];
      selector = metadata.labels;
    };
  };
  resource.kubernetes_secret."${service}-ssl" = {
    metadata = { name = "${service}-ssl"; namespace = cert-manager.namespace; };
    type = "kubernetes.io/tls";
    data = { "tls.crt" = ""; "tls.key" = ""; };
  };
  resource.kubernetes_ingress_v1."${service}-ingress" = {
    metadata = {
      name = "${service}-ingress";
      annotations = {
        "kubernetes.io/ingress.allow-http" = true;
        # Link TLS Issuer
        "cert-manager.io/cluster-issuer" = webserver.tls.issuer;
        # Make GCP External LB with static IP
        "kubernetes.io/ingress.class" = "gce";
        "kubernetes.io/ingress.global-static-ip-name" = static-ip-name;
      };
    };
    spec = {
      rule = [
        { host = domain; http.path = [{ backend.service = { name = service; port.number = 8080; }; }]; }
      ];
      tls = [
        { hosts = [ domain ]; secret_name = resource.kubernetes_secret."${service}-ssl".metadata.name; }
      ];
    };
  };
}
