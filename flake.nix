{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        system,
        self',
        ...
      }: let
        zigEnv = inputs.zig2nix.zig-env.${system} {};
      in {
        packages = rec {
          default = pkgs.makeOverridable ({
            withOpenGl ? true,
            withVulkan ? true,
            withCairo ? true,
            withStub ? true,
            cairo ? null,
          }:
            zigEnv.package {
              src = pkgs.lib.cleanSource ./.;

              nativeBuildInputs = with pkgs; [
                python3
              ];

              buildInputs = with pkgs; [
                cairo
                libGL
                pkg-config
                vulkan-loader
                xorg.libX11
                xorg.libXcursor
                xorg.libXext
                xorg.libXrandr
              ];

              zigBuildFlags =
                pkgs.lib.optional withOpenGl "-Dopengl=true"
                ++ pkgs.lib.optional withVulkan "-Dvulkan=true"
                ++ pkgs.lib.optional withCairo "-Dcairo=true"
                ++ pkgs.lib.optional (cairo != null) "-Dbuild_cairo=false"
                ++ pkgs.lib.optional withStub "-Dstub=true";
            }) {};

          docs =
            (default.override {inherit (pkgs) cairo;})
            .overrideAttrs (old: {
              pname = "pugl-docs";
              zigBuildFlags = ["docs"] ++ old.zigBuildFlags;
            });
        };

        devShells.default = zigEnv.mkShell {
          nativeBuildInputs = with pkgs; [
            zls
          ];

          inherit (self'.packages.default) buildInputs;
        };
      };
    };
}
