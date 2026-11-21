{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "cmakelint";
  version = "1.4.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-mKHkhTGLQe6vTe40acowOdR0WYU1Ps6iCNbdLBIExx0=";
  };

  build-system = [ python3Packages.setuptools ];

  pythonImportsCheck = [ "cmakelint" ];

  meta = {
    homepage = "https://github.com/cmake-lint/cmake-lint";
    license = lib.licenses.asl20;
    mainProgram = "cmakelint";
  };
}
