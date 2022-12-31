{ lib }:
let
  inherit (builtins) listToAttrs map;
  inherit (lib.attrsets) nameValuePair;
in
{
  listToAttrsWithKeyFunc = { valueFunc, keyFunc ? (o: o.name) }: l:
    listToAttrs (map (o: nameValuePair (keyFunc o) o) (map valueFunc l));
}
