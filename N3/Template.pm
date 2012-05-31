package N3::Template;

use N3;

sub include {
    my $self = shift;
    my $uri = shift;
    $uri = "/$uri";
    my $page = N3::Page->new($uri);
    $page->run;
    return $page->contents;
}

sub asXml {
    my $self = shift;
    my $data = shift;
    return '<?xml version="1.0"?>' . $self->makeXml($data);
}

sub makeXml {
    my $self = shift;
    my $data = shift;
    my $xml;
    foreach my $key (keys %$data) {
	$xml .= "<$key>";
	my $node = $data->{$key};
	if (ref $node eq 'ARRAY') {
	    foreach my $element (@$node) {
		$xml .= $self->makeXml($element);
	    }
	}
	elsif ((ref $node) =~ m{HASH}) {
	    $xml .= $self->makeXml($node);
	}
	else {
	    $xml .= $node;
	}
	$xml .= "</$key>";
    }
    return $xml;
}

sub scripts {
    my $self = shift;
    my $junk = shift;
    my $scriptList = shift;
    $scriptList =~ s{^\s*}{}gis;
    $scriptList =~ s{\s*$}{}gis;
    my @scripts = split(/\s+/, $scriptList);
    my $version;
    foreach my $script (@scripts) {
        my $tmpPage = N3::Page->new($script);
        $version += $tmpPage->version;
    }
    my $page = N3->page;
    my $scriptText = join('+', map { $page->uriToShort($_); } @scripts);
    return "<script language='Javascript' type='text/javascript' src='" . $self->httpSite . '/script/' . $scriptText . "/script.js?version=$version'></script>";
}

sub css {
    my $self = shift;
    my $junk = shift;
    my $cssList = shift;
    $cssList =~ s{^\s*}{}gis;
    $cssList =~ s{\s*$}{}gis;
    my @cssUris = split(/\s+/, $cssList);
    my $version;
    foreach my $uri (@cssUris) {
        my $tmpPage = N3::Page->new($uri);
        $version += $tmpPage->version;
    }
    my $page = N3->page;
    my $cssText = join('+', map { $page->uriToShort($_); } @cssUris);
    return "<link rel='stylesheet' type='text/css' href='" . $self->httpSite . "/css/" . $cssText . "/style.css?version=$version'/>";
}

sub httpSite {
    my $self = shift;
    my $httpSite = $self->hostname;
    $httpSite .= ":" . $ENV{PORT} if $ENV{PORT};
    return "http://" . $httpSite;
}

sub imgSrc {
    my $self = shift;
    my $src = shift;
    return $ENV{IMAGE_SERVER} . $src;
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
