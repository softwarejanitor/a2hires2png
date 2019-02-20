#!/usr/bin/perl -w

#
# a2hires2png.pl
#
# Convert Apple II HIRES grqphic image to a PNG image.
#
# 20190220 Leeland Heins
#

use strict;

use GD;

sub HIGH {
  my ($bytes, $min, $x) = @_;

  return ($bytes->[$min + ($x) / 7] & (1 << 7))
}

sub process {
  my ($ifh) = @_;

  # Create a new image.
  my $im = new GD::Image(280, 192);

  # Allocate Apple II hires colors
  my $black = $im->colorAllocate(0x00, 0x00, 0x00);
  my $white = $im->colorAllocate(0xff, 0xff, 0xff);
  my $green = $im->colorAllocate(0x14, 0xfe, 0x3c);
  my $violet = $im->colorAllocate(0xff, 0x44, 0xfd);
  my $orange = $im->colorAllocate(0xff, 0x6a, 0x3c);
  my $blue = $im->colorAllocate(0x14, 0xcf, 0xfd);

  # Fill the image black
  $im->filledRectangle(0, 0, 279, 191, $black);

  my $maj = 0;
  my $min = 0;
  my $color = 0;

  my @lines = (
    0x000,
    0x080,
    0x100,
    0x180,
    0x200,
    0x280,
    0x300,
    0x380,
    0x028,
    0x0a8,
    0x128,
    0x1a8,
    0x228,
    0x2a8,
    0x328,
    0x3a8,
    0x050,
    0x0d0,
    0x150,
    0x1d0,
    0x250,
    0x2d0,
    0x350,
    0x3d0
  );

  my $buf;

  # Read the Apple II hires data.
  read ($ifh, $buf, 8192);

  # Unpack it into bytes.
  my @bytes = unpack "C*", $buf;

  # Determine if this is a color or monochrome image.
  for ($maj = 0; $maj < 24; $maj++) {
    for ($min = $lines[$maj]; $min < $lines[$maj] + 8192; $min += 1024) {
      my $x;

      for ($x = 0; $x < 40; $x++) {
        if (($bytes[$min + $x] & 0x80) &&
            ($bytes[$min + $x] != 0xff) &&
            ($bytes[$min + $x] != 0x80)) {
          $color = 1;
          last;
        }
      }
    }
  }

  my $y = 0;

  for ($maj = 0; $maj < 24; $maj++) {
    for ($min = $lines[$maj]; $min < $lines[$maj] + 8192; $min += 1024) {
      $y++;
      my $x;
      my @bits;  # 280

      for ($x = 0; $x < 280; $x++) {
        $bits[$x] = ($bytes[$min + $x / 7] & (1 << ($x % 7))) != 0;
      }

      $x = 0;

      # Left edge
      if ($color && ($bits[0] != $bits[1])) {
        if (HIGH(\@bytes, $min, 0)) {
          if ($bits[0]) {
            # Draw blue pixel
            $im->setPixel($x, $y, $blue);
          } else {
            # Draw orange pixel
            $im->setPixel($x, $y, $orange);
          }
        } else {
          if ($bits[0]) {
            # Draw violet pixel
            $im->setPixel($x, $y, $violet);
          } else {
            # Draw green pixel
            $im->setPixel($x, $y, $green);
          }
        }
      } else {
        if ($bits[0]) {
          # Draw white pixel
          $im->setPixel($x, $y, $white);
        } else {
          # Draw black pixel
          $im->setPixel($x, $y, $black);
        }
      }

      # Middle
      for ($x = 1; $x < 279; $x++) {
        if ($color &&
            $bits[$x] != $bits[$x - 1] &&
            $bits[$x] != $bits[$x + 1]) {
          if ($x % 2 == 0) {
            if (HIGH(\@bytes, $min, $x)) {
              if ($bits[$x]) {
                # Draw blue pixel
                $im->setPixel($x, $y, $blue);
              } else {
                # Draw orange pixel
                $im->setPixel($x, $y, $orange);
              }
            } else {
              if ($bits[$x]) {
                # Draw violet pixel
                $im->setPixel($x, $y, $violet);
              } else {
                # Draw green pixel
                $im->setPixel($x, $y, $green);
              }
            }
          } else {
            if (HIGH(\@bytes, $min, $x)) {
              if ($bits[$x]) {
                # Draw orange pixel
                $im->setPixel($x, $y, $orange);
              } else {
                # Draw blue pixel
                $im->setPixel($x, $y, $blue);
              }
            } else {
              if ($bits[$x]) {
                # Draw green pixel
                $im->setPixel($x, $y, $green);
              } else {
                # Draw violet pixel
                $im->setPixel($x, $y, $violet);
              }
            }
          }
        } else {
          if ($bits[$x]) {
            # Draw white pixel
            $im->setPixel($x, $y, $white);
          } else {
            # Draw black pixel
            $im->setPixel($x, $y, $black);
          }
        }
      }

      $x = 279;

      # Right edge
      if ($color && ($bits[278] != $bits[279])) {
        if (HIGH(\@bytes, $min, 279)) {
          if ($bits[279]) {
            # Draw orange pixel
            $im->setPixel($x, $y, $orange);
          } else {
            # Draw blue pixel
            $im->setPixel($x, $y, $blue);
          }
        } else {
          if ($bits[279]) {
            # Draw green pixel
            $im->setPixel($x, $y, $green);
          } else {
            # Draw violet pixel
            $im->setPixel($x, $y, $violet);
          }
        }
      } else {
        if ($bits[279]) {
          # Draw white pixel
          $im->setPixel($x, $y, $white);
        } else {
          # Draw black pixel
          $im->setPixel($x, $y, $black);
        }
      }
    }
  }

  return $im;
}

my $filename = shift or die "Must supply filename\n";

my $ifh;

if (open($ifh, "<$filename")) {
  my $im = process($ifh);

  # make sure we are writing to a binary stream
  binmode STDOUT;
 
  # Convert the image to PNG and print it on standard output
  print $im->png;
} else {
  die "Unable to read $filename\n";
}

1;

