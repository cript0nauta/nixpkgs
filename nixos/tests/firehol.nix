# Test the firewall module.

import ./make-test-python.nix ({ pkgs, ... }:
  let
    env = with pkgs; [ firehol iptables vim tcpdump ];
    rules = ''
      version 6

      interface4 eth+ lan
        policy reject
        client all accept
        server icmp accept
    '';
  in {

    name = "firehol";
    meta = with pkgs.lib.maintainers; { maintainers = [ eelco ]; };

    nodes = {
      walled = { ... }: {
        networking.firewall.enable = false;
        networking.firehol.enable = true;
        networking.firehol.ruleset = rules;
        services.httpd.enable = true;
        services.httpd.adminAddr = "foo@example.org";
        environment.systemPackages = env;
      };

      # tcpdump firehol iptables vim

      # Dummy configuration to check whether firewall.service will be honored
      # during system activation. This only needs to be different to the
      # original walled configuration so that there is a change in the service
      # file.
      walled2 = { ... }: {
        networking.firewall.enable = false;
        networking.firehol.enable = true;
        networking.firehol.ruleset = rules + ''
          server ftp accept
        '';
        services.httpd.enable = true;
        services.httpd.adminAddr = "foo@example.org";
        environment.systemPackages = env;
      };

      attacker = { ... }: {
        services.httpd.enable = true;
        environment.systemPackages = env;
        services.httpd.adminAddr = "foo@example.org";
        networking.firewall.enable = false;
      };
    };

    testScript = { nodes, ... }:
      let newSystem = nodes.walled2.config.system.build.toplevel;
      in ''
        start_all()

        walled.wait_for_unit("firehol")
        walled.wait_for_unit("httpd")
        attacker.wait_for_unit("network.target")

        # Local connections should still work.
        walled.succeed("curl -v http://localhost/ >&2")

        # Connections to the firewalled machine should fail, but ping should succeed.
        attacker.fail("curl --fail --connect-timeout 2 http://walled/ >&2")
        attacker.succeed("ping -c 1 walled >&2")

        # Outgoing connections/pings should still work.
        walled.succeed("curl -v http://attacker/ >&2")
        walled.succeed("ping -c 1 attacker >&2")

        # If we stop the firewall, then connections should succeed.
        walled.stop_job("firehol")
        attacker.succeed("curl -v http://walled/ >&2")

        # Check whether activation of a new configuration reloads the firewall.
        walled.start_job("firehol")  # TODO check why is necessary
        walled.succeed(
            "${newSystem}/bin/switch-to-configuration test 2>&1 | grep -qF firehol.service"
        )
      '';
  })
