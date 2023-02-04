export PKG_CONFIG_PATH="/opt/homebrew/opt/openblas/lib/pkgconfig"

# Python-Fortran-OpenBlas deps
LDFLAGS="$LDFLAGS -L/opt/homebrew/opt/openblas/lib"
CPPFLAGS="$CPPFLAGS -I/opt/homebrew/opt/openblas/include"
