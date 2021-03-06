{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "fping-4.0";

  src = fetchurl {
    url = "http://www.fping.org/dist/${name}.tar.gz";
    sha256 = "1kp81wchi79l8z8rrj602fpjrd8bi84y3i7fsaclzlwap5943sv7";
  };

  configureFlags = [ "--enable-ipv6" "--enable-ipv4" ];

  meta = {
    homepage = http://fping.org/;
    description = "Send ICMP echo probes to network hosts";
    maintainers = with stdenv.lib.maintainers; [ the-kenny ];
    platforms = with stdenv.lib.platforms; all;
  };
}
