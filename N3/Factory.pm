package N3::Factory;

use strict;
use base 'N3::Savable';

sub new {
    my $class = shift;
    my $ownerId = shift;
    my $tmp = { 
	items => {},
	ownerId => $ownerId,
    };
    bless $tmp, $class;
    my $self = $tmp->load;
    return $self;
}

sub ownerId {
    my $self = shift;
    $self->{ownerId} = shift if @_;
    return $self->{ownerId};
}

sub addItem {
    my $self = shift;
    my $item = shift;
    die "You must provide an item" unless $item;
    my $largest = 0;
    map { $largest = $_ if $_ > $largest; } keys %{$self->{items}};
    my $id = $largest + 1;
    $item->id($id);
    $self->{items}->{$id} = $item;
    return $self->{items}->{$id};
}

sub removeItem {
    my $self = shift;
    my $id = shift;
    die "Must provide an id" unless $id;
    warn "$id does not exist in this factory" unless $self->{items}->{$id};
    delete $self->{items}->{$id};
}

sub item {
    my $self = shift;
    my $id = shift;
    die "Must provide an id" unless $id;
    return $self->{items}->{$id};
}

sub items {
    my $self = shift;
    return $self->{items};
}

sub filename {
    die "You must override the filename method for factory classes";
}

1;
