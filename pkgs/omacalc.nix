{
  stdenv,
  lib,
  fetchFromGitHub,
  qt6,
}:
stdenv.mkDerivation rec {
  pname = "omacalc";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "omacalc";
    tag = "v${version}";
    hash = "sha256-I+WxkMz/2hCf4OpJKu99+30c0CxyxFD0M6eSLFDLs1I=";
  };

  nativeBuildInputs = [
    qt6.qmake
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 omacalc $out/bin/omacalc
    runHook postInstall
  '';

  meta = {
    description = "Omarchy's simple calculator";
    homepage = "https://github.com/omacom/omacalc";
    license = lib.licenses.mit;
    mainProgram = "omacalc";
  };
}
