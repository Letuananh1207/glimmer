# PlatformIO pre-script for [env:native]: host gcc defaults to C23, where
# ricmoo/QRCode's `typedef unsigned char bool` no longer compiles. C files only.
Import("env")
env.Append(CFLAGS=["-std=gnu11"])
