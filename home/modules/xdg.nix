{
  config,
  hostType,
  dotfilesPath,
  ...
}:

{
  xdg.configFile = {
    "btop".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/btop";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/fastfetch";
    "swaync".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/swaync";
    "themes".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/themes";
    "scripts".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/scripts";
    "foot".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/foot";
    "quickshell".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/quickshell";
    "marktext/preferences.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/marktext/preferences.json";

    # Hyprland configuration
    "hypr/hyprland.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/hyprland.lua";
    "hypr/keybinds.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/keybinds.lua";
    "hypr/.luarc.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/.luarc.json";

    # System-specific modules
    "hypr/modules".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/hypr/${hostType}";
  };
}
