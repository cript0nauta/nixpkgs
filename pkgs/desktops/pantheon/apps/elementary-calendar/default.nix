{ stdenv
, fetchFromGitHub
, pantheon
, pkgconfig
, meson
, ninja
, vala
, desktop-file-utils
, gtk3
, granite
, libgee
, geoclue2
, libchamplain
, clutter
, folks
, geocode-glib
, python3
, libnotify
, libical
, evolution-data-server
, appstream-glib
, elementary-icon-theme
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "elementary-calendar";
  version = "5.0.4";

  repoName = "calendar";

  src = fetchFromGitHub {
    owner = "elementary";
    repo = repoName;
    rev = version;
    sha256 = "0ywk9w6d6nw7ir3f11xc13fr08ifvzpavq1c3x48kmmf69ywprdk";
  };

  passthru = {
    updateScript = pantheon.updateScript {
      attrPath = "pantheon.${pname}";
    };
  };

  nativeBuildInputs = [
    appstream-glib
    desktop-file-utils
    meson
    ninja
    pkgconfig
    python3
    vala
    wrapGAppsHook
  ];

  buildInputs = [
    clutter
    elementary-icon-theme
    evolution-data-server
    folks
    geoclue2
    geocode-glib
    granite
    gtk3
    libchamplain
    libgee
    libical
    libnotify
  ];

  postPatch = ''
    chmod +x meson/post_install.py
    patchShebangs meson/post_install.py
  '';

  meta = with stdenv.lib; {
    description = "Desktop calendar app designed for elementary OS";
    homepage = https://github.com/elementary/calendar;
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = pantheon.maintainers;
  };
}
