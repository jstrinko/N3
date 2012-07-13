package N3::Montage;

use strict;
use N3::Util;

init();

my %Montage_Map;

sub init {
    my $montage_file = "$ENV{SRCTOP}/$ENV{PROJECT}/montages.ref";
    open(MONTAGE, $montage_file) or die "Unable to open montage file: $!";
    while(<MONTAGE>) {
	my $line = $_;
	my ($id, $image_location, $width, $height, $x_offset, $y_offset) = 
	    map {
		my $tmp = $_;
		$tmp =~ s{\s}{}gis;
		$tmp;
	    }
	    split(/\|/, $line);
	if ($id) {
	    $Montage_Map{$id} = {
		id => $id,
		imageLocation => $image_location,
		width => $width,
		height => $height,
		xOffset => $x_offset,
		yOffset => $y_offset,
	    };
	}
    }
    close MONTAGE;
}

sub new {
    my $class = shift;
    my $id = shift;
    die "No montage found for: $id" unless $Montage_Map{$id};
    my $self = $Montage_Map{$id};
    return bless $self, $class;
}

sub image_location {
    my $self = shift;
    return $self->{image_location};
}

sub width {
    my $self = shift;
    return $self->{width};
}

sub height {
    my $self = shift;
    return $self->{height};
}

sub x_offset {
    my $self = shift;
    return $self->{x_offset};
}

sub y_offset {
    my $self = shift;
    return $self->{y_offset};
}

1;
