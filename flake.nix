{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = (crane.mkLib nixpkgs.legacyPackages.${system});
        my-crate = craneLib.buildPackage {
          src = craneLib.cleanCargoSource (craneLib.path ./.);

          buildInputs = [
            pkgs.just
            pkgs.protobuf
            pkgs.openssl
            pkgs.openssl.dev
            pkgs.zlib
            pkgs.gcc
            pkgs.gcc.cc.lib
            pkgs.pkg-config
            pkgs.libclang.lib
            pkgs.clang
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.libiconv
          ];
        };

      in
      {
        packages.default = my-crate;

        devShells.default = craneLib.devShell {
          inputsFrom = [ my-crate ];
          packages = [
            pkgs.just
            pkgs.openssl
            pkgs.openssl.dev
            pkgs.zlib
            pkgs.postgresql
            pkgs.gcc
            pkgs.rust-analyzer
            pkgs.diesel-cli
            pkgs.gcc.cc.lib
            pkgs.pkg-config
            pkgs.libclang.lib
            pkgs.clang
            pkgs.flyctl
          ];
          shellHook = ''
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
            export LD_LIBRARY_PATH=${pkgs.openssl}/bin:${pkgs.gcc.cc.lib}/lib:$LD_LIBRARY_PATH
            export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig
          '';
        };
      });
}
