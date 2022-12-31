{ org, project }:
{
  terraform.backend.gcs = {
    bucket = "${org}-terraform";
    prefix = "${project}/state";
  };
}
