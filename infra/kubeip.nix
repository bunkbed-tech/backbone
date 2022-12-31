{ funcs
, project
, address_count
, cluster
, ingress-pool
, web-pool
}:
let
  inherit (builtins) attrNames map toString;
  inherit (funcs) listToAttrsWithKeyFunc range;
  service = "kubeip";
  makeAddress = index: {
    provider = "google-beta";
    name = "${service}-ip${toString index}";
    labels = { ${service} = cluster; };
  };
  makeEnv = cm: key: { name = key; value_from.config_map_key_ref = { inherit key; name = cm.metadata.name; }; };
  makeEnvs = cm: map (makeEnv cm) (attrNames cm.data);
  volume-google = rec {
    name = "google-cloud-key";
    secret.secret_name = "\${ kubernetes_secret.${service}.metadata[0].name }";
    mount_path = "/var/secrets/google";
    file = "${mount_path}/key.json";
  };
in
rec {
  resource.google_service_account.${service} = {
    account_id = service;
  };
  resource.google_project_iam_custom_role.${service} = {
    role_id = service;
    title = service;
    description = "Required permissions to run ${service}";
    stage = "GA";
    permissions = [
      "compute.addresses.list"
      "compute.instances.addAccessConfig"
      "compute.instances.deleteAccessConfig"
      "compute.instances.get"
      "compute.instances.list"
      "compute.projects.get"
      "container.clusters.get"
      "container.clusters.list"
      "resourcemanager.projects.get"
      "compute.networks.useExternalIp"
      "compute.subnetworks.useExternalIp"
      "compute.addresses.use"
    ];
  };
  resource.google_project_iam_binding.${service} = {
    inherit project;
    role = "\${ google_project_iam_custom_role.${service}.id }";
    members = [ "\${ google_service_account.${service}.member }" ];
  };
  resource.google_service_account_key.main = {
    service_account_id = "\${ google_service_account.${service}.name }";
  };
  resource.kubernetes_secret.${service} = {
    metadata = { name = "${service}-key"; namespace = "kube-system"; };
    data = "\${ jsondecode(base64decode(google_service_account_key.main.private_key)) }";
  };
  resource.google_compute_address = listToAttrsWithKeyFunc { valueFunc = makeAddress; } (range 1 address_count);
  resource.kubernetes_config_map.${service} = {
    metadata = { name = "${service}-config"; namespace = "kube-system"; labels = { app = service; }; };
    data = {
      KUBEIP_LABELKEY = service;
      KUBEIP_LABELVALUE = cluster;
      KUBEIP_NODEPOOL = ingress-pool;
      KUBEIP_FORCEASSIGNMENT = true;
      KUBEIP_ADDITIONALNODEPOOLS = "";
      KUBEIP_TICKER = 5;
      KUBEIP_ALLNODEPOOLS = false;
      KUBEIP_ORDERBYLABELKEY = "priority";
      KUBEIP_ORDERBYDESC = true;
      KUBEIP_COPYLABELS = false;
      KUBEIP_CLEARLABELS = false;
      KUBEIP_DRYRUN = false;
    };
  };
  resource.kubernetes_service_account.${service} = {
    metadata = { name = "${service}-sa"; namespace = "kube-system"; };
  };
  resource.kubernetes_cluster_role.${service} = {
    metadata = { inherit (resource.kubernetes_service_account.${service}.metadata) name; };
    rule = [
      { api_groups = [ "" ]; resources = [ "nodes" ]; verbs = [ "get" "list" "watch" "patch" ]; }
      { api_groups = [ "" ]; resources = [ "pods" ]; verbs = [ "get" "list" "watch" ]; }
    ];
  };
  resource.kubernetes_cluster_role_binding.${service} = rec {
    metadata = { inherit (resource.kubernetes_service_account.${service}.metadata) name; };
    role_ref = { api_group = "rbac.authorization.k8s.io"; kind = "ClusterRole"; name = metadata.name; };
    subject = [{ kind = "ServiceAccount"; name = metadata.name; namespace = "kube-system"; }];
  };
# resource.kubernetes_deployment.${service} = {
#   metadata = { name = service; namespace = "kube-system"; };
#   spec = {
#     replicas = 1;
#     selector.match_labels.app = service;
#     template = {
#       metadata.labels.app = service;
#       spec = rec {
#         node_selector."cloud.google.com/gke-nodepool" = web-pool;
#         container = [
#           (rec {
#             name = service;
#             image = "doitintl/${service}:latest";
#             image_pull_policy = "Always";
#             volume_mount = [{ inherit (volume-google) name mount_path; }];
#             env = (makeEnvs resource.kubernetes_config_map.${service}) ++ [
#               { name = "GOOGLE_APPLICATION_CREDENTIALS"; value = volume-google.file; }
#             ];
#           })
#         ];
#         restart_policy = "Always";
#         service_account_name = resource.kubernetes_service_account.${service}.metadata.name;
#         volume = [ { inherit (volume-google) name secret; } ];
#       };
#     };
#   };
# };
}
