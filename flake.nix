{
  description = "Personal Blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-zola.url = "github:NixOS/nixpkgs/a50ab42bfe17b6cb772d43a8b9c8fef9d650c556";
    theme = {
      url = "github:ebkalderon/terminus";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-zola,
      ...
    }@inputs:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});
      zolaForAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: function nixpkgs-zola.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          name = "static-website";
          src = self;
          nativeBuildInputs = [
            (zolaForAllSystems (p: p.zola)).${pkgs.system}
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
          packages = [
            (zolaForAllSystems (p: p.zola)).${pkgs.system}
          ];
          shellHook = ''
            mkdir -p themes
            ln -sfn ${inputs.theme} themes/main-theme
          '';
        };
      });
    };
}
