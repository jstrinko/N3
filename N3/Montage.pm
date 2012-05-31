package N3::Montage;

use strict;
use N3::Util;

init();

my %MontageMap;

sub init {
    my $montageFile = "$ENV{SRCTOP}/$ENV{PROJECT}/montages.ref";
    open(MONTAGE, $montageFile) or die "Unable to open montage file: $!";
    while(<MONTAGE>) {
	my $line = $_;
	my ($id, $imageLocation, $width, $height, $xOffset, $yOffset) = 
	    map {
		my $tmp = $_;
		$tmp =~ s{\s}{}gis;
		$tmp;
	    }
	    split(/\|/, $line);
	if ($id) {
	    $MontageMap{$id} = {
		id => $id,
		imageLocation => $imageLocation,
		width => $width,
		height => $height,
		xOffset => $xOffset,
		yOffset => $yOffset,
	    };
	}
    }
    close MONTAGE;
}

sub new {
    my $class = shift;
    my $id = shift;
    die "No montage found for: $id" unless $MontageMap{$id};
    my $self = $MontageMap{$id};
    return bless $self, $class;
}

sub imageLocation {
    my $self = shift;
    return $self->{imageLocation};
}

sub width {
    my $self = shift;
    return $self->{width};
}

sub height {
    my $self = shift;
    return $self->{height};
}

sub xOffset {
    my $self = shift;
    return $self->{xOffset};
}

sub yOffset {
    my $self = shift;
    return $self->{yOffset};
}

1;
