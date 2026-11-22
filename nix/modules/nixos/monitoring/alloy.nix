{ config, ... }:
let
  tailscaleDebugAddress = "localhost:41112";
in
{
  services.alloy.enable = true;

  services.tailscale.extraDaemonFlags = [ "--debug=${tailscaleDebugAddress}" ];

  environment.etc."alloy/config.alloy" = {
    text = ''
      prometheus.exporter.unix "node" {
        set_collectors     = ["cpu", "diskstats", "filesystem", "loadavg", "meminfo", "netdev", "netstat", "sockstat", "stat", "uname", "vmstat", "hwmon", "pressure", "filefd", "conntrack", "textfile", "systemd"]
        textfile {
          directory = "/var/lib/prometheus-textfile"
        }
      }

      prometheus.exporter.process "host" {
        matcher {
          name    = "{{.Comm}}"
          cmdline = [".+"]
        }
      }

      prometheus.scrape "process" {
        targets         = prometheus.exporter.process.host.targets
        scrape_interval = "15s"
        forward_to      = [prometheus.relabel.process_job.receiver]
      }

      prometheus.relabel "process_job" {
        rule {
          target_label = "job"
          replacement  = "process"
        }

        forward_to = [prometheus.remote_write.default.receiver]
      }

      prometheus.scrape "node" {
        targets         = prometheus.exporter.unix.node.targets
        scrape_interval = "15s"
        forward_to      = [prometheus.relabel.force_job.receiver]
      }

      prometheus.relabel "force_job" {
        rule {
          target_label = "job"
          replacement  = "node"
        }

        forward_to = [prometheus.remote_write.default.receiver]
      }

      prometheus.scrape "tailscale" {
        targets = [
          {"__address__" = "${tailscaleDebugAddress}"},
        ]
        metrics_path    = "/debug/metrics"
        scrape_interval = "30s"
        forward_to      = [prometheus.relabel.tailscale_job.receiver]
      }

      prometheus.relabel "tailscale_job" {
        rule {
          target_label = "job"
          replacement  = "tailscale"
        }

        forward_to = [prometheus.remote_write.default.receiver]
      }

      prometheus.remote_write "default" {
        external_labels = {
          instance = "${config.networking.hostName}",
        }

        endpoint {
          url = "http://localhost:30090/api/v1/write"
        }
      }
    '';
  };
}
