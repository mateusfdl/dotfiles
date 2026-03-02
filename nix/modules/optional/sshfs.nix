{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.sshfs ];

  system.activationScripts.mkMountDirs = ''
    # check /proc/mounts directly to avoid stat() on a stale fuse
    # mountpoint (which would hang or error).
    if ${pkgs.gnugrep}/bin/grep -q ' /mnt/beelink1 ' /proc/mounts 2>/dev/null; then
      ${pkgs.util-linux}/bin/umount -l /mnt/beelink1 2>/dev/null || true
    fi
    mkdir -p /mnt/beelink1
    chown matheus:users /mnt/beelink1
  '';

  programs.zsh.shellAliases = {
    mount-beelink = "sshfs matheus@100.121.74.52:/ /mnt/beelink1 -o reconnect,ServerAliveInterval=15,IdentityFile=/home/matheus/.ssh/beelink_n1";
    umount-beelink = "fusermount -u /mnt/beelink1";
  };
}
