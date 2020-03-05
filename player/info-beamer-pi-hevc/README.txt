HEVC support for info-beamer pi
-------------------------------

Extract these files into the directory info-beamer-pi-hevc next to
the info-beamer binary. info-beamer should then automatically pick
then up. Alternatively, place those files anywhere and use
LD_LIBRARY_PATH to point to that directory:

$ LD_LIBRARY_PATH=/path/to/info-beamer-pi-hevc info-beamer /your/code

This is a specially crafted FFmpeg version supporting HEVC on the Pi4.
Source code is available at https://github.com/info-beamer/FFmpeg
