{ ... }:
{
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy" = {
    text = ''
      prometheus.exporter.unix "node" { }

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
