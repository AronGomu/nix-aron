{
  lib,
  stdenv,
  fetchFromGitHub,
  runCommand,
  buildNpmPackage,
  rustPlatform,
  cargo,
  rustc,
  nodejs,
  pkg-config,
  gtk3,
  webkitgtk_4_1,
  libayatana-appindicator,
  openssl,
  glib,
  gdk-pixbuf,
  cairo,
  pango,
  perl,
  atk,
}:
buildNpmPackage rec {
  pname = "file-explorer";
  version = "0.2.3";

  src = runCommand "file-explorer-source" { } ''
    cp -R ${fetchFromGitHub {
      owner = "conaticus";
      repo = "FileExplorer";
      rev = "22b69f5a677f23ec96f0578acdcf6ce76a2db60b";
      hash = "sha256-HrdQq147Sbarycaw5xkv9U53SCRn9EtFVs5eMd+9jbU=";
    }} $out
    chmod -R u+w $out
    cp ${./file-explorer-Cargo.lock} $out/src-tauri/Cargo.lock
  '';

  postPatch = ''
    cp ${./file-explorer-package-lock.json} package-lock.json
    cp ${./file-explorer-Cargo.lock} Cargo.lock
    cp ${./file-explorer-Cargo.lock} src-tauri/Cargo.lock
  '';

  npmDepsHash = "sha256-y+zzZ2Ttrgo7qcfADVLezPk2T+2ydK9Bj9dJ8J3cvX0=";
  cargoRoot = "src-tauri";
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    cargoRoot = "src-tauri";
    hash = "sha256-kSaj5v5H1eTVoKnAx4fxANmeEFYzeSUGf8nMvwU40TI=";
  };

  nativeBuildInputs = [
    cargo
    nodejs
    perl
    rustPlatform.cargoSetupHook
    pkg-config
    rustc
  ];
  buildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    openssl
    pango
    webkitgtk_4_1
  ];

  buildPhase = ''
    runHook preBuild
    npm run build
    cargo build --offline --release --locked --manifest-path src-tauri/Cargo.toml
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 target/release/src-tauri $out/bin/file-explorer
    install -Dm644 src-tauri/icons/logo_128x128.png \
      $out/share/icons/hicolor/128x128/apps/file-explorer.png
    install -Dm644 src-tauri/icons/logo_32x32.png \
      $out/share/icons/hicolor/32x32/apps/file-explorer.png
    install -Dm644 /dev/stdin $out/share/applications/file-explorer.desktop <<'EOF'
    [Desktop Entry]
    Name=File Explorer
    Comment=Fast file explorer
    Exec=file-explorer
    Icon=file-explorer
    Terminal=false
    Type=Application
    Categories=Utility;FileManager;
    EOF
    runHook postInstall
  '';

  meta = {
    description = "Fast file explorer built with Rust and Tauri";
    homepage = "https://github.com/conaticus/FileExplorer";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "file-explorer";
  };
}
