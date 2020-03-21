{ version, sha256 }:

{ stdenv, buildPackages, fetchurl, perl, xz

# we are a dependency of gcc, this simplifies bootstraping
, interactive ? false, ncurses, procps
}:

let
  crossBuildTools = interactive && stdenv.hostPlatform != stdenv.buildPlatform;
in

with stdenv.lib;

stdenv.mkDerivation {
  name = "texinfo-${optionalString interactive "interactive-"}${version}";
  inherit version;

  src = fetchurl {
    url = "mirror://gnu/texinfo/texinfo-${version}.tar.xz";
    inherit sha256;
  };

  patches = optional (version == "6.5") ./perl.patch
    ++ optional crossBuildTools ./cross-tools-flags.patch;

  # ncurses is required to build `makedoc'
  # this feature is introduced by the ./cross-tools-flags.patch
  NATIVE_TOOLS_CFLAGS = if crossBuildTools then "-I${getDev buildPackages.ncurses}/include" else null;
  NATIVE_TOOLS_LDFLAGS = if crossBuildTools then "-L${getLib buildPackages.ncurses}/lib" else null;

  # We need a native compiler to build perl XS extensions
  # when cross-compiling.
  depsBuildBuild = [ buildPackages.stdenv.cc perl ];

  buildInputs = [ xz.bin ]
    ++ optionals stdenv.isSunOS [ libiconv gawk ]
    ++ optional interactive ncurses;

  configureFlags = [ "PERL=${buildPackages.perl}/bin/perl" ]
    ++ stdenv.lib.optional stdenv.isSunOS "AWK=${gawk}/bin/awk";

  installFlags = [ "TEXMF=$(out)/texmf-dist" ];
  installTargets = [ "install" "install-tex" ];

  checkInputs = [ procps ];

  doCheck = interactive
    && !stdenv.isDarwin
    && !stdenv.isSunOS; # flaky

  meta = {
    homepage = https://www.gnu.org/software/texinfo/;
    description = "The GNU documentation system";
    license = licenses.gpl3Plus;
    platforms = platforms.all;
    maintainers = with maintainers; [ vrthra oxij ];

    longDescription = ''
      Texinfo is the official documentation format of the GNU project.
      It was invented by Richard Stallman and Bob Chassell many years
      ago, loosely based on Brian Reid's Scribe and other formatting
      languages of the time.  It is used by many non-GNU projects as
      well.

      Texinfo uses a single source file to produce output in a number
      of formats, both online and printed (dvi, html, info, pdf, xml,
      etc.).  This means that instead of writing different documents
      for online information and another for a printed manual, you
      need write only one document.  And when the work is revised, you
      need revise only that one document.  The Texinfo system is
      well-integrated with GNU Emacs.
    '';
    branch = version;
  };
}
