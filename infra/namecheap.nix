{ domain, ips, funcs }:
let
  inherit (builtins) map;
  inherit (funcs) concatMap;
  makeRecords = ip: map (h: { hostname = h; type = "A"; address = ip; }) [ "@" "*" ];
in
{
  resource.namecheap_domain_records.dns = {
    inherit domain;
    mode = "MERGE";
    record = concatMap makeRecords ips;
  };
}
