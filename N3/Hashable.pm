package N3::Hashable;

use strict;

sub hash {
    my $self = shift;
    my $ref = ref($self);
    return $self unless $ref;
    if ($ref eq 'SCALAR') {
	return \$self;
    }
    elsif ($ref eq 'ARRAY') {
	my @arr = ();
	foreach my $part (@$self) {
	    push @arr, N3::Hashable::hash($part);
	}
	return \@arr;
    }
    elsif ($ref eq 'HASH' || $self->isa('N3::Hashable')) {
	my $hash = {};
	foreach my $key (keys %$self) {
	    $hash->{$key} = N3::Hashable::hash($self->{$key});
	}
	return $hash;
    }
    
}

1;
