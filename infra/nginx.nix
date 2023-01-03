{ domain, webserver, ingress-pool, issuer, tls, taint, ip, funcs }:
let
  inherit (builtins) getAttr toJSON toString;
  inherit (funcs) importYaml toHCL;
  service = "nginx";
  cert-volume = rec { name = "web-certs"; secret.secret_name = tls.secret; mount_path = "/cert"; };
  conf-volume = rec {
    name = "nginx-conf";
    config_map.name = "\${ kubernetes_config_map.${service}.metadata[0].name }";
    sub_path = "default.conf";
    mount_path = "/etc/nginx/conf.d/${sub_path}";
  };
  taintEffectMap = value: getAttr value {
    NO_SCHEDULE = "NoSchedule";
    PREFER_NO_SCHEDULE = "PreferNoSchedule";
    NO_EXECUTE = "NoExecute";
  };
  tolerations = [{ inherit (taint) key value; operator = "Equal"; effect = taintEffectMap taint.effect; }];
in
rec {
  resource.kubernetes_config_map.${service} = {
    metadata = { name = service; };
    data.${conf-volume.sub_path} = ''
      # Allow variables in proxy_pass + bypass startup checks
      # Variables must use: FQDN <service>.<namespace>.svc.cluster.local
      resolver kube-dns.kube-system.svc.cluster.local valid=30s ipv6=off;

      server {
        listen 80;
        listen [::]:80;
        server_name ${domain};
#       return 301 https://$host$request_uri;

        location / {
          set $upstream "http://${webserver.name}.${webserver.namespace}.svc.cluster.local:${toString webserver.port}";
          proxy_pass $upstream;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
          root /usr/share/nginx/html;
        }
      }

      server {
        listen 443 ssl;
        server_name ${domain};
        ssl_certificate /cert/tls.crt;
        ssl_certificate_key /cert/tls.key;
        ssl_protocols TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
          set $upstream "http://${webserver.name}.${webserver.namespace}.svc.cluster.local:${toString webserver.port}";
          proxy_pass $upstream;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
          root /usr/share/nginx/html;
        }
      }
    '';
  };
  resource.kubernetes_deployment.${service} = rec {
    metadata = rec {
      name = service;
      labels.app = name;
    };
    spec = {
      replicas = 1;
      selector.match_labels = metadata.labels;
      template = {
        metadata.labels = metadata.labels;
        spec = rec {
          host_network = true;
          dns_policy = "ClusterFirstWithHostNet";
          node_selector."cloud.google.com/gke-nodepool" = ingress-pool;
          toleration = [{ inherit (taint) key value; operator = "Equal"; effect = taintEffectMap taint.effect; }];
          container = [
            {
              name = metadata.name;
              image = service;
              port = [
                { name = "https"; container_port = 443; host_port = 443; }
                { name = "http"; container_port = 80; host_port = 80; }
              ];
              volume_mount = [
                { inherit (cert-volume) name mount_path; read_only = true; }
                { inherit (conf-volume) name mount_path sub_path; read_only = true; }
              ];
            }
          ];
          volume = [
            { inherit (cert-volume) name secret; }
            { inherit (conf-volume) name config_map; }
          ];
        };
      };
    };
  };
# resource.kubernetes_service.${service} = rec {
#   inherit (resource.kubernetes_deployment.${service}) metadata;
#   spec = {
#     type = "ClusterIP";
#     port = [ { name = "http"; port = 80; } { name = "https"; port = 443; } ];
#     selector = metadata.labels;
#   };
# };
# resource.kubernetes_ingress_v1.ingress = {
#   metadata = {
#     name = "ingress";
#     namespace = "default";
#     annotations."cert-manager.io/cluster-issuer" = issuer;
#     annotations."acme.cert-manager.io/http01-edit-in-place" = true;
#   };
#   spec.rule = [
#     {
#       host = domain;
#       http.path = [
#         {
#           path = "/";
#           backend.service = {
#             name = webserver.name;
#             port.number = webserver.port;
#           };
#         }
#       ];
#     }
#   ];
#   spec.tls = [
#     { inherit (cert-volume.secret) secret_name; hosts = [ domain "www.${domain}" ]; }
#   ];
#   spec.ingress_class_name = service;
# };
}
