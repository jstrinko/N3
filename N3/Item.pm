package N3::Item;

use strict;

sub new {
    my $class = shift;
    my $ownerId = shift;
    my $self = {
	ownerId => $ownerId,
    };
    return bless $self, $class;
}

sub owner_id {
    my $self = shift;
    $self->{owner_id} = shift if @_;
    return $self->{owner_id};
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}

1;
