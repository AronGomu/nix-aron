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
          {
            name = "Scryfall";
            url = "https://scryfall.com/";
          }
          {
            name = "ASCENCIO - Duel Simulator";
            url = "http://localhost:4300/";
          }
          {
            name = "ASCENCIO - Deckbuilder";
            url = "http://localhost:4301/";
          }
          {
            name = "ASCENCIO - VN";
            url = "http://localhost:4302/";
          }
          {
            name = "Siinergy ERP";
            url = "http://erpcloud.siinergy.net/";
          }
          {
            name = "Outlook";
            url = "https://outlook.live.com/mail/";
          }
          {
            name = "Discord";
            url = "https://discord.com/channels/@me";
          }
          {
            name = "Messenger";
            url = "https://www.facebook.com/messages/e2ee/t/8160697540693740/#";
          }
          {
            name = "Facebook";
            url = "https://facebook.com/";
          }
          {
            name = "Instagram";
            url = "https://www.instagram.com/";
          }
          {
            name = "X";
            url = "https://x.com/";
          }
          {
            name = "MTGTop8 - Legacy";
            url = "https://mtgtop8.com/format?f=LE";
          }
          {
            name = "Maps";
            url = "https://www.google.com/maps";
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
        ];
      }
    ];
  };
in
{
  environment.etc."brave/policies/managed/managed-bookmarks.json".text =
    builtins.toJSON managedBookmarks;
}
