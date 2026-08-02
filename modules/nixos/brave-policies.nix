# Brave enterprise policies (system). Managed bookmarks = read-only folder in browser.
{ lib, ... }:
let
  managedBookmarks = {
    ManagedBookmarks = [
      { toplevel_name = "Nix"; }
      {
        name = "Daily";
        children = [
          {
            name = "YouTube";
            url = "https://www.youtube.com/";
          }
          {
            name = "YouTube Music";
            url = "https://music.youtube.com/";
          }
          {
            name = "LinkedIn";
            url = "https://www.linkedin.com/feed/";
          }
          {
            name = "Canva";
            url = "https://www.canva.com/";
          }
        ];
      }
      {
        name = "GitHub";
        children = [
          {
            name = "AronGomu repos";
            url = "https://github.com/AronGomu?tab=repositories";
          }
          {
            name = "nix-aron";
            url = "https://github.com/AronGomu/nix-aron";
          }
          {
            name = "brain";
            url = "https://github.com/AronGomu/brain";
          }
          {
            name = "gones";
            url = "https://github.com/AronGomu/gones";
          }
          {
            name = "ygo-story-duel-simulator";
            url = "https://github.com/AronGomu/ygo-story-duel-simulator";
          }
        ];
      }
      {
        name = "Local";
        children = [
          {
            name = "Gones :4200";
            url = "http://localhost:4200";
          }
          {
            name = "Essentia :4201";
            url = "http://localhost:4201";
          }
          {
            name = "Ascensio :4202";
            url = "http://localhost:4202";
          }
        ];
      }
    ];
  };
in
{
  environment.etc."brave/policies/managed/managed-bookmarks.json".text =
    builtins.toJSON managedBookmarks;
}
