{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.sshfs ];

  system.activationScripts.mkMountDirs = ''
    mkdir -p /mnt/beelink1
    chown matheus:users /mnt/beelink1
  '';

  programs.zsh.shellAliases = {
    mount-beelink = "sshfs matheus@100.121.74.52:/ /mnt/beelink1 -o reconnect,ServerAliveInterval=15,IdentityFile=/home/matheus/.ssh/beelink_n1";
    umount-beelink = "fusermount -u /mnt/beelink1";
  };
}
