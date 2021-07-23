{ stdenv, lib, fetchFromGitHub, mkYarnPackage, makeWrapper, nodejs, nodePackages, python3, xcbuild }:
let
  base = "ever-traduora";
  version = "0.19.0";

  traduoraSrc = fetchFromGitHub {
    owner = "ever-co";
    repo = base;
    rev = "v${version}";
    sha256 = "sha256-jCH6zvCrMB9GINxYbK0qD33N5lnAnGj1kYgGC3qxZ4E=";
  };
in
{
  api = mkYarnPackage rec {
    pname = "${base}-api";
    inherit version;

    src = "${traduoraSrc}/api";

    buildInputs = [ ];
    nativeBuildInputs = [
      makeWrapper
      python3
      nodePackages.node-gyp
      nodePackages.node-pre-gyp
    ] ++ lib.optionals stdenv.isDarwin [
      xcbuild
    ];

    buildPhase = ''
      runHook preBuildHook
      yarn build

      # Build bcrypt natives
      tmphome="$(mktemp -d)"
      pushd node_modules/bcrypt
      env HOME="$tmphome" node-pre-gyp install --fallback-to-build
      popd

      runHook postBuildHook
    '';

    distPhase = ":"; # unneeded tarball
    postInstall = ''
      makeWrapper '${nodejs}/bin/node' "$out/bin/traduora-api" \
        --add-flags "$out/libexec/ever-traduora-api/deps/dist/src/main.js"
    '';

    doDist = false; # XXX: does not work?
    dontStrip = true;
    yarnNix = ./yarn-api.nix;
  };
  web = mkYarnPackage rec {
    pname = "${base}-web";
    inherit version;

    src = "${traduoraSrc}/webapp";

    postPatch = ''
      # I give up...
      substituteInPlace src/styles.scss \
        --replace "../node_modules/" "$(pwd)/node_modules/"
      substituteInPlace src/custom_bootstrap.scss \
        --replace "../node_modules/" "$(pwd)/node_modules/"

      substituteInPlace angular.json \
        --replace "../dist/public" "$(pwd)/dist"
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
}
