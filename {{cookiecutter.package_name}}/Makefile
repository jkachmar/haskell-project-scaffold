.PHONY: list-ghcs
list-ghcs:
	nix-instantiate --eval -E "let sources = import ./nix/sources.nix; pkgs = import sources.nixpkgs {}; in pkgs.lib.attrNames pkgs.haskell.compiler"
