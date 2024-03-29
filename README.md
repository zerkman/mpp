# Multi palette picture for Atari ST(e)

This is the official archive of the Multi palette picture (MPP) file format
for Atari ST and STE computers, by Zerkman / Sector One.

The archive consists of source code for generating MPP still images out of
uncompressed 24-bit BMP image files, as well as for viewing such generated
images on an Atari ST or STE. Additional code is also provided to convert MPP
files back into BMP format.

The whole source code is released without any warranty, under the WTFPL
license, version 2 (see included COPYING file). For more information about
this license, see http://www.wtfpl.net/ .

The MPP file format actually supports different kinds of images. It has a
modular-based structure, making the format easily expendable by adding source
or binary plugins into the file viewer.


## Pre-defined image modes

* Mode 0: 320x199, CPU based, displays 54 colors per scanline
with non-uniform repartition of color change positions.
* Mode 1: 320x199, CPU based, displays 48 colors per scanline
with uniform repartition of color change positions.
* Mode 2: 320x199, blitter based (STE only), displays 56 colors per scanline
with uniform repartition of color change positions
* Mode 3: 416x273, CPU based, displays 48+6 colors per scanline
with overscan and non-uniform repartition of color changes.


## The MPP to BMP converter (mpp2bmp)

This is a simple program written in C which enables to convert MPP images into
the popular uncompressed 24-bit image bitmap format. The code is simple
enough to be used as a base for importing MPP images in image editors.


## The BMP to MPP converter (bmp2mpp)

This program is able to accurately convert BMP images into MPP format,
thanks to a metaheuristic method to optimize the palette and pixel data of
the resulting image.

This is a commandline tool, but the code is designed to be easily used in a
graphical application.

The general command line format is :

    ./bmp2mpp [OPTION] file.bmp [OUTPUT]

where OUTPUT is the destination file name. If omitted, the output file name
is the input file name whose extension is changed to .mpp.

Options are:
```
-0                    No optimization
-1                    Optimize faster
-9                    Optimize better (default optimization = 3)
--optimal             Find the optimal solution
--mode=VALUE          Palette and screen mode
                      0: 320x199, 54 colors/scanline, ST/STE (default)
                      1: 320x199, 48 colors/scanline, ST/STE, uniform
                      2: 320x199, 56 colors/scanline, STE
                      3: 416x273, 48+6 colors/scanline, ST/STE, overscan
--st                  Use 9-bit ST palette (default in modes 0, 1, 3)
--ste                 Use 12-bit STE palette (default in mode 2)
--extra               Add extra palette bit (single image)
--double              Add extra palette bit (double image)
--seed=VALUE          Set random seed to VALUE (default=42)
--err                 Display error diagnosis
--raw                 Write raw palette instead of MPP file
```

MPP Header options:
```
--nompph              Do not create MPPH extended header
--title=VALUE         Picture title
--artist=VALUE        Artist name
--ripper=VALUE        Ripper name
--year=VALUE          Year of release
```

Optimization levels from 0 to 9 specify the amount of effort the converter
takes to perform the conversion. As there is no simple and straightforward
way to generate the pixel and palette colors, the converter makes can use of
a simulated annealing-based heuristic to try and find the best combination
of values for the pixels and palette color entries.
At level 0, only a very simple and fast greedy heuristic is used to generate
an initial solution, which in general is of sub-satisfactory quality.
Levels 1 to 9 enable the optimization heuristic to optimize that initial
solution. The solution quality is expressed in terms of "error penalty" by
the encoder. The lower the error level, the better the quality of the
converted image. An error value of 0 would correspond to a conversion result
for which every pixel is assigned the exact required color in the
destination image. In practice, it is generally not the case, but optimized
conversions usually show very little difference between the converted image
and the original one.
The `--optimal` option uses a branch-and-bound search method to find an
optimal solution, ie. a conversion for which there is no possible better
solution in terms of error value. It is more efficient when used in
combination with the optimization heuristic with a high optimization level.
This method may be used for curiosity purposes only, as the heuristic with a
high optimization level already produces solution of similar if not equal
quality.
The encoder also outputs a quality gain ratio, which corresponds to the
error penalty generated for the initial solution (using the greedy heuritic)
divided by the penalty for the optimized solution.

The extra palette bit (`--extra` option) mode must always be combined with STE
mode. This enables palettes of 29791 possible colors. In practice, such
15-bit palettes are converted by the viewer into two alternating 12-bit
palettes which are alternated at each screen refresh.

The double image mode (`--double` option) is an extension of the extra palette
bit mode. In this case, two 12-bit images are generated, so when they are
displayed alternatively, this enables to simulate 29791 possible colors. The
difference is that in the extra palette bit mode specific palette entries
are used for colors with the extra bit set. In the double image mode,
palette entries do encode 12-bit images, expanding the possibility to use
palette entries for more various color shades. The major drawback in this
case is the size of the generated image file, which becomes as large as two
individual 12-bit images.

Other options are for debugging only, or for users who know what they are doing.


## The MPP viewer (MPPVIEW.TTP)

The provided image viewer has been written in 68000 assembly language without
many features. It is basically a proof-of-concept tool, but it still can
be used to view single files (by providing the file name in command line),
or a slide show of all .MPP files in the current directory if no command line
argument is provided, or if the program is renamed to .TOS.

It is designed in a modular way, enabling easy additions of new image
subformats.

The viewer is responsible for displaying the pictures by alternating the
palettes and/or images to simulate extra palette precision, depending on the
encoding of the image files.

Note that on the ST, STE palette mode (12-bit) is treated as a 9-bit palette
mode with an extra bit of precision in each color component. Such images are
displayed by simulating that extra bit with the palette flipping method. STE
images with the extra palette bit (15-bit) are displayed on ST with the
extra bit ignored.


## MPP decoding and displaying library (MPPDEC.S)

This library is useful in user code to decode and display MPP
image files from memory.

The user code must allocate sufficient
memory space for storing the corresponding image(s) and palette
data. Memory space depends on the number of images (and palettes)
in the file, and if a single palette has to be split in two
(extended 15-bit palette on the STe, or STe palette on the ST).


## The MPP file format

An MPP file consists of a 12-byte header providing the image encoding, palette
format and number of images. The header format is the following.

```
3 bytes : the three "MPP" ASCII characters
1 byte  : pre-defined image mode (possible values: 0-3, other values reserved)
1 byte  : flags
  bit 0: STE palette       (12-bit, otherwise 9-bit)
  bit 1: extra palette bit (only in STE palette, extends the palette to 15-bit)
  bit 2: double image      (required on very colorful images)
  bits 3-7: reserved, currently always zero.
3 bytes : reserved, currently always zero.
4 bytes : extra_len : length of extra header data.
```

If `extra_len` is different from zero, then a block of `extra_len` bytes follows.
The `extra_len` value must be an even number.

Then follows the palette data. The length of this block depends on the image
mode and flags. Its value (in bits) is the number of bits per palette entry
multiplied by the total number of palette entries. The resulting value is
rounded to the smallest multiple of 16 not less than it. To get the size in
bytes you must divide the computed value by 8. Note that because of the
rounding to a multiple of 16 bits, the palette size in bytes is always a
multiple of 2.

Finally, comes the image data. It corresponds to unpacked bitplanes of the
image. The size of the image in bytes is the image width rounded to the
closest higher or equal multiple of 16, multiplied by the image height, and
divided by two.

In the case of double image mode, follows a second palette and image pair.


### The MPP extra header information

If the `extra_len` header value is not zero, then a MPPH block follows. It
is very similar to what the SNDH header information is for Atari SND files.
It consists of the four `MPPH` characters, a list of tag/value pairs, and a
final even-aligned `HPPM` four-character string.

Below follows the list of the different supported tags.
The order of the tags is not important.

```
;------------------------------------------------------------------------------
; TAG   Description      Example                                    Termination
;------------------------------------------------------------------------------
; TITL  Title of Picture dc.b 'TITL','The Persistence of Memory',0  0 (Null)
; ARTT  Artist Name      dc.b 'ARTT','Salvador Dali',0              0 (Null)
; RIPP  Ripper Name      dc.b 'RIPP','Me the hacker',0              0 (Null)
; CONV  Converter Name   dc.b 'CONV','Me the converter',0           0 (Null)
; YEAR  Year of release  dc.b '1931',0                              0 (Null)
; HPPM  End of Header    dc.b 'HPPM'                                None
;                                                 Must be on an EVEN boundary
```
