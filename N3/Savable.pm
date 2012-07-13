package N3::Savable;

use strict;

use Storable;
use Data::Dumper;

sub save {
    my $self = shift;
    $self->rinse;
    store $self, $self->filename;
}

sub load {
    my $self = shift;
    my $filename = $self->filename;
    if (-e $filename) {
	$self = retrieve $filename;
	$self->loaded(1);
    }
    return $self;
}

sub loaded {
    my $self = shift;
    $self->{_loaded} = shift if @_;
    return $self->{_loaded};
}

sub rinse {
    my $self = shift;
    foreach my $key (keys %$self) {
	delete $self->{$key} if $key =~ m{^_}si;
    }
}

sub numeric_path {
    my $self = shift;
    my $number = shift;
    $number = "0$number" if ((length "$number") % 2);
    my @parts;
    while ($number =~ m{(\d\d)}g) {
	push @parts, $1;
    }
    return join("/", @parts);
}

sub filename {
    die "The filename method must be overridden";
}

1;
