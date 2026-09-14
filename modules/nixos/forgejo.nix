{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.tea ];

  services.forgejo = {
    enable = true;
    settings = {
      server = {
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        DOMAIN = "localhost";
        ROOT_URL = "http://localhost:3000/";
        DISABLE_SSH = true;
      };
      service.DISABLE_REGISTRATION = true;
    };
  };
}
