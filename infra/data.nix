{ org, domain }:
{
  data.google_organization.${org} = { inherit domain; };
  data.google_billing_account.tristan-united = { display_name = "tristan-united"; };
  data.google_client_config.default = { };
}
