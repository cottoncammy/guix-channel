;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages zig-apps)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages c)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system zig)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:))

(define-public ghostty
  (package
    (name "ghostty")
    (version "1.1.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                     (url "https://github.com/ghostty-org/ghostty")
                     (commit version)))
              (file-name (git-file-name name version))
              (sha256
                (base32 "0glwj88s8jj8vrlc42fzwj4v8yzm01szvnl4mg51qaw5wddk4yk0"))))
    (build-system zig-build-system)
    (native-inputs (list pkg-config blueprint-compiler))
    (inputs (list freetype
                  harfbuzz
                  bzip2
                  fontconfig
                  libpng
                  zlib
                  oniguruma
                  glslang
                  spirv-cross
                  simdutf
                  mesa
                  utfcpp
                  gtk
                  libadwaita
                  libx11
                  wayland
                  wayland-protocols
                  plasma-wayland-protocols
                  gtk-layer-shell))
    (arguments
      `(#:zig zig-0.13
        #:zig-release-type "safe"))
    (home-page "https://ghostty.org")
    (synopsis "A fast, feature-rich, and cross-platform terminal emulator that uses
platform-native UI and GPU acceleration")
    (description "Ghostty is a terminal emulator that differentiates itself by being
fast, feature-rich, and native.")
    (license license:expat)))
