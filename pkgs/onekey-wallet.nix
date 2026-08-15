{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "onekey-wallet";
  version = "6.5.0";
  src = fetchurl {
    url = "https://github.com/OneKeyHQ/app-monorepo/releases/download/v${version}/OneKey-Wallet-${version}-linux-x86_64.AppImage";
    # Matches the SHA256SUMS.asc published alongside the release.
    hash = "sha256-pxbzIAFQjWSOtj/isoUBm141jS3Ec7zUaWTKWRKoeVE=";
  };
  contents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${contents}/${pname}.desktop $out/share/applications/${pname}.desktop
    install -m 444 -D ${contents}/${pname}.png \
      $out/share/icons/hicolor/512x512/apps/${pname}.png
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
  '';

  meta = {
    description = "OneKey crypto wallet desktop app";
    homepage = "https://onekey.so";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
