{ org, project, kubernetes }:
rec {
  terraform.required_providers.namecheap = {
    source = "namecheap/namecheap";
    version = "2.1.0";
  };
  provider.namecheap = rec {
    api_user = "\${ var.namecheap_api_user }";
    api_key = "\${ var.namecheap_api_key }";
    user_name = api_user;
  };
  provider.google = {
    project = "${org}-${project}";
    region = "us-central1";
    zone = "us-central1-a";
    billing_project = "${org}-billing";
    user_project_override = true;
  };
  provider.google-beta = provider.google;
  provider.kubernetes = kubernetes;
  provider.helm = { inherit kubernetes; };
}
