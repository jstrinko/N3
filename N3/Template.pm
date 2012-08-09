package N3::Template;

use N3;
use Data::Dumper;

sub include {
    my $self = shift;
    my $uri = shift;
    $uri = "/$uri";
    my $page = N3::Page->new($uri);
    $page->run;
    return $page->contents;
}

sub as_xml {
    my $self = shift;
    my $data = shift;
    return '<?xml version="1.0"?>' . $self->make_xml($data);
}

sub make_xml {
    my $self = shift;
    my $data = shift;
    my $xml;
    foreach my $key (keys %$data) {
	$xml .= "<$key>";
	my $node = $data->{$key};
	if (ref $node eq 'ARRAY') {
	    foreach my $element (@$node) {
		$xml .= $self->make_xml($element);
	    }
	}
	elsif ((ref $node) =~ m{HASH}) {
	    $xml .= $self->make_xml($node);
	}
	else {
	    $xml .= $node;
	}
	$xml .= "</$key>";
    }
    return $xml;
}

sub http_site {
    my $self = shift;
    my $http_site = $self->hostname;
    $http_site .= ":" . $ENV{PORT} if $ENV{PORT};
    return "http://" . $http_site;
}

sub static_src {
    my $self = shift;
    my $src = shift;
    return $ENV{STATIC_SERVER} . $src;
}

sub hostname {
    my $self = shift;
    return $ENV{HOSTNAME} if $ENV{HOSTNAME};
    if (!$self->{hostname}) {
        my $hostname = `hostname`;
        $hostname =~ s{\s*$}{}gis;
        $self->{hostname} = $hostname;
    }
    return $self->{hostname};
}

1;
