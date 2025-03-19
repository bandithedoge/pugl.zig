{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig.url = "github:Cloudef/zig2nix";
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
        zigEnv = inputs.zig.outputs.zig-env.${system} {
          zig = inputs.zig.packages.${system}.zig-0_14_0;
        };
      in {
        packages.default = zigEnv.package {
          pname = "pugl.zig";
          version = "0.1.0";
          src = pkgs.lib.cleanSource ./.;

          buildInputs = with pkgs; [
            libGL
            pkg-config
            vulkan-loader
            xorg.libX11
            xorg.libXcursor
            xorg.libXext
            xorg.libXrandr
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
