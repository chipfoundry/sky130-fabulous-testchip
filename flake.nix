{
  nixConfig = {
    extra-substituters = [
      "https://nix-cache.fossi-foundation.org"
    ];
    extra-trusted-public-keys = [
      "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
    ];
  };

  inputs = {
    librelane_plugin_fabulous.url = "github:mole99/librelane_plugin_fabulous/1.7.0";
  };

  outputs =
    {
      self,
      librelane_plugin_fabulous,
      ...
    }:
    let
      librelane = librelane_plugin_fabulous.inputs.librelane;
      nix-eda = librelane.inputs.nix-eda;
      devshell = librelane.inputs.devshell;
      nixpkgs = nix-eda.inputs.nixpkgs;
      lib = nixpkgs.lib;
    in
    {
      # Outputs
      legacyPackages = nix-eda.forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            nix-eda.overlays.default
            devshell.overlays.default
            librelane.overlays.default
            librelane_plugin_fabulous.overlays.default
            (nix-eda.composePythonOverlay (
            pkgs': pkgs: pypkgs': pypkgs:
            let
              callPythonPackage = lib.callPackageWith (pkgs' // pypkgs');
            in
            {
              cocotbext-spi = callPythonPackage ./nix/cocotbext-spi.nix { };
            }
          ))
          (final: prev: {
            nextpnr = prev.nextpnr.overrideAttrs {
              version = "87f8f83b";
              src = prev.fetchFromGitHub {
                owner = "mole99";
                repo = "nextpnr";
                rev = "87f8f83ba44a380ca502a726dbaf7040a12931ab";
                hash = "sha256-7QCpZI6Pje92howE/x0fHguaQLefM1VQJma1RMXgXzw=";
                fetchSubmodules = true;
              };
              cmakeFlags = [
                "-DCURRENT_GIT_VERSION=nextpnr-0e66c0ce"
                "-DARCH=generic"
                "-DBUILD_TESTS=ON"
                "-DUSE_OPENMP=ON"
                "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
              ];
            };
          })
          (final: prev: {
            yosys = prev.yosys.overrideAttrs {
              version = "774d9ba3";
              src = prev.fetchGitHubSnapshot {
                owner = "mole99";
                repo = "yosys";
                rev = "774d9ba3109f5b338d8724309cbf96941eb966b3";
                hash = "sha256-cLpKgDzCq1zDFSbFqcbgu2nGOUMMBGr0BCKk1/KUFJ4=";
                add-gitcommit = true;
              };
            };
          })
          ];
        }
      );

      packages = nix-eda.forAllSystems (system: {
        inherit (self.legacyPackages.${system}.python3.pkgs) ;
      });

      devShells = nix-eda.forAllSystems (
        system:
        let
          pkgs = (self.legacyPackages.${system});
          callPackage = lib.callPackageWith pkgs;
        in
        {
          default = pkgs.librelane-shell.override ({
            librelane-plugins = ps: with ps; [librelane-plugin-fabulous];
            extra-packages = with pkgs; [
              # Utilities
              gnumake
              gnugrep
              gawk

              # Simulation
              iverilog
              verilator

              # PnR
              nextpnr

              # Waveform viewing
              gtkwave
              surfer
            ];
            extra-python-packages = ps: with ps; [
              # Verification
              cocotb
              cocotbext-spi
              pytest
              pyyaml
            ];
          });
        }
      );
    };
}
