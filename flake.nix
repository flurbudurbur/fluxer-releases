{
  description = "Fluxer AppImage releases for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      # Updated by CI on each new release
      version            = "0.0.8";
      hash_x86_64_linux  = "sha256-GdoBK+Z/d2quEIY8INM4IQy5tzzIBBM+3CgJXQn0qAw=";
      hash_aarch64_linux = "sha256-wxLNekbw3E0YPcC27COWtp8VphKmBB9bF2dp7lnjPf8=";

      appimageFilename = {
        x86_64-linux  = "fluxer-stable-${version}-x86_64.AppImage";
        aarch64-linux = "fluxer-stable-${version}-arm64.AppImage";
      };

      hashes = {
        inherit hash_x86_64_linux hash_aarch64_linux;
      };

      mkFluxer = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nixHash = if system == "x86_64-linux" then hashes.hash_x86_64_linux
                    else hashes.hash_aarch64_linux;
          src = pkgs.fetchurl {
            url = "https://github.com/flurbudurbur/fluxer-releases/releases/download/v${version}/${appimageFilename.${system}}";
            hash = nixHash;
          };
          appimageContents = pkgs.appimageTools.extract {
            pname = "fluxer";
            inherit version src;
          };
        in pkgs.appimageTools.wrapType2 {
          pname = "fluxer";
          inherit version src;

          extraInstallCommands = ''
            install -Dm444 ${appimageContents}/fluxer.desktop \
              $out/share/applications/fluxer.desktop 2>/dev/null || true
            install -Dm444 ${appimageContents}/.DirIcon \
              $out/share/pixmaps/fluxer.png 2>/dev/null || true
          '';
        };

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in {
      packages = nixpkgs.lib.genAttrs supportedSystems (system:
        let pkg = mkFluxer system;
        in { fluxer = pkg; default = pkg; }
      );
    };
}
