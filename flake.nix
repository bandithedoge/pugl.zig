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
        ...
      }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            inputs.zig.packages.${system}.zig-0_14_0
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
