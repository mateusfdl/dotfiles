{ pkgs, ... }:
let
  textfileDir = "/var/lib/prometheus-textfile";

  conntrackScript = pkgs.writeShellScript "conntrack-textfile" ''
    set -euo pipefail

    OUTPUT="${textfileDir}/conntrack.prom"
    TMP="''${OUTPUT}.tmp"
    CONNTRACK="${pkgs.conntrack-tools}/bin/conntrack"

    {
      echo "# HELP conntrack_entries_by_src Number of conntrack entries per source IP."
      echo "# TYPE conntrack_entries_by_src gauge"
      $CONNTRACK -L -o extended 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '
            match($0, /src=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/, m) {
              count[m[1]]++
            }
            END {
              for (ip in count)
                printf "conntrack_entries_by_src{src=\"%s\"} %d\n", ip, count[ip]
            }
          '

      echo "# HELP conntrack_entries_by_proto Number of conntrack entries per protocol."
      echo "# TYPE conntrack_entries_by_proto gauge"
      $CONNTRACK -L -o extended 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '{count[$1]++} END {for (p in count) printf "conntrack_entries_by_proto{proto=\"%s\"} %d\n", p, count[p]}'

      echo "# HELP conntrack_total_entries Total number of conntrack entries."
      echo "# TYPE conntrack_total_entries gauge"
      TOTAL=$($CONNTRACK -C 2>/dev/null || echo 0)
      echo "conntrack_total_entries $TOTAL"
    } > "$TMP"

    mv "$TMP" "$OUTPUT"
  '';
in
{
  boot.kernelModules = [ "nf_conntrack" ];

  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 root root -"
  ];

  systemd.services.conntrack-textfile = {
    description = "Export conntrack metrics for Prometheus textfile collector";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = conntrackScript;
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
    };
  };

  systemd.timers.conntrack-textfile = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };
}
