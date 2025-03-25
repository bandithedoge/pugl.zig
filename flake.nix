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
        packages.default = zigEnv.package {
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

          zigBuildFlags = [
            "docs"
            "-Dopengl=true"
            "-Dvulkan=true"
            "-Dcairo=true"
            "-Dbuild_cairo=false"
            "-Dstub=true"
          ];
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
