{
  description = "Personal Blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    theme = {
      url = "github:ebkalderon/terminus";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          name = "static-website";
          src = self;
          nativeBuildInputs = with pkgs; [
            zola
          ];

          buildPhase = ''
            mkdir -p themes
            ln -s ${inputs.theme} themes/main-theme
            zola build
          '';

          installPhase = ''
            mkdir -p $out
            cp -r public/. $out/
          '';
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            zola
          ];
          shellHook = ''
            mkdir -p themes
            ln -s ${inputs.theme} themes/main-theme
          '';
        };
      });
    };
}
