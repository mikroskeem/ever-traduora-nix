{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.traduora;
in
{
  options = {
    services.traduora = {
      enable = mkEnableOption "Traduora";
      enableSignups = mkEnableOption "Sign ups";

      listenPort = mkOption {
        type = types.int;
        default = 8080;
        description = "Listen port";
      };

      virtualHost = mkOption {
        type = types.str;
        default = "http://localhost:8080";
        description = "Virtual host";
      };
    };
  };

  config = {
    systemd.services.traduora-api = mkIf cfg.enable {
      description = "Traduora API server";
      serviceConfig = {
        Restart = "always";
        ExecStart = "${pkgs.traduora}/bin/traduora-api";
      };

      # TODO: expose
      environment = {
        TR_ACCESS_LOGS_ENABLED = "true";
        TR_CORS_ENABLED = "true";
        TR_PORT = "${toString cfg.listenPort}";

        TR_AUTH_TOKEN_EXPIRES = "86400";
        TR_MAX_PROJECTS_PER_USER = "100";
        TR_SIGNUPS_ENABLED = "true";

        TR_DB_AUTOMIGRATE = "true";
        TR_DB_DATABASE = "traduora";
        TR_DB_HOST = "127.0.0.1";
        TR_DB_PASSWORD = "password";
        TR_DB_USER = "root";

        TR_MAIL_DEBUG = "false";
        TR_MAIL_PASSWORD = "587";
        TR_MAIL_PORT = "587";
        TR_MAIL_REJECT_SELF_SIGNED = "false";
        TR_MAIL_SECURE = "true";
        TR_MAIL_SENDER = "noreply@domain.tld";
        TR_MAIL_USER = "587";
      };

      after = [ "network.target" "mysql.service" ];
      requires = [ "mysql.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
