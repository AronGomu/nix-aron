{
  lib,
  buildGoModule,
  fetchFromGitHub,
  alsa-lib,
  flac,
  mpg123,
  libvorbis,
  libogg,
  pkg-config,
}:
buildGoModule rec {
  pname = "cliamp";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "bjarneo";
    repo = "cliamp";
    tag = "v${version}";
    hash = "sha256-r7MrrcVt+/f+iPozn9jaczJmpPv431wAoW8LvHKBtB8=";
  };

  vendorHash = "sha256-rtwUWbft5XGEbuBCn0OMCn4TS5Ul+UXJNIqNOzXfU+M=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    alsa-lib
    flac
    mpg123
    libvorbis
    libogg
  ];

  meta = {
    description = "Terminal music player inspired by Winamp";
    homepage = "https://github.com/bjarneo/cliamp";
    license = lib.licenses.mit;
    mainProgram = "cliamp";
  };
}
