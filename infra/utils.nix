{ pkgs, lib }:
let
  inherit (builtins) fetchurl fromJSON listToAttrs map readFile toFile toJSON;
  inherit (lib.attrsets) nameValuePair;
  inherit (pkgs) runCommand yj;
in
{
  listToAttrsWithKeyFunc = { valueFunc, keyFunc ? (o: o.name) }: l:
    listToAttrs (map (o: nameValuePair (keyFunc o) o) (map valueFunc l));
  importYaml = url: fromJSON (readFile (runCommand "y-j.json" "${yj}/bin/yj < '${fetchurl url}' > '$out'"));
  toHCL = o: readFile (runCommand "j-c.json" "echo '${toJSON o}' | ${yj}/bin/yj -jc > '$out'");
}
