{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig = {
      url = "github:bandithedoge/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          pkgs,
          system,
          self',
          ...
        }:
        let
          zig' = inputs.zig.packages.${system}."0_15_2";
        in
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              zig'
              zig'.zls
              python3
              pkg-config
            ];

            buildInputs = with pkgs; [
              cairo
              libGL
              vulkan-loader
              xorg.libX11
              xorg.libXcursor
              xorg.libXext
              xorg.libXrandr
              xorg.libXrender
            ];
          };
        };
    };
}
