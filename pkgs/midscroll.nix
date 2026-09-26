{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  wrapGAppsHook3,
  python3Packages,
  gtk4,
  gtk4-layer-shell,
  kdotool,
  xprop,
  polkit,
  systemd,
}:
let
  pythonEnv = python3Packages.python.withPackages (ps: [
    ps.evdev
    ps.pygobject3
    ps.pycairo
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "midscroll";
  version = "2026-02-13";

  src = fetchFromGitHub {
    owner = "gnhen";
    repo = "midscroll";
    rev = "ac76b554cf6b279d646dee8336b45390d9db3597";
    hash = "sha256-x/pmdmkCNtsng57jSYpvfNTFHzsm9Qddp2sFXqEQzyQ=";
  };

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
  ];

  dontBuild = true;

  installPhase = ''
    install -Dm644 midscroll.py $out/libexec/midscroll.py
    install -Dm644 midscroll-overlay.py $out/libexec/midscroll-overlay.py
    install -Dm644 midscroll-settings.py $out/libexec/midscroll-settings.py
    install -Dm644 midscroll-apply.py $out/libexec/midscroll-apply.py
    install -Dm644 midscroll.conf $out/etc/midscroll.conf
    install -Dm644 io.github.gnhen.midscroll.Settings.desktop \
      $out/share/applications/io.github.gnhen.midscroll.Settings.desktop
    install -Dm644 io.github.gnhen.midscroll.policy \
      $out/share/polkit-1/actions/io.github.gnhen.midscroll.policy
    install -Dm644 icons/move-vertical.svg \
      $out/share/midscroll/move-vertical.svg
    install -Dm644 icons/move-vertical.svg \
      $out/share/icons/hicolor/scalable/apps/midscroll.svg
    install -Dm644 systemd/midscroll.service \
      $out/share/doc/midscroll/midscroll.service
    install -Dm644 systemd/midscroll-overlay.service \
      $out/share/doc/midscroll/midscroll-overlay.service

    makeWrapper ${pythonEnv}/bin/python $out/bin/midscroll \
      --add-flags $out/libexec/midscroll.py
    makeWrapper ${pythonEnv}/bin/python $out/bin/midscroll-overlay \
      --add-flags $out/libexec/midscroll-overlay.py \
      --prefix PATH : ${lib.makeBinPath [ kdotool xprop ]}
    makeWrapper ${pythonEnv}/bin/python $out/bin/midscroll-settings \
      --add-flags $out/libexec/midscroll-settings.py \
      --prefix PATH : ${lib.makeBinPath [ polkit systemd ]}
    makeWrapper ${pythonEnv}/bin/python $out/bin/midscroll-apply \
      --add-flags $out/libexec/midscroll-apply.py
  '';

  meta = {
    description = "Windows-style middle-button drag autoscroll for Linux";
    homepage = "https://github.com/gnhen/midscroll";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.linux;
    mainProgram = "midscroll";
  };
}
