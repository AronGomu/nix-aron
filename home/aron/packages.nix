{
  pkgs,
  pkgsUnstable,
  ...
}:
let
  davinciResolve = pkgs.symlinkJoin {
    name = "davinci-resolve-wrapped";
    paths = [ pkgsUnstable.davinci-resolve ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/davinci-resolve \
        --unset QT_PLUGIN_PATH \
        --unset QT_STYLE_OVERRIDE \
        --unset QT_QPA_PLATFORMTHEME
    '';
  };
  herdr = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = "0.7.5";
    src = pkgs.fetchurl {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v0.7.5/herdr-linux-x86_64";
      hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/herdr
    '';
  };
  openwhispr = pkgs.appimageTools.wrapType2 rec {
    pname = "openwhispr";
    version = "1.7.6";
    src = pkgs.fetchurl {
      url = "https://github.com/OpenWhispr/openwhispr/releases/download/v${version}/OpenWhispr-${version}-linux-x86_64.AppImage";
      hash = "sha256-8c1bE3ZfJTb0ZXQb3mRAfj7QtMoUkaby8N3133Gg3z4=";
    };
    extraInstallCommands =
      let
        contents = pkgs.appimageTools.extractType2 { inherit pname version src; };
      in
      ''
        install -m 444 -D ${contents}/open-whispr.desktop $out/share/applications/open-whispr.desktop
        install -m 444 -D ${contents}/open-whispr.png $out/share/icons/hicolor/512x512/apps/open-whispr.png
        substituteInPlace $out/share/applications/open-whispr.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=openwhispr'
      '';
  };
in
{
  home.packages =
    with pkgs;
    [
      # Daily desktop
      copyq
      evince
      ffmpeg-full
      file-roller
      flameshot
      mediainfo
      mpv
      p7zip
      pavucontrol
      strawberry
      thunderbird
      unrar

      # Development
      bat
      btop
      cargo
      curl
      direnv
      eza
      fd
      fzf
      gcc
      gh
      git
      gnumake
      go
      htop
      jq
      lazygit
      neovim
      nodejs_24
      python3
      ripgrep
      rustc
      tree
      tree-sitter
      unzip
      uv
      wget
      xclip
      xsel
      yq-go
      zip
      zoxide
      home-manager
      davinciResolve
      herdr
      openwhispr
    ]
    ++ (with pkgsUnstable; [
      brave
      codex
      ghostty
      obs-studio
      pi-coding-agent
    ]);
}
