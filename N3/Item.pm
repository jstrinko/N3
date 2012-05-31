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

sub ownerId {
    my $self = shift;
    $self->{ownerId} = shift if @_;
    return $self->{ownerId};
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}

1;
