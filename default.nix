{ stdenv, lib, fetchFromGitHub, mkYarnPackage, makeWrapper, jq, nodejs, nodePackages, xcbuild }:
let
  base = "ever-traduora";
  version = "0.19.0";

  traduoraSrc = fetchFromGitHub {
    owner = "ever-co";
    repo = base;
    rev = "v${version}";
    sha256 = "sha256-jCH6zvCrMB9GINxYbK0qD33N5lnAnGj1kYgGC3qxZ4E=";
  };

  web = mkYarnPackage rec {
    pname = "${base}-web";
    inherit version;

    src = "${traduoraSrc}/webapp";

    nativeBuildInputs = [ jq ];

    postPatch = ''
      # I give up...
      substituteInPlace src/styles.scss \
        --replace "../node_modules/" "$(pwd)/node_modules/"
      substituteInPlace src/custom_bootstrap.scss \
        --replace "../node_modules/" "$(pwd)/node_modules/"

      substituteInPlace angular.json \
        --replace "../dist/public" "$(pwd)/dist"

      # https://github.com/angular/angular-cli/issues/19401
      jq '.projects."traduora-webapp".architect.build.configurations.production.optimization = { fonts: false }' < angular.json > angular.new.json
      mv angular.new.json angular.json
    '';

    preBuild = ''
      # Work around NgCC failing because of EACCESS - silly NgCC wants to
      # write into node_modules
      pushd deps/ever-traduora-webapp
      mv node_modules node_modules.old
      mkdir node_modules
      cd node_modules
      for d in ../node_modules.old/* ../node_modules.old/.bin; do
        ln -s "$d" $(basename -- "$d")
      done
      popd
    '';

    buildPhase = ''
      runHook preBuild
      yarn build --prod
      runHook postBuild
    '';

    installPhase = ''
      mkdir -p $out
      mv dist/* $out/
    '';

    distPhase = ":";
    dontStrip = true;
    yarnNix = ./yarn-web.nix;
  };

  api = mkYarnPackage rec {
    pname = "${base}-api";
    inherit version;

    src = "${traduoraSrc}/api";

    nativeBuildInputs = [
      makeWrapper
      nodejs
      nodejs.passthru.python
      nodePackages.node-gyp
      nodePackages.node-pre-gyp
    ] ++ lib.optionals stdenv.isDarwin [
      xcbuild
    ];

    preBuild = ''
      # XXX: ?
      substituteInPlace node_modules/node-addon-api/napi.h \
        --replace "<node_api.h>" '"${nodejs}/include/node/node_api.h"'

      # Build bcrypt natives
      tmphome="$(mktemp -d)"
      pushd node_modules/bcrypt
      env HOME="$tmphome" node-pre-gyp install --fallback-to-build --nodedir=${nodejs}/include/node
      popd
    '';

    buildPhase = ''
      runHook preBuild
      yarn build
      runHook postBuild
    '';

    distPhase = ":"; # unneeded tarball
    postInstall = ''
      makeWrapper '${nodejs}/bin/node' "$out/bin/traduora-api" \
        --add-flags "$out/libexec/ever-traduora-api/deps/dist/src/main.js" \
        --set-default NODE_ENV "production" \
        --set-default TR_PUBLIC_DIR "${web}"
    '';

    doDist = false; # XXX: does not work?
    dontStrip = true;
    yarnNix = ./yarn-api.nix;

    passthru.web = web; # Exposed for e.g nginx
  };
in
api
