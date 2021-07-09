{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.networking.firehol;

  rulesFile = pkgs.writeTextFile {
    name = "firehol.conf";
    text = cfg.ruleset;
  };

in {

  options = {
    networking.firehol.enable = mkOption {
      type = types.bool;
      default = false;
    };

    networking.firehol.ruleset = mkOption { type = types.lines; };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = config.networking.firewall.enable == false;
      message = "either firehol or iptables";
    }];

    environment.systemPackages = [ pkgs.iptables pkgs.firehol ];
    environment.etc."firehol/firehol.conf".source = rulesFile;

    systemd.services.firehol = {
      before = [ "network-pre.target" ];
      wants = [ "network-pre.target" ];
      wantedBy = [ "network-pre.target" ];
      reloadIfChanged = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.firehol}/bin/firehol ${rulesFile} start";
        ExecStop = "${pkgs.firehol}/bin/firehol stop";
      };
    };

  };

}

