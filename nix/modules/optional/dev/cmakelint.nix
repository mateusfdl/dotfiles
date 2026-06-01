{ pkgs, ... }:
let
  cmakelint = pkgs.python3Packages.buildPythonApplication rec {
    pname = "cmakelint";
    version = "1.4.3";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-mKHkhTGLQe6vTe40acowOdR0WYU1Ps6iCNbdLBIExx0=";
    };

    build-system = [ pkgs.python3Packages.setuptools ];

    pythonImportsCheck = [ "cmakelint" ];

    meta = {
      description = "Linter for CMake files";
      homepage = "https://github.com/cmake-lint/cmake-lint";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "cmakelint";
    };
  };
in
{
  environment.systemPackages = [ cmakelint ];
}
