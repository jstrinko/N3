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

sub scripts {
    my $self = shift;
    my $junk = shift;
    my $script_list = shift;
    $script_list =~ s{^\s*}{}gis;
    $script_list =~ s{\s*$}{}gis;
    my @scripts = split(/\s+/, $script_list);
    my $version;
    foreach my $script (@scripts) {
        my $tmp_page = N3::Page->new($script);
        $version += $tmp_page->version;
    }
    my $page = N3->page;
    my $script_text = join('+', map { $page->uri_to_short($_); } @scripts);
    return "<script language='Javascript' type='text/javascript' src='" . $self->httpSite . '/script/' . $script_text . "/script.js?version=$version'></script>";
}

sub css {
    my $self = shift;
    my $junk = shift;
    my $css_list = shift;
    $css_list =~ s{^\s*}{}gis;
    $css_list =~ s{\s*$}{}gis;
    my @css_uris = split(/\s+/, $css_list);
    my $version;
    foreach my $uri (@css_uris) {
        my $tmp_page = N3::Page->new($uri);
        $version += $tmp_page->version;
    }
    my $page = N3->page;
    my $css_text = join('+', map { $page->uri_to_short($_); } @css_uris);
    return "<link rel='stylesheet' type='text/css' href='" . $self->http_site . "/css/" . $css_text . "/style.css?version=$version'/>";
}

sub http_site {
    my $self = shift;
    my $http_site = $self->hostname;
    $http_site .= ":" . $ENV{PORT} if $ENV{PORT};
    return "http://" . $http_site;
}

sub img_src {
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
