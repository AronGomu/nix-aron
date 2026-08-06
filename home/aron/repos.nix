{ lib, pkgs, ... }:
let
  # Single source of truth for every repo checked out on this machine.
  # `dir` is relative to $HOME; `name` is the local directory name (may differ
  # from the GitHub repo name — e.g. ascencio -> ygo-story-duel-simulator).
  repos = [
    {
      name = "nix-aron";
      dir = "config";
      url = "git@github.com:AronGomu/nix-aron.git";
    }
    {
      name = "ascencio";
      dir = "projects";
      url = "git@github.com:AronGomu/ygo-story-duel-simulator.git";
    }
    {
      name = "essentia";
      dir = "projects";
      url = "git@github.com:AronGomu/YGO-x-MTG.git";
    }
    {
      name = "gones";
      dir = "projects";
      url = "git@github.com:AronGomu/gones.git";
    }
    {
      name = "millions_must_die";
      dir = "projects";
      url = "git@github.com:AronGomu/millions-must-die.git";
    }
  ];

  # Directories that must exist even when no repo is cloned into them yet
  # (e.g. ~/config/bookmarks is a local-only repo with no remote).
  repoRoots = lib.unique ([ "config" "projects" ] ++ map (r: r.dir) repos);

  cloneLines = lib.concatMapStringsSep "\n" (r: ''
    clone_repo "${r.dir}" "${r.name}" "${r.url}"
  '') repos;

  clone-repos = pkgs.writeShellApplication {
    name = "clone-repos";
    runtimeInputs = [ pkgs.git ];
    text = ''
      # Clone every declared repo that is not already present.
      # Idempotent: existing checkouts are left untouched (never overwritten).
      # Usage: clone-repos [--https]   (--https avoids needing an SSH key)
      use_https=0
      if [ "''${1:-}" = "--https" ]; then
        use_https=1
      fi

      clone_repo() {
        dir="$1"
        name="$2"
        url="$3"
        target="$HOME/$dir/$name"

        if [ "$use_https" = "1" ]; then
          url="''${url/git@github.com:/https://github.com/}"
        fi

        if [ -e "$target/.git" ]; then
          echo "skip   $dir/$name (already cloned)"
          return 0
        fi
        if [ -e "$target" ]; then
          echo "SKIP   $dir/$name exists but is not a git repo — leaving alone" >&2
          return 0
        fi

        echo "clone  $dir/$name <- $url"
        mkdir -p "$HOME/$dir"
        git clone "$url" "$target"
      }

      ${cloneLines}

      echo "done."
    '';
  };
in
{
  home.packages = [ clone-repos ];

  # Create the repo roots on activation so a fresh system has them immediately,
  # before `clone-repos` is ever run.
  home.activation.createRepoRoots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.concatMapStringsSep " " (d: "\"$HOME/${d}\"") repoRoots}
  '';
}
