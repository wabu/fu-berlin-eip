= Video Compression for ViMo L1C Project =

This project implements an fast picture/video compression method,
used to stream a video from the ViMo L1C chip over network.

Camera, video compression and network code are put together to 
stream the video from the xmos board over network.

To show the video, it's received, decompressed and rendered on a normal PC.

Details on the codec can be found in the comments inside "codec/codec.c"

== Project Layout ==

  codec/
  receiver/
  board/
    chksm/
    video/
    compat/
    common/
    test/
    net/
    cam/
  mathlab/
  mk/

The "codec/" directory contains the implementation of the compression method.
The codec code is written to be run both on the xmos board and a normal PC.

The "receiver/" directory contains the app for receiving, decompressing and
rendering the video stream. It uses gl as an rendering backend and relies on
glut for basic application setup.

The "board/" directory contains all the code specific for the xmos board.
The main application is inside the "video/", putting together camera,
compression and network code.

The "mathlab/" directory contains prototypes of the compression methods
written in mathlab.

The "mk/" directory contains Makefile instructions for this project.




== Build ==
We use custom Makefiles to build our project. It was tested inside linux
environments, but should work with some customisation on other systems.

=== Prerequirements ===
You must have installed the Xmos Development tools, a running build-chain for
the host system with the gl and glut libraries installed.

=== Configuration and Customisation ===
Edit the config.mk for your system. 

To change the compression parameters and address of the receiving host, you
have to edit the sources in "board/video/".

=== Compilation and Running it ===
Make sure that you sourced SetEnv from the Xmos Development Tools in your shell.
To compile the project, type xmake/make on the command line.

After the build has finished, you can run the board/video/main.xe on the xmos
chip with xrun and ./receiver/main on the host.


