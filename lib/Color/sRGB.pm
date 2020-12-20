package Color::sRGB;
use warnings;
use strict;
use v5.10.0;

=head1 NAME

Color::sRGB --- A color object in the sRGB color space

=head1 SYNOPSIS

    my $color = Color::SRGB->new('#ff0');
    my $color = Color::SRGB->new('#ffff00');
    my $color = Color::SRGB->new('#ffffffff0000');

=cut

use Regexp::Common qw(number);
use Scalar::Util qw(looks_like_number);
use lib '..';
use Color::sRGB::Util qw(:all);
use Data::Dumper qw(Dumper);

use overload '""' => \&asString;

our $VERSION;
BEGIN {
    $VERSION = v0.0.0;
}

our $NAMED_COLORS;
our $RE_SEPARATOR;
our $RE_ALPHA_SEPARATOR;
BEGIN {
    $NAMED_COLORS = {
                     # CSS Level 1
                     black                => '#000000',
                     silver               => '#c0c0c0',
                     gray                 => '#808080',
                     grey                 => '#808080',
                     white                => '#ffffff',
                     maroon               => '#800000',
                     red                  => '#ff0000',
                     purple               => '#800080',
                     fuchsia              => '#ff00ff',
                     green                => '#008000',
                     lime                 => '#00ff00',
                     olive                => '#808000',
                     yellow               => '#ffff00',
                     navy                 => '#000080',
                     blue                 => '#0000ff',
                     teal                 => '#008080',
                     aqua                 => '#00ffff',
                     # CSS Level 2 (Revision 1)
                     orange               => '#ffa500',
                     # CSS Color Module Level 3
                     aliceblue            => '#f0f8ff',
                     antiquewhite         => '#faebd7',
                     aquamarine           => '#7fffd4',
                     azure                => '#f0ffff',
                     beige                => '#f5f5dc',
                     bisque               => '#ffe4c4',
                     blanchedalmond       => '#ffebcd',
                     blueviolet           => '#8a2be2',
                     brown                => '#a52a2a',
                     burlywood            => '#deb887',
                     cadetblue            => '#5f9ea0',
                     chartreuse           => '#7fff00',
                     chocolate            => '#d2691e',
                     coral                => '#ff7f50',
                     cornflowerblue       => '#6495ed',
                     cornsilk             => '#fff8dc',
                     crimson              => '#dc143c',
                     cyan                 => '#00ffff',
                     aqua                 => '#00ffff',
                     darkblue             => '#00008b',
                     darkcyan             => '#008b8b',
                     darkgoldenrod        => '#b8860b',
                     darkgray             => '#a9a9a9',
                     darkgrey             => '#a9a9a9',
                     darkgreen            => '#006400',
                     darkgrey             => '#a9a9a9',
                     darkkhaki            => '#bdb76b',
                     darkmagenta          => '#8b008b',
                     darkolivegreen       => '#556b2f',
                     darkorange           => '#ff8c00',
                     darkorchid           => '#9932cc',
                     darkred              => '#8b0000',
                     darksalmon           => '#e9967a',
                     darkseagreen         => '#8fbc8f',
                     darkslateblue        => '#483d8b',
                     darkslategray        => '#2f4f4f',
                     darkslategrey        => '#2f4f4f',
                     darkturquoise        => '#00ced1',
                     darkviolet           => '#9400d3',
                     deeppink             => '#ff1493',
                     deepskyblue          => '#00bfff',
                     dimgray              => '#696969',
                     dimgrey              => '#696969',
                     dodgerblue           => '#1e90ff',
                     firebrick            => '#b22222',
                     floralwhite          => '#fffaf0',
                     forestgreen          => '#228b22',
                     gainsboro            => '#dcdcdc',
                     ghostwhite           => '#f8f8ff',
                     gold                 => '#ffd700',
                     goldenrod            => '#daa520',
                     greenyellow          => '#adff2f',
                     grey                 => '#808080',
                     honeydew             => '#f0fff0',
                     hotpink              => '#ff69b4',
                     indianred            => '#cd5c5c',
                     indigo               => '#4b0082',
                     ivory                => '#fffff0',
                     khaki                => '#f0e68c',
                     lavender             => '#e6e6fa',
                     lavenderblush        => '#fff0f5',
                     lawngreen            => '#7cfc00',
                     lemonchiffon         => '#fffacd',
                     lightblue            => '#add8e6',
                     lightcoral           => '#f08080',
                     lightcyan            => '#e0ffff',
                     lightgoldenrodyellow => '#fafad2',
                     lightgray            => '#d3d3d3',
                     lightgrey            => '#d3d3d3',
                     lightgreen           => '#90ee90',
                     lightgrey            => '#d3d3d3',
                     lightpink            => '#ffb6c1',
                     lightsalmon          => '#ffa07a',
                     lightseagreen        => '#20b2aa',
                     lightskyblue         => '#87cefa',
                     lightslategray       => '#778899',
                     lightslategrey       => '#778899',
                     lightsteelblue       => '#b0c4de',
                     lightyellow          => '#ffffe0',
                     limegreen            => '#32cd32',
                     linen                => '#faf0e6',
                     magenta              => '#ff00ff',
                     fuschia              => '#ff00ff',
                     mediumaquamarine     => '#66cdaa',
                     mediumblue           => '#0000cd',
                     mediumorchid         => '#ba55d3',
                     mediumpurple         => '#9370db',
                     mediumseagreen       => '#3cb371',
                     mediumslateblue      => '#7b68ee',
                     mediumspringgreen    => '#00fa9a',
                     mediumturquoise      => '#48d1cc',
                     mediumvioletred      => '#c71585',
                     midnightblue         => '#191970',
                     mintcream            => '#f5fffa',
                     mistyrose            => '#ffe4e1',
                     moccasin             => '#ffe4b5',
                     navajowhite          => '#ffdead',
                     oldlace              => '#fdf5e6',
                     olivedrab            => '#6b8e23',
                     orangered            => '#ff4500',
                     orchid               => '#da70d6',
                     palegoldenrod        => '#eee8aa',
                     palegreen            => '#98fb98',
                     paleturquoise        => '#afeeee',
                     palevioletred        => '#db7093',
                     papayawhip           => '#ffefd5',
                     peachpuff            => '#ffdab9',
                     peru                 => '#cd853f',
                     pink                 => '#ffc0cb',
                     plum                 => '#dda0dd',
                     powderblue           => '#b0e0e6',
                     rosybrown            => '#bc8f8f',
                     royalblue            => '#4169e1',
                     saddlebrown          => '#8b4513',
                     salmon               => '#fa8072',
                     sandybrown           => '#f4a460',
                     seagreen             => '#2e8b57',
                     seashell             => '#fff5ee',
                     sienna               => '#a0522d',
                     skyblue              => '#87ceeb',
                     slateblue            => '#6a5acd',
                     slategray            => '#708090',
                     slategrey            => '#708090',
                     snow                 => '#fffafa',
                     springgreen          => '#00ff7f',
                     steelblue            => '#4682b4',
                     tan                  => '#d2b48c',
                     thistle              => '#d8bfd8',
                     tomato               => '#ff6347',
                     turquoise            => '#40e0d0',
                     violet               => '#ee82ee',
                     wheat                => '#f5deb3',
                     whitesmoke           => '#f5f5f5',
                     yellowgreen          => '#9acd32',
                     # CSS Color Module Level 4
                     rebeccapurple        => '#663399',
                    };
    $RE_SEPARATOR = qr{(?:\s+|\s*,\s*)};
    $RE_ALPHA_SEPARATOR = qr{(?:\s*/\s*|\s*,\s*)};
}

sub new {
    my $class = shift;
    my $self = bless({
                      r => 1.0,
                      g => 1.0,
                      b => 1.0,
                      a => 1.0
                     }, $class);
    $self->set(@_);
    return $self;
}

sub set {
    my $self = shift;
    if (scalar @_ == 0) {
        $self->{r} = 1.0;
        $self->{g} = 1.0;
        $self->{b} = 1.0;
        $self->{a} = 1.0;
        $self->computeFromRGB();
        return;
    }
    if (scalar @_ == 1) {
        my $color = shift;
        $color = lc $color;
        if ($color =~ m{^\#
                        ([[:xdigit:]])
                        ([[:xdigit:]])
                        ([[:xdigit:]])$}xi) {
            my ($r, $g, $b) = ($1, $2, $3);
            ($r, $g, $b) = (hex($r), hex($g), hex($b));
            $self->setRGBA($r, $g, $b, undef, 15);
        } elsif ($color =~ m{^\#
                             ([[:xdigit:]])
                             ([[:xdigit:]])
                             ([[:xdigit:]])
                             ([[:xdigit:]])$}xi) {
            my ($r, $g, $b, $a) = ($1, $2, $3, $4);
            ($r, $g, $b, $a) = (hex($r), hex($g), hex($b), hex($a));
            $self->setRGBA($r, $g, $b, $a, 15);
        } elsif ($color =~ m{^\#
                             ([[:xdigit:]]{2})
                             ([[:xdigit:]]{2})
                             ([[:xdigit:]]{2})$}xi) {
            my ($r, $g, $b) = ($1, $2, $3);
            ($r, $g, $b) = (hex($r), hex($g), hex($b));
            $self->setRGBA($r, $g, $b, undef, 255);
        } elsif ($color =~ m{^\#
                             ([[:xdigit:]]{2})
                             ([[:xdigit:]]{2})
                             ([[:xdigit:]]{2})
                             ([[:xdigit:]]{2})$}xi) {
            my ($r, $g, $b, $a) = ($1, $2, $3, $4);
            ($r, $g, $b, $a) = (hex($r), hex($g), hex($b), hex($a));
            $self->setRGBA($r, $g, $b, $a, 255);
        } elsif ($color =~ m{^\#
                             ([[:xdigit:]]{4})
                             ([[:xdigit:]]{4})
                             ([[:xdigit:]]{4})$}xi) {
            my ($r, $g, $b) = ($1, $2, $3);
            ($r, $g, $b) = (hex($r), hex($g), hex($b));
            $self->setRGBA($r, $g, $b, undef, 65535);
        } elsif ($color =~ m{^\#
                             ([[:xdigit:]]{4})
                             ([[:xdigit:]]{4})
                             ([[:xdigit:]]{4})
                             ([[:xdigit:]]{4})$}xi) {
            my ($r, $g, $b, $a) = ($1, $2, $3, $4);
            ($r, $g, $b, $a) = (hex($r), hex($g), hex($b), hex($a));
            $self->setRGBA($r, $g, $b, $a, 65535);
        } elsif ($color eq 'transparent') {
            $self->setRGBA(0, 0, 0, 0);
        } elsif (exists $NAMED_COLORS->{$color}) {
            $self->set($NAMED_COLORS->{$color});
            return;
        } elsif ($color =~ m{^ \s* rgba? \s* \( \s*
                             ($RE{num}{real}) (\s*%)? $RE_SEPARATOR
                             ($RE{num}{real}) (\s*%)? $RE_SEPARATOR
                             ($RE{num}{real}) (\s*%)? \s* \) \s* $}xi) {
            my ($r, $rPercent, $g, $gPercent, $b, $bPercent) =
              ($1, $2, $3, $4, $5, $6);
            $r /= ($rPercent ? 100 : 255);
            $g /= ($gPercent ? 100 : 255);
            $b /= ($bPercent ? 100 : 255);
            $self->setRGBA($r, $g, $b, undef);
        } elsif ($color =~ m{^ \s* rgba? \s* \( \s*
                             ($RE{num}{real}) (\s*%)? $RE_SEPARATOR
                             ($RE{num}{real}) (\s*%)? $RE_SEPARATOR
                             ($RE{num}{real}) (\s*%)? $RE_ALPHA_SEPARATOR
                             ($RE{num}{real}) (\s*%)? \s* \) \s* $}xi) {
            my ($r, $rPercent, $g, $gPercent, $b, $bPercent, $a, $aPercent) =
              ($1, $2, $3, $4, $5, $6, $7, $8);
            $r /= ($rPercent ? 100 : 255);
            $g /= ($gPercent ? 100 : 255);
            $b /= ($bPercent ? 100 : 255);
            $a /= ($aPercent ? 100 : 1);
            $self->setRGBA($r, $g, $b, $a);
        } else {
            die("invalid color: $color\n");
        }
    } elsif (scalar @_ == 3 &&
             looks_like_number($_[0]) && looks_like_number($_[1]) &&
             looks_like_number($_[2])) {
        my ($r, $g, $b) = @_;
        $self->setRGBA($r, $g, $b);
    } elsif (scalar @_ == 4 &&
             looks_like_number($_[0]) && looks_like_number($_[1]) &&
             looks_like_number($_[2]) && looks_like_number($_[3])) {
        my ($r, $g, $b, $a) = @_;
        $self->setRGBA($r, $g, $b, $a);
    } else {
        die(sprintf("invalid color: %s", join(', ', @_)));
    }
}

sub setRGBA {
    my ($self, $r, $g, $b, $a, $div, $divA) = @_;
    $div //= 1.0;
    $divA //= $div;
    $r = defined $r ? clamp($r / $div)  : 1.0;
    $g = defined $g ? clamp($g / $div)  : 1.0;
    $b = defined $b ? clamp($b / $div)  : 1.0;
    $a = defined $a ? clamp($a / $divA) : 1.0;
    $self->{r} = $r;
    $self->{g} = $g;
    $self->{b} = $b;
    $self->{a} = $a;
    $self->computeFromRGB();
}

sub computeFromRGB {
    my ($self) = @_;
    $self->computeHSLfromRGB();
    $self->computeHSVfromRGB();
    $self->computeHSPfromRGB();
}

sub computeFromHSL {
    my ($self) = @_;
    $self->computeRGBfromHSL();
    $self->computeHSVfromRGB();
    $self->computeHSPfromRGB();
}

sub computeFromHSV {
    my ($self) = @_;
    $self->computeRGBfromHSV();
    $self->computeHSLfromRGB();
    $self->computeHSPfromRGB();
}

sub computeFromHSP {
    my ($self) = @_;
    $self->computeRGBfromHSP();
    $self->computeHSLfromRGB();
    $self->computeHSVfromRGB();
}

sub computeHSLfromRGB {
    my ($self) = @_;
    my ($r, $g, $b) = ($self->{r}, $self->{g}, $self->{b});
    my ($h, $s, $l) = rgb2hsl($r, $g, $b);
    $self->{hsl} = { h => $h, s => $s, l => $l };
}

sub computeHSVfromRGB {
    my ($self) = @_;
    my ($r, $g, $b) = ($self->{r}, $self->{g}, $self->{b});
    my ($h, $s, $v) = rgb2hsv($r, $g, $b);
    $self->{hsv} = { h => $h, s => $s, v => $v };
}

sub computeHSPfromRGB {
    my ($self) = @_;
    my ($r, $g, $b) = ($self->{r}, $self->{g}, $self->{b});
    my ($h, $s, $p) = rgb2hsp($r, $g, $b);
    $self->{hsp} = { h => $h, s => $s, p => $p };
}

sub computeRGBfromHSL {
    my ($self) = @_;
    my $h = hmod(eval { $self->{hsl}->{h} } // 0);
    my $s = clamp(eval { $self->{hsl}->{s} } // 0);
    my $l = clamp(eval { $self->{hsl}->{l} } // 1);
    my ($r, $g, $b) = hsl2rgb($h, $s, $l);
    $self->{r} = $r;
    $self->{g} = $g;
    $self->{b} = $b;
}

sub computeRGBfromHSV {
    my ($self) = @_;
    my $h = hmod(eval { $self->{hsv}->{h} } // 0);
    my $s = clamp(eval { $self->{hsv}->{s} } // 0);
    my $v = clamp(eval { $self->{hsv}->{v} } // 1);
    my ($r, $g, $b) = hsv2rgb($h, $s, $v);
    $self->{r} = $r;
    $self->{g} = $g;
    $self->{b} = $b;
}

sub computeRGBfromHSP {
    my ($self) = @_;
    my $h = hmod(eval { $self->{hsp}->{h} } // 0);
    my $s = clamp(eval { $self->{hsp}->{s} } // 0);
    my $p = clamp(eval { $self->{hsp}->{p} } // 1);
    my ($r, $g, $b) = hsp2rgb($h, $s, $p);
    $self->{r} = $r;
    $self->{g} = $g;
    $self->{b} = $b;
}

sub getHSL {
    my ($self) = @_;
    my @result = ($self->{hsl}->{h},
                  $self->{hsl}->{s},
                  $self->{hsl}->{l});
    return @result if wantarray;
    return \@result;
}

sub getHSV {
    my ($self) = @_;
    my @result = ($self->{hsv}->{h},
                  $self->{hsv}->{s},
                  $self->{hsv}->{v});
    return @result if wantarray;
    return \@result;
}

sub getHSP {
    my ($self) = @_;
    my @result = ($self->{hsp}->{h},
                  $self->{hsp}->{s},
                  $self->{hsp}->{p});
    return @result if wantarray;
    return \@result;
}

sub getRGBA {
    my ($self) = @_;
    my @result = ($self->{r}, $self->{g}, $self->{b}, $self->{a});
    return @result if wantarray;
    return \@result;
}

sub setHSL {
    my ($self, $h, $s, $l) = @_;
    $self->{hsl}->{h} = hmod($h)  if defined $h;
    $self->{hsl}->{s} = clamp($s) if defined $s;
    $self->{hsl}->{l} = clamp($l) if defined $l;
    $self->computeFromHSL();
}

sub setHSV {
    my ($self, $h, $s, $v) = @_;
    $self->{hsv}->{h} = hmod($h)  if defined $h;
    $self->{hsv}->{s} = clamp($s) if defined $s;
    $self->{hsv}->{v} = clamp($v) if defined $v;
    $self->computeFromHSV();
}

sub setHSP {
    my ($self, $h, $s, $p) = @_;
    $self->{hsp}->{h} = hmod($h)  if defined $h;
    $self->{hsp}->{s} = clamp($s) if defined $s;
    $self->{hsp}->{p} = clamp($p) if defined $p;
    $self->computeFromHSP();
}

sub asString {
    my ($self) = @_;
    my $rr = int(0.5 + $self->{r} * 255);
    my $gg = int(0.5 + $self->{g} * 255);
    my $bb = int(0.5 + $self->{b} * 255);
    my $aa = int(0.5 + $self->{a} * 255);
    if ($aa == 255) {
        return sprintf("#%02x%02x%02x", $rr, $gg, $bb);
    }
    return sprintf("#%02x%02x%02x%02x", $rr, $gg, $bb, $aa);
}

sub asStringHSL {
    my ($self) = @_;
    my $hsl = $self->{hsl};
    return sprintf('hsl(%.3f, %.3f, %.3f)', @{$hsl}{qw(h s l)}) if $self->{a} == 1.0;
    return sprintf('hsl(%.3f, %.3f, %.3f, %.3f)', @{$hsl}{qw(h s l)}, $self->{a});
}

sub asStringHSV {
    my ($self) = @_;
    my $hsv = $self->{hsv};
    return sprintf('hsv(%.3f, %.3f, %.3f)', @{$hsv}{qw(h s v)}) if $self->{a} == 1.0;
    return sprintf('hsv(%.3f, %.3f, %.3f, %.3f)', @{$hsv}{qw(h s v)}, $self->{a});
}

sub asStringHSP {
    my ($self) = @_;
    my $hsp = $self->{hsp};
    return sprintf('hsp(%.3f, %.3f, %.3f)', @{$hsp}{qw(h s p)}) if $self->{a} == 1.0;
    return sprintf('hsp(%.3f, %.3f, %.3f, %.3f)', @{$hsp}{qw(h s p)}, $self->{a});
}

sub multiplyRGB {
    my ($self, $multiplicand) = @_;
    my ($r, $g, $b) = ($self->{r},
                       $self->{g},
                       $self->{b});
    $r = clamp($r * $multiplicand, 0, 1);
    $g = clamp($g * $multiplicand, 0, 1);
    $b = clamp($b * $multiplicand, 0, 1);
    return __PACKAGE__->new($r, $g, $b, $self->{a});
}

sub saturateMultiplyRGB {
    my ($self, $multiplicand) = @_;
    my ($r, $g, $b) = ($self->{r},
                       $self->{g},
                       $self->{b});
    $r = clamp(1 - ((1 - $r) * $multiplicand), 0, 1);
    $g = clamp(1 - ((1 - $g) * $multiplicand), 0, 1);
    $b = clamp(1 - ((1 - $b) * $multiplicand), 0, 1);
    return __PACKAGE__->new($r, $g, $b, $self->{a});
}

# http://alienryderflex.com/hsp.html

1;
