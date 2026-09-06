{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule (finalAttrs: {
  pname = "gum";
  version = "0.17.0";

  src = pkgs.fetchFromGitHub {
    owner = "charmbracelet";
    repo = "gum";
    rev = "v${finalAttrs.version}";
    hash = "sha256-TbheGevUrUKwT97JayW7rfAEgAfRnpOvHyvAxt27sIg=";
  };

  vendorHash = "sha256-9vHlQuJA5g5sonfxe+whXDdkROuE3lZzOPYq74tJZtE="; 

  nativeBuildInputs = [
    pkgs.installShellFiles
  ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${finalAttrs.version}"
  ] ++ pkgs.lib.optionals (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isStatic) [
    "-linkmode=external"
    "-extldflags"
    "-static"
  ];

  postInstall = pkgs.lib.optionalString (pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform) ''
    $out/bin/gum man > gum.1
    installManPage gum.1
    installShellCompletion --cmd gum \
      --bash <($out/bin/gum completion bash) \
      --fish <($out/bin/gum completion fish) \
      --zsh <($out/bin/gum completion zsh)
  '';

  meta = {
    description = "Tasty Bubble Gum for your shell";
    homepage = "https://github.com/charmbracelet/gum";
    changelog = "https://github.com/charmbracelet/gum/releases/tag/v${finalAttrs.version}";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [
      savtrip
    ];
    mainProgram = "gum";
  };
})
