{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8b3398bc7587ebb79f93dfeea1b8c574d3c6dba1.tar.gz") {}
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.flutter
    pkgs.dart
  ];
}

