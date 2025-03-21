{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShell.override {stdenv = pkgs.zigStdenv;} {
          nativeBuildInputs = with pkgs; [
            zig
            zls
          ];

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
      };
    };
}
