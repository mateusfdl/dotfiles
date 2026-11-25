{
  config,
  pkgs,
  username,
  ...
}:
let
  user = config.users.users.${username};
  mountPoint = "/mnt/beelink1";
in
{
  environment.systemPackages = [ pkgs.sshfs ];

  system.activationScripts.mkMountDirs = ''
    if ${pkgs.gnugrep}/bin/grep -q ' ${mountPoint} ' /proc/mounts 2>/dev/null; then
      ${pkgs.util-linux}/bin/umount -l ${mountPoint} 2>/dev/null || true
    fi
    mkdir -p ${mountPoint}
    chown ${user.name}:${user.group} ${mountPoint}
  '';

  programs.zsh.shellAliases = {
    mount-beelink = "sshfs matheus@100.121.74.52:/ ${mountPoint} -o reconnect,ServerAliveInterval=15,IdentityFile=${user.home}/.ssh/beelink_n1";
    umount-beelink = "fusermount -u ${mountPoint}";
  };
}
