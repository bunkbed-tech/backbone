{ google_project, billing_account, org_id }:
{
  resource.google_project.main = rec {
    inherit billing_account org_id;
    inherit (google_project) project_id;
    name = project_id;
  };
}
