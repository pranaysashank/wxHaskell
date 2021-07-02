let pkgs = import <nixpkgs> {};
in
with pkgs;
let frameworks = pkgs.darwin.apple_sdk.frameworks;
in
mkShell {
  name = "wxc-dev-shell";
  packages = [ ];
  passthru.pkgs = pkgs;
  src = pkgs.nix-gitignore.gitignoreSource [] ./.;
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
