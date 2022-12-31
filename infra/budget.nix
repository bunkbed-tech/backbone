{ billing_account, domain, billing_project, funcs }:
let
  inherit (funcs) genAttrs;
  services = [ "cloudbilling" "iam" "billingbudgets" ];
  makeService = prefix: { service = "${prefix}.googleapis.com"; project = billing_project; };
in
{
  resource.google_project_service = genAttrs services makeService;
  resource.google_billing_budget.overall = {
    inherit billing_account;
    display_name = "Overall Budget";
    amount.specified_amount = { currency_code = "USD"; units = "74"; };
    threshold_rules = [
      { threshold_percent = "1.0"; }
      { threshold_percent = "1.0"; spend_basis = "FORECASTED_SPEND"; }
      { threshold_percent = "0.5"; }
      { threshold_percent = "0.85"; }
    ];
    all_updates_rule = {
      monitoring_notification_channels = [ "\${ google_monitoring_notification_channel.email.id }" ];
      disable_default_iam_recipients = true;
    };
  };
  resource.google_monitoring_notification_channel.email = {
    display_name = "Email Notifications";
    project = billing_project;
    type = "email";
    labels.email_address = "billing@${domain}";
  };
}
