{ lib
, fetchFromGitHub
, buildNpmPackage
, electron
, makeWrapper
}:

buildNpmPackage rec {
  pname = "neo";
  version = "0.7.10";

  src = fetchFromGitHub {
    owner = "hughhowey";
    repo = "neo";
    rev = "9d8ba5adbfdaa4d7c1d02a702274d47ae0b46812";
    hash = "sha256-7e58YdIkSaSmlI3B3NC5hpTfODScs47YVyhg7xkWW50=";
  };

  npmDepsHash = "sha256-RsnHHLUSScZ55nUe5JjZ7WWegXRnjSVj/9og0+8Xs1o=";
  nativeBuildInputs = [ makeWrapper ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/neo $out/bin $out/share/applications
    cp -R . $out/lib/neo
    makeWrapper ${electron}/bin/electron $out/bin/neo \
      --add-flags $out/lib/neo
    cat > $out/share/applications/neo.desktop <<'EOF'
    [Desktop Entry]
    Name=NEO
    Comment=Distraction-free word processor for authors
    Exec=neo %U
    Terminal=false
    Type=Application
    Categories=Office;WordProcessor;
    EOF
    runHook postInstall
  '';

  meta = {
    description = "Distraction-free word processor for authors";
    homepage = "https://github.com/hughhowey/neo";
    license = lib.licenses.mit;
    mainProgram = "neo";
  };
}
