let pkgs = import <nixpkgs> {};
    ghc = "ghc901";
in
with pkgs;
let ghcCompiler = haskell.compiler.${ghc};
    ghcHaskellPkgs = haskell.packages.${ghc};
#     // {
#      doCheck = false;
#      doHaddock = false;
#      enableExecutableProfiling = false;
#      enableLibraryProfiling = false;
#    };
   frameworks = pkgs.darwin.apple_sdk.frameworks;

   wxdirectDrv = ghcHaskellPkgs.callCabal2nix "wxdirect" ./wxdirect/wxdirect.cabal {};
   # wxcDrv = ghcHaskellPkgs.callCabal2nix "wxc" ./wxc/wxc.cabal { wxdirect = wxdirectDrv; };
   wxcoreDrv = with ghcHaskellPkgs;
            ghcHaskellPkgs.mkDerivation {
              pname = "wxcore";
              version = "0.93.0.0";
              src = pkgs.nix-gitignore.gitignoreSource [] ./wxcore;
              setupHaskellDepends = [
                base bytestring Cabal directory filepath process split
                ];
              libraryHaskellDepends = [ base split wxdirectDrv ];
              doHaddock = false;
              #  postInstall = "cp -v dist/build/libwxc.so.0.93.0.0 $out/lib/libwxc.so";
              #  postPatch = "sed -i -e '/ldconfig inst_lib_dir/d' Setup.hs";
              homepage = "https://wiki.haskell.org/WxHaskell";
              description = "Lowlevel haskell interface to wxc.";
              license = "unknown";
              hydraPlatforms = lib.platforms.none;
            };

in
ghcHaskellPkgs.shellFor {
  name = "wxHaskell-dev-shell";
  packages = pkgset: [ wxdirectDrv ];
  passthru.pkgs = pkgs;
  src = pkgs.nix-gitignore.gitignoreSource [] ./.;
  nativeBuildInputs = with ghcHaskellPkgs;
                      [ cabal-install
                      ];
  buildInputs =
                [ autoconf automake m4 cmake
                  less which man git
                  wxmac
                  frameworks.AGL
                  frameworks.OpenGL
                  frameworks.CoreFoundation
                  frameworks.CoreServices
                  frameworks.AudioToolbox
                  frameworks.Cocoa
                ];
}
