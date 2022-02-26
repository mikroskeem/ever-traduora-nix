{ stdenv, lib, fetchFromGitHub, mkYarnPackage, makeWrapper, jq, nodejs, nodePackages, xcbuild, esbuild }:
let
  base = "ever-traduora";
  version = "0.19.2";

  traduoraSrc = fetchFromGitHub {
    owner = "ever-co";
    repo = base;
    rev = "v${version}";
    sha256 = "sha256-Jc4l5t0po4OdwKRjBqzH+7fnV4yD8AkrkR8JYfw6zYg=";
  };

  web = stdenv.mkDerivation rec {
    pname = "${base}-web";
    inherit version;
    name = "${pname}-${version}"; # XXX: `nix flake show` IFD fix

    src = ./prebuilt + "/ever-traduora-v${version}.tar.gz";

    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      tar -C $out -xzf $src

      runHook postInstall
    '';
  };

  api = mkYarnPackage rec {
    pname = "${base}-api";
    inherit version;
    name = "${pname}-${version}"; # XXX: `nix flake show` IFD fix

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

    postPatch = ''
      # Hardcode paths to the database entities and migrations, so
      # program launching wouldn't depend on the cwd
      substituteInPlace src/config.ts \
        --replace 'src/entity/' '${placeholder "out"}/libexec/ever-traduora-api/deps/dist/src/entity/'

      substituteInPlace src/config.ts \
        --replace 'src/migrations/' '${placeholder "out"}/libexec/ever-traduora-api/deps/dist/src/migrations/'
    '';

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
        --run "cd $out/libexec/ever-traduora-api/deps/dist" \
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
