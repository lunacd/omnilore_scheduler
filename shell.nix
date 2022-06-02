{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/a634c8f6c1fbf9b9730e01764999666f3436f10a.tar.gz") {}
}:

with pkgs;
mkShell {
  buildInputs = [
    flutter
    dart
    unzip
    cmake
    ninja
    clang
    pkg-config
    gtk3
    pcre
    libepoxy
    mount
    gnome.zenity
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${libepoxy}/lib
  '';
}

