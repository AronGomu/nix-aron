{
  stdenv,
  lib,
  fetchFromGitHub,
  qt6,
}:
stdenv.mkDerivation rec {
  pname = "omawrite";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "omawrite";
    tag = "v${version}";
    hash = "sha256-yS3GOL/kc03qx4naWzUdSZwAYxMuCjvrgmhexpwjsfA=";
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
    install -Dm755 omawrite $out/bin/omawrite
    runHook postInstall
  '';

  meta = {
    description = "Dead-simple Markdown writing app built with Qt Quick (Omarchy)";
    homepage = "https://github.com/omacom/omawrite";
    license = lib.licenses.mit;
    mainProgram = "omawrite";
  };
}
