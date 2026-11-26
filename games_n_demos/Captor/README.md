Captor
======

A vertical scrolling shooter in the style of the old WWII arcade games, set
in a futuristic world where sewage is used to create energy. The evil
Trillionaire, Magnus Grasp'em, has kidnapped your sister and holds her
captive in his vast sewage treatment complex. You must set her free.

Fly up the sludge river through four stages of fighters, jets, bombers,
gunboats and gun emplacements, and sink Magnus's dreadnought at the end of
each one.

Controls
--------

* d-pad: fly
* A: fire
* B: evasive roll - you cannot be hit while rolling (three per plane)

Shoot down a whole silver formation of fighters and a worker escapes from the
works: pick him up for more guns and some energy. Enemy shots cost a quarter
of your energy, collisions half of it; a plane is lost when it runs out.

Press A on the title screen to start; left alone, the title runs a demo.

Building
--------

`make` builds `build/captor.bin` (the flash image). `assets/gen-assets.py`
makes the sprite sheet, tile set, map, story pictures and the generated
headers from the images and the Tiled map in `assets/` (it needs Python 3
and Pillow).
