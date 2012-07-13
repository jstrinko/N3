package N3::Page;

use strict;
use N3;
use N3::Util;
use HTML::TokeParser;
use Data::Dumper;

init();

my %Pages_Ref;
my %Pages_Cache;
my %Short_Map;

sub new {
    my $class = shift;
    my $uri = shift;
    my $self;
    if (!$Pages_Ref{$uri}) {
	my @parts = split(/\//, $uri);
	for(my $x = 0; $x < scalar @parts; $x++) {
	    my @tmp_parts;
	    foreach my $y (1..$x) {
		push @tmp_parts, $parts[$y];
	    }
	    my $tmp_uri = "/" . join("/", @tmp_parts);
	    if ($Pages_Ref{$tmpUri}) {
		$self = $Pages_Ref{$tmpUri};
		my @values;
		foreach my $y (($x+1)..scalar @parts) {
		    push @values, $parts[$y];
		}
		$self->{'values'} = \@values;
	    }
	}
	if (!$self) {
	    die "No page for $uri";
	}
    }
    else {
        $self = $Pages_Ref{$uri};
    }

    return bless $self, $class;
}

sub run {
    my $self = shift;
    if (!$Pages_Cache{$self->{uri}}) {
	my $add_index = $self->{local_location} =~ m{/$}gis ? "index" : "";
	my $full_location = $self->{local_location} . $add_index;
	my $base = "$ENV{SRCTOP}/$ENV{PROJECT}/htdocs$full_location";
	my $html_file = "$base.html";
	my $perl_file = "$base.pl";
	my $html_contents;
	my $perl_contents;
	if (-e $html_file) {
	    $html_contents = N3::Util::fileContents($html_file);
	}
	if (-e $perl_file) {
	    $perl_contents = N3::Util::fileContents($perl_file);
	}
	my @tmp_elements;
	$full_location = "htdocs$full_location";
	my $name_space_string = $full_location;
	$name_space_string =~ s{\..*$}{}gis;
	$name_space_string =~ s{\-}{}gis;
	my $name_space = join("::", split(/\//, $name_space_string));
	my $first_letter_capitalized_project = uc(substr($ENV{PROJECT}, 0, 1)) . substr($ENV{PROJECT},1,length($ENV{PROJECT}) - 1);
	$perl_contents = "package $name_space; use base '${first_letter_capitalized_project}::Template'; use strict; $perl_contents 1;";
	my $page_object = bless {}, $name_space;
	if ($html_contents) {
	    eval $perl_contents;
	    warn $@ if $@;
	    if ($page_object->can('init')) {
		push @tmp_elements, { 
		    type => 'object', 
		    object => $page_object,
		    method => 'init',
		};
	    }
	    $html_contents =~ s{\s+}{ }gis;
	    $html_contents =~ s{^\s+}{}gis;
	    $html_contents =~ s{\s+$}{}gis;
	    $html_contents =~ s{>\s+<}{><}gis;
	    $html_contents =~ s{<(\w+):\s*(.*?)>(?:(.*?)<:\1>)?}{$page_object->$1($self->parse_args($2), $3)}goe;
	    while($html_contents =~ m{\G(.*?)(?:\$([a-zA-Z_]\w*)\.(\w+)(\(.*?\))?)}mcosg) {
		my $html = $1;
		push @tmp_elements, {
		    type => 'html',
		    html => $html,
    		};
		if ($2) {
		    my ($object_name, $method, $args) = ($2, $3, $4);
		    $args =~ s{\(|\)}{}gis;
		    my $object;
		    if ($object_name eq 'self') {
			$object = $page_object;
		    }
		    elsif ($object_name eq 'request') {
			$object = N3->request;
		    }
		    elsif ($object_name eq 'page') {
			$object = N3->page;
		    }
		    elsif ($object_name eq 'user') {
			$object = N3->user;
		    }
		    push @tmp_elements, {
			type => 'object',
			object => $object,
			method => $method,
			argsString => $args,
		    };		    
		}
	    }
	    push @tmp_elements, {
		type => 'html',
		html => substr($html_contents, pos($html_contents), length($html_contents) - pos($html_contents)),
	    };
	}
	elsif ($perl_contents) {
	    eval $perl_contents;
	    warn $@ if $@;
	    push @tmp_elements, { 
		type => 'object', 
		object => $page_object,
		method => 'init',
	    };
	}
	else {
	    N3->request->redirect('/error');
	}
	$Pages_Cache{$self->{uri}}->{elements} = \@tmp_elements;
    }
    my @params = @{$self->{params}};
    if (scalar @params) {
	foreach my $x (0..scalar @params) {
	    N3->request->customParam($params[$x], $self->{'values'}->[$x]);
	}
    }
    my $elements = $Pages_Cache{$self->{uri}}->{elements};
    my $contents;
    foreach my $element (@$elements) {
	$contents .= $self->render($element);
    }
    $self->contents($contents);
}

sub render {
    my $self = shift;
    my $element = shift;
    if ($element->{type} eq 'html') {
	return $element->{html};
    }
    elsif ($element->{type} eq 'object') {
	my $object = $element->{object};
	my $method = $element->{method};
	return $object->$method($self->parse_args($element->{args_string}));
    }
}

sub contents {
    my $self = shift;
    if (@_) {
	$self->{contents} = shift;
    }
    return $self->{contents};
}

sub parse_args {
    my $self = shift;	
    my $args_string = shift;
    return $args_string unless $args_string =~ m{=};
    my $p = HTML::TokeParser->new(\"<p $args_string>") || return {};
    my $token = $p->get_token;
    return $token->[2];
}

sub version {
    my $self = shift;
    return $self->{version};
}

sub uri_to_short {
    my $self = shift;
    my $uri = shift;
    return $Pages_Ref{$uri}->{short}
}

sub short_to_uri {
    my $self = shift;
    my $short = shift;
    return $Short_Map{$short};
}

sub init {
    my $pages_file = "$ENV{SRCTOP}/$ENV{PROJECT}/pages.ref";
    open(PAGES, $pages_file) or die "Unable to open pages file: $!";
    while(<PAGES>) {
	my $line = $_;
	my ($uri, $local_location, $param_keys, $version, $skip_load_user, $short) = 
	    map { 
		my $tmp = $_; 
		$tmp =~ s{\s}{}gis; 
		$tmp; 
	    } 
	    split(/\|/, $line);
	my @params = split(/\//, $param_keys);
	if ($uri and $local_location) {
	    $Pages_Ref{$uri} = {
		uri => $uri,
		localLocation => $local_location,
		skipLoadUser => $skip_load_user,
		version => $version,
		params => \@params,
		short => $short,
	    };
	    $Short_Map{$short} = $uri;
	}
    }
    close(PAGES);
}

1;
