{ config, username, hostType, dotfilesPath, ... }:

let
  activationPath = config.lib.makeBinPath [
    config.pkgs.bash
    config.pkgs.coreutils
    config.pkgs.git
  ];
in
{
  xdg.configFile = {
    "btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/btop";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/fastfetch";
    "oh-my-posh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/oh-my-posh";
    "swaync".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/swaync";
    "themes".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/themes";
    "wallust".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/wallust";
    "scripts".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/scripts";
    "foot".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/foot";
    "quickshell".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/quickshell";

    # Hyprland configuration
    "hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/hyprland.lua";
    "hypr/keybinds.lua".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/keybinds.lua";
    "hypr/.luarc.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/.luarc.json";

    # System-specific modules
    "hypr/modules".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/${hostType}";
  }; 
}
