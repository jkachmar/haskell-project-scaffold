# to see ghc versions:
# nix-instantiate --eval -E "let sources = import ./nix/sources.nix; pkgs = import sources.nixpkgs {}; in pkgs.lib.attrNames pkgs.haskell.compiler"
{ pkgs ? null
, compiler ? null
, withHoogle ? true 
}:

let

  nixpkgs = 
    if isNull pkgs then
      import (import ./nix/sources.nix).nixpkgs {}
    else if builtins.typeOf pkgs == "set" then
      pkgs
    else
      import (builtins.getAttr pkgs (import ./nix/sources.nix)) {};

  inShell = nixpkgs.lib.inNixShell;

  haskellPackagesNoHoogle = 
    if isNull compiler then
      nixpkgs.haskellPackages
    else
      nixpkgs.haskell.packages.${compiler};

  haskellPackagesWithHoogle = haskellPackagesNoHoogle.override {
    overrides = (self: super: {
      ghc = super.ghc // { withPackages = super.ghc.withHoogle; };
      ghcWithPackages = self.ghc.withPackages;
    });
  };

  haskellPackages = 
    if (inShell && withHoogle) then
      haskellPackagesWithHoogle
    else
      haskellPackagesNoHoogle;

  source = nixpkgs.nix-gitignore.gitignoreSource [ ] ./.;

  overrides = import ./nix/overrides.nix {
    pkgs = nixpkgs;
    haskellPackages = haskellPackages;
  };

  build = 
    haskellPackages.callCabal2nixWithOptions
      "{{cookiecutter.package_name}}" 
      source 
      "--hpack"
      overrides;

  shell = nixpkgs.mkShell {
    inputsFrom = [ build.env ];
    buildInputs = [ 
      # Haskell-specific development dependencies
      haskellPackages.ghcid
      haskellPackages.cabal-install
      nixpkgs.stack

      # General-purpose development dependencies
      nixpkgs.niv
    ];
  };

in 
  if inShell then 
    shell
  else 
    build
