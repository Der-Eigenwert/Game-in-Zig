{ pkgs ? import <nixpkgs> {} }:

let
  zig = pkgs.stdenv.mkDerivation {
    name = "zig-0.8.0-dev.1060+1ed8c54cd";

    src = pkgs.fetchurl {
      url = https://ziglang.org/builds/zig-linux-x86_64-0.8.0-dev.1060+1ed8c54cd.tar.xz;
      sha256 = "f44d9e4331c38f5cf2dea4902c9a7ab37fb2f7096a06d2f0cb18b3d9b07a9b6f";
    };

    installPhase = ''
      mkdir -p $out/bin

      cp zig $out/bin
      cp -r lib/ $out
    '';
  };
  zls = pkgs.stdenv.mkDerivation {
    name = "zls-0.1.0";

    src = pkgs.fetchurl {
      url = https://github.com/zigtools/zls/releases/download/0.1.0/x86_64-linux.tar.xz;
      sha256 = "1jswk9z2dy0jjlrywkn617i4rhyf40xl0hh23mnzhblqws2sf60k";
    };

    installPhase = ''
      mkdir -p $out/bin

      cp * $out/bin
    '';
  };
in
pkgs.mkShell {
  buildInputs = [
    zig

    zls

    pkgs.SDL2

    pkgs.bashInteractive
  ];
}
