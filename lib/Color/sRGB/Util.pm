package Color::sRGB::Util;
use warnings;
use strict;
use v5.10.0;

use base 'Exporter';

our @EXPORT_OK;
our %EXPORT_TAGS;
BEGIN {
    my @subs = (
                'clamp',
                'clampRGB',
                'rgb2hsl',
                'hsl2rgb',
                'rgb2hsv',
                'hsv2rgb',
                'rgb2hsp',
                'hsp2rgb',
                'luma',
                'luminance',
                'hspBrightness',
                'gammaCompress',
                'gammaExpand',
                'ncmp',
                'hmod',
                'nlt',
                'ngt',
                'neq',
                'nne',
                'nle',
                'nge'
               );
    my @vars = (
                '$COEFFICIENTS_TYPE',
               );
    @EXPORT_OK = (@subs, @vars);
    %EXPORT_TAGS = (
                    'all' => [@subs, @vars],
                    'subs' => [@subs],
                    'vars' => [@vars],
                   );
}

use Scalar::Util qw(looks_like_number);
use List::Util qw(min max);
use Data::Dumper qw(Dumper);

our $COEFFICIENTS;
our $COEFFICIENTS_TYPE;
BEGIN {
    $COEFFICIENTS = {
                     bt709     => [ 0.2126, 0.7152, 0.0722 ], # ITU-R Recommendation BT.709, used for sRGB
                     srgb      => [ 0.2126, 0.7152, 0.0722 ],
                     sRGB      => [ 0.2126, 0.7152, 0.0722 ],
                     bt601     => [ 0.299,  0.587,  0.114  ], # ITU-R Recommendation BT.601 (used for JPG)
                     jpg       => [ 0.299,  0.587,  0.114  ],
                     JPG       => [ 0.299,  0.587,  0.114  ],
                     bt2020    => [ 0.2627, 0.6780, 0.0593 ], # ITU-R Recommendation BT.2020
                     smpte240m => [ 0.212,  0.701,  0.087  ], # SMPTE 240M (transitional 1035i HDTV)
                     hsp       => [ 0.299,  0.587,  0.114  ], # http://alienryderflex.com/hsp.html
                     hsp2      => [ 0.241,  0.691,  0.068  ], # http://alienryderflex.com/hsp.html
                    };
}

use constant R => 0;
use constant G => 1;
use constant B => 2;

sub clamp {
    my ($a, $b, $c) = @_;
    if (!defined $b && !defined $c) {
        $b = 0.0;
        $c = 1.0;
    }
    if (!defined $a || !looks_like_number($a) ||
        !defined $b || !looks_like_number($b) ||
        !defined $c || !looks_like_number($c) || $b > $c) {
        die(sprintf("clamp: invalid arguments: %s", Dumper(\@_)));
    }
    return $b if $a < $b;
    return $c if $a > $c;
    return $a;
}

sub clampRGB {
    my ($r, $g, $b) = @_;
    if ($r <= 1 && $g <= 1 && $b <= 1) {
        return ($r, $g, $b);
    }
    ($r, $g, $b) = map { gammaExpand($_) } ($r, $g, $b);
    my $max = max($r, $g, $b);
    if ($max > 1) {
        $r /= $max;
        $g /= $max;
        $b /= $max;
    }
    ($r, $g, $b) = map { gammaCompress($_) } ($r, $g, $b);
    return ($r, $g, $b);
}

#------------------------------------------------------------------------------
# HSV and HSL conversion
#------------------------------------------------------------------------------

sub rgb2hsl {
    my ($r, $g, $b) = @_;
    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);
    my $max = max($r, $g, $b);
    my $min = min($r, $g, $b);
    my $c = $max - $min;
    my $l = ($min + $max) / 2;
    if ($c == 0) {         # achromatic
        return (0, 0, $l);
    }
    my $s = ($l > 0.5) ? ($c / (2 - $max - $min)) : ($c / ($max + $min));
    my $h;
    if ($max == $r) {
        $h = ($g - $b) / $c + ($g < $b ? 6 : 0);
    } elsif ($max == $g) {
        $h = ($b - $r) / $c + 2;
    } elsif ($max == $b) {
        $h = ($r - $g) / $c + 4;
    }
    $h /= 6;
    $s = clamp($s);
    $l = clamp($l);
    return ($h, $s, $l);
}

sub hue2rgb {
    my ($p, $q, $t) = @_;
    if ($t < 0) {
        $t += 1;
    }
    if ($t > 1) {
        $t -= 1;
    }
    if ($t < 1/6) {
        return $p + ($q - $p) * 6 * $t;
    }
    if ($t < 1/2) {
        return $q;
    }
    if ($t < 2/3) {
        return $p + ($q - $p) * (2/3 - $t) * 6;
    }
    $p = hmod($p);
    return $p;
}

sub hsl2rgb {
    my ($h, $s, $l) = @_;
    $h += 1 while $h < 0;
    $h -= 1 while $h >= 1;
    $s = clamp($s);
    $l = clamp($l);
    my ($r, $g, $b);
    if ($s == 0) {
        $r = $g = $b = $l;      # achromatic
    } else {
        my $q = $l < 0.5 ? $l * (1 + $s) : $l + $s - $l * $s;
        my $p = 2 * $l - $q;
        $r = hue2rgb($p, $q, $h + 1/3);
        $g = hue2rgb($p, $q, $h);
        $b = hue2rgb($p, $q, $h - 1/3);
    }
    ($r, $g, $b) = clampRGB($r, $g, $b);
    return ($r, $g, $b);
}

sub rgb2hsv {
    my ($r, $g, $b) = @_;
    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);
    my $max = max($r, $g, $b);
    my $min = min($r, $g, $b);
    my $c = $max - $min;
    my $v = $max;
    if ($c == 0) {              # achromatic
        return (0, 0, $v);
    }
    my $s = ($max == 0) ? 0 : $c / $max;
    my $h;
    if ($max == $r) {
        $h = ($g - $b) / $c + ($g < $b ? 6 : 0);
    } elsif ($max == $g) {
        $h = ($b - $r) / $c + 2;
    } elsif ($max == $b) {
        $h = ($r - $g) / $c + 4;
    }
    $h /= 6;
    $s = clamp($s);
    $v = clamp($v);
    return ($h, $s, $v);
}

use POSIX qw(floor);

sub hsv2rgb {
    my ($h, $s, $v) = @_;
    $h += 1 while $h < 0;
    $h -= 1 while $h >= 1;
    $s = clamp($s);
    $v = clamp($v);
    my ($r, $g, $b);
    my $i = floor($h * 6);
    my $f = $h * 6 - $i;
    my $p = $v * (1 - $s);
    my $q = $v * (1 - $f * $s);
    my $t = $v * (1 - (1 - $f) * $s);
    if ($i == 0) {
        $r = $v; $g = $t; $b = $p;
    } elsif ($i == 1) {
        $r = $q; $g = $v; $b = $p;
    } elsif ($i == 2) {
        $r = $p; $g = $v; $b = $t;
    } elsif ($i == 3) {
        $r = $p; $g = $q; $b = $v;
    } elsif ($i == 4) {
        $r = $t; $g = $p; $b = $v;
    } elsif ($i == 5) {
        $r = $v; $g = $p; $b = $q;
    }
    ($r, $g, $b) = clampRGB($r, $g, $b);
    return ($r, $g, $b);
}

sub rgb2hsp {
    my ($r, $g, $b) = @_;
    $r = clamp($r);
    $g = clamp($g);
    $b = clamp($b);
    my $c = $COEFFICIENTS->{$COEFFICIENTS_TYPE // 'bt709'};
    my $Pr = $c->[R];
    my $Pg = $c->[G];
    my $Pb = $c->[B];
    my $p = sqrt($Pr * $r * $r + $Pg * $g * $g + $Pb * $b * $b);
    if ($r == $g && $r == $b) {
        return (0, 0, $p);
    }
    my $h;
    my $s;
    if ($r>= $g && $r>= $b) {     #  $r is largest
        if ($b>= $g) {
            $h = 1-1/6*($b-$g)/($r-$g); $s = 1-$g/$r; # g is smallest
        } else {
            $h = 1/6*($g-$b)/($r-$b); $s = 1-$b/$r; # b is smallest
        }
    } elsif ($g>= $r && $g>= $b) { #  $g is largest
        if ($r>= $b) {
            $h = 1/3-1/6*($r-$b)/($g-$b); $s = 1-$b/$g; # b is smallest
        } else {
            $h = 1/3+1/6*($b-$r)/($g-$r); $s = 1-$r/$g; # r is smallest
        }
    } else {                    #  $b is largest
        if ($g>= $r) {
            $h = 2/3-1/6*($g-$r)/($b-$r); $s = 1-$r/$b; # r is smallest
        } else {
            $h = 2/3+1/6*($r-$g)/($b-$g); $s = 1-$g/$b; # g is smallest
        }
    }
    $s = clamp($s);
    $p = clamp($p);
    return ($h, $s, $p);
}

sub hsp2rgb {
    my ($h, $s, $p) = @_;
    $h += 1 while $h < 0;
    $h -= 1 while $h >= 1;
    $s = clamp($s);
    $p = clamp($p);

    my $c = $COEFFICIENTS->{$COEFFICIENTS_TYPE // 'bt709'};
    my $Pr = $c->[R];
    my $Pg = $c->[G];
    my $Pb = $c->[B];

    my $part;
    my $minOverMax = 1 - $s;
    my ($r, $g, $b);
    if ($minOverMax>0) {
        if ($h<1/6) {           #  R>G>B
            $h = 6*($h-0/6); $part = 1+$h*(1/$minOverMax-1);
            $b = $p/sqrt($Pr/$minOverMax/$minOverMax+$Pg*$part*$part+$Pb);
            $r = ($b)/$minOverMax; $g = ($b)+$h*(($r)-($b));
        } elsif ($h<2/6) {      #  G>R>B
            $h = 6*(-$h+2/6); $part = 1+$h*(1/$minOverMax-1);
            $b = $p/sqrt($Pg/$minOverMax/$minOverMax+$Pr*$part*$part+$Pb);
            $g = ($b)/$minOverMax; $r = ($b)+$h*(($g)-($b));
        } elsif ($h<3/6) {      #  G>B>R
            $h = 6*( $h-2/6); $part = 1+$h*(1/$minOverMax-1);
            $r = $p/sqrt($Pg/$minOverMax/$minOverMax+$Pb*$part*$part+$Pr);
            $g = ($r)/$minOverMax; $b = ($r)+$h*(($g)-($r));
        } elsif ($h<4/6) {      #  B>G>R
            $h = 6*(-$h+4/6); $part = 1+$h*(1/$minOverMax-1);
            $r = $p/sqrt($Pb/$minOverMax/$minOverMax+$Pg*$part*$part+$Pr);
            $b = ($r)/$minOverMax; $g = ($r)+$h*(($b)-($r));
        } elsif ($h<5/6) {      #  B>R>G
            $h = 6*( $h-4/6); $part = 1+$h*(1/$minOverMax-1);
            $g = $p/sqrt($Pb/$minOverMax/$minOverMax+$Pr*$part*$part+$Pg);
            $b = ($g)/$minOverMax; $r = ($g)+$h*(($b)-($g));
        } else {                #  R>B>G
            $h = 6*(-$h+6/6); $part = 1+$h*(1/$minOverMax-1);
            $g = $p/sqrt($Pr/$minOverMax/$minOverMax+$Pb*$part*$part+$Pg);
            $r = ($g)/$minOverMax; $b = ($g)+$h*(($r)-($g));
        }
    } else {
        if ( $h<1/6) {        #  R>G>B
            $h = 6*( $h-0/6); $r = sqrt($p*$p/($Pr+$Pg*$h*$h)); $g = ($r)*$h; $b = 0;
        } elsif ( $h<2/6) { #  G>R>B
            $h = 6*(-$h+2/6); $g = sqrt($p*$p/($Pg+$Pr*$h*$h)); $r = ($g)*$h; $b = 0;
        } elsif ( $h<3/6) { #  G>B>R
            $h = 6*( $h-2/6); $g = sqrt($p*$p/($Pg+$Pb*$h*$h)); $b = ($g)*$h; $r = 0;
        } elsif ( $h<4/6) { #  B>G>R
            $h = 6*(-$h+4/6); $b = sqrt($p*$p/($Pb+$Pg*$h*$h)); $g = ($b)*$h; $r = 0;
        } elsif ( $h<5/6) { #  B>R>G
            $h = 6*( $h-4/6); $b = sqrt($p*$p/($Pb+$Pr*$h*$h)); $r = ($b)*$h; $g = 0;
        } else {                #  R>B>G
            $h = 6*(-$h+6/6); $r = sqrt($p*$p/($Pr+$Pb*$h*$h)); $b = ($r)*$h; $g = 0;
        }
    }
    ($r, $g, $b) = clampRGB($r, $g, $b);
    return ($r, $g, $b);
}

# apply correction: convert linear values to gamma-compressed sRGB values
sub gammaCompress {
    if (scalar @_ == 3) {
        my @y = map { gammaCompress($_) } @_;
        return @y if wantarray;
        return \@y;
    }
    my $x = shift;
    if ($x <= 0.0031308) {
        return 12.92 * $x;
    }
    return 1.055 * $x ** (1/2.4) - 0.055;
}

# convert gamma-compressed sRGB values to linear values
sub gammaExpand {
    if (scalar @_ == 3) {
        my @y = map { gammaExpand($_) } @_;
        return @y if wantarray;
        return \@y;
    }
    my $x = shift;
    if ($x <= 0.04045) {
        return $x / 12.92;
    }
    return (($x + 0.055) / 1.055) ** 2.4;
}

# The luma is the weighted sum of gamma-compressed sRGB values, used
# in video engineering.
#
# Takes gamma-compressed sRGB values.
# Returns the (linear) luma.
sub luma {
    my ($r, $g, $b, %args) = @_;
    ($r, $g, $b) = map { clamp($_) } ($r, $g, $b);
    my $c = $COEFFICIENTS->{$COEFFICIENTS_TYPE // 'bt709'};
    my $luma = $c->[R] * $r + $c->[G] * $g + $c->[B] * $b;
    if (!$args{noExpand}) {
        $luma = gammaExpand($luma);
    }
    return $luma;
}

# The luminance, or relative luminance, is the weighted sum of
# **linear** RGB components.  Luminance is the best reflection of the
# perceived brightness of a color.
#
# Takes gamma-compressed sRGB values.
# Returns the (linear) relative luminance.
sub luminance {
    my ($r, $g, $b, %args) = @_;
    ($r, $g, $b) = map { clamp($_) } ($r, $g, $b);
    if (!$args{noExpand}) {
        $r = gammaExpand($r);
        $g = gammaExpand($g);
        $b = gammaExpand($b);
    }
    my $c = $COEFFICIENTS->{$COEFFICIENTS_TYPE // 'bt709'};
    return $c->[R] * $r + $c->[G] * $g + $c->[B] * $b;
}

# returns a very close approximation to the gamma-compressed luminance
# for a (gamma-compressed) sRGB color.
sub hspBrightness {
    my ($r, $g, $b, %args) = @_;
    ($r, $g, $b) = map { clamp($_) } ($r, $g, $b);
    my $c = $COEFFICIENTS->{$COEFFICIENTS_TYPE // 'hsp'};
    if ($args{expand}) {
        $r = gammaExpand($r);
        $g = gammaExpand($g);
        $b = gammaExpand($b);
    }
    return sqrt($c->[R] * $r * $r + $c->[G] * $g * $g + $c->[B] * $b * $b);
}

sub ncmp {
    my ($a, $b, $x) = @_;
    $x //= 0.01;
    my $result = $a - $b;
    return 0 if abs($result) < $x;
    return $result;
}

sub hmod {
    my ($h) = @_;
    $h += 1 while $h < 0;
    $h -= 1 while $h >= 1;
    return $h;
}

# shortcuts to ncmp
sub nlt { my ($a, $b, $x) = @_; return ncmp($a, $b, $x) < 0; }
sub ngt { my ($a, $b, $x) = @_; return ncmp($a, $b, $x) > 0; }
sub neq { my ($a, $b, $x) = @_; return ncmp($a, $b, $x) == 0; }
sub nne { my ($a, $b, $x) = @_; return ncmp($a, $b, $x) != 0; }
sub nle { my ($a, $b, $x) = @_; return ncmp($a, $b, $x) <= 0; }
sub nge { my ($a, $b, $x) = @_; return ncmp($a, $b, $x) >= 0; }

1;
