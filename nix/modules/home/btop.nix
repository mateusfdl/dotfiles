{ ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = false;
      force_tty = true;
      vim_keys = true;
      graph_symbol = "tty";
      proc_sorting = "user";
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      base_10_sizes = true;
      show_disks = false;
      show_battery = false;
      shown_gpus = "nvidia amd intel";
      save_config_on_exit = false;
    };
  };
}
