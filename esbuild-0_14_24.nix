{ buildGoModule, fetchFromGitHub, lib }:

# Based on pkgs/development/tools/esbuild/default.nix
buildGoModule rec {
  pname = "esbuild";
  version = "0.14.22";

  src = fetchFromGitHub {
    owner = "evanw";
    repo = "esbuild";
    rev = "v${version}";
    sha256 = "sha256-oD8QjjolEfmfxs+Q4duVUCbEp74HzIWaPrmH8Vn1H+o=";
  };

  vendorSha256 = "sha256-2ABWPqhK2Cf4ipQH7XvRrd+ZscJhYPc3SV2cGT0apdg=";

  meta = with lib; {
    description = "An extremely fast JavaScript bundler";
    homepage = "https://esbuild.github.io";
    license = licenses.mit;
    maintainers = with maintainers; [ lucus16 ];
  };
}
