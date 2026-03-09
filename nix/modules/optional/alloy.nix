{ ... }:
{
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy" = {
    text = ''
      prometheus.exporter.unix "node" { }

      prometheus.scrape "node" {
        targets         = prometheus.exporter.unix.node.targets
        forward_to      = [prometheus.remote_write.default.receiver]
        scrape_interval = "15s"
        job_name        = "node"
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
