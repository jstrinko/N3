package N3::Hashable;

sub hash {
    my $self = shift;
    my $ref = ref($self);
    if ($ref eq 'SCALAR') {
	return $self;
    }
    elsif ($ref eq 'ARRAY') {
	my @arr = ();
	foreach my $part (@$self) {
	    push @arr, N3::Hashable::hash($part);
	}
	return \@arr;
    }
    elsif ($ref eq 'HASH') {
	my $hash = {};
	foreach my $key (keys %$self) {
	    $hash->{$key} = N3::Hashable::hash($self->{$key});
	}
    }
    
}

1;
