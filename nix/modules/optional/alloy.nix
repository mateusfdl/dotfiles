{ ... }:
{
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy" = {
    text = ''
      prometheus.exporter.unix "node" {
        set_collectors     = ["cpu", "diskstats", "filesystem", "loadavg", "meminfo", "netdev", "netstat", "sockstat", "stat", "uname", "vmstat", "hwmon", "pressure", "filefd", "conntrack", "textfile"]
        textfile {
          directory = "/var/lib/prometheus-textfile"
        }
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
          {"__address__" = "localhost:41112"},
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
          instance = "beelink-n1",
        }

        endpoint {
          url = "http://localhost:30090/api/v1/write"
        }
      }
    '';
  };
}
