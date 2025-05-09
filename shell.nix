{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "sandboxy-dev";
  buildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    
    # Core dependencies
    irrlicht
    libpng
    libjpeg
    libGLU
    openal
    openalSoft
    sqlite
    
    # Optional dependencies
    curl
    freetype
    gettext
    gmp
    jsoncpp
    leveldb
    libogg
    libvorbis
    luajit
    postgresql
    redis
    zlib
    zstd
    
    # Development tools
    gdb
    valgrind
    clang-tools
  ];

  shellHook = ''
    export SANDBOXY_USER_PATH="$HOME/.local/share/sandboxy"
    export SANDBOXY_SHARE_PATH="/usr/share/sandboxy"
    
    # Configure paths for development
    if [ ! -d build ]; then
      mkdir build
      cd build
      cmake -G Ninja .. \
        -DRUN_IN_PLACE=1 \
        -DENABLE_GETTEXT=1 \
        -DENABLE_SYSTEM_GMP=1 \
        -DENABLE_SYSTEM_JSONCPP=1
      cd ..
    fi
  '';
}
