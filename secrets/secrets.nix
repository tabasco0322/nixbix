let
  inherit (builtins)
    all
    any
    attrValues
    concatMap
    elem
    elemAt
    filter
    foldl'
    getFlake
    hasAttr
    isList
    length
    listToAttrs
    split
    ;

  last = list: elemAt list (length list - 1);

  flatten = x: if isList x then concatMap flatten x else [ x ];

  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [ ];

  hasAttrsFilter = attrsList: filter (attr: all (key: hasAttr key attr) attrsList);

  hostConfigsList = map (host: host.config) (
    attrValues (getFlake (toString ../.)).nixosConfigurations
  );

  hostsWithSecrets = hasAttrsFilter [ "publicKey" "age" ] hostConfigsList;

  toLocalSecretPath = path: last (split "/secrets/" path);

  secretsList = unique (
    flatten (
      map (
        host: map (s: toLocalSecretPath (toString s.file)) (attrValues host.age.secrets)
      ) hostsWithSecrets
    )
  );

  mapSecretToPublicKeys =
    secret:
    unique (
      map (host: host.publicKey) (
        filter (
          host: any (s: secret == toLocalSecretPath (toString s.file)) (attrValues host.age.secrets)
        ) hostsWithSecrets
      )
    );
  nemko = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFh4MHoAx2/HhQf6mGnb3HJI8DDJtNkC84dhaNPnHZfE"
  ];
in
listToAttrs (
  map (name: {
    inherit name;
    value.publicKeys = nemko ++ (mapSecretToPublicKeys name);
  }) secretsList
)
