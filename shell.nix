{ pkgs ? import <nixpkgs> { }, ... }:
pkgs.mkShell rec {
  nativeBuildInputs = with pkgs; [ zfs ] ++ [ go golangci-lint gopls ];

  CGO_CFLAGS = "-I${pkgs.zfs.dev}/include/libzfs -I${pkgs.zfs.dev}/include/libspl";
  CGO_LDFLAGS = "-L${pkgs.zfs.out}/lib";
}
