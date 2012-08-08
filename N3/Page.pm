package N3::Page;

use strict;
use N3;
use N3::Util;
use HTML::TokeParser;
use JSON;

init();

my %Pages_Ref;
my %Pages_Cache;
my %Content_Type_Map = (
    html => 'text/html',
    javascript => 'text/javascript',
    css => 'text/css',
    json => 'application/json',
);

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
	    if ($Pages_Ref{$tmp_uri}) {
		$self = $Pages_Ref{$tmp_uri};
		my @values;
		foreach my $y (($x+1)..scalar @parts) {
		    push @values, $parts[$y];
		}
		my @params = $self->{params} ? @{$self->{params}} : ();
		if (scalar @values <= scalar @params) {
		    $self->{'values'} = \@values;
		}
		else {
		    die "Page does not exist: $uri";
		}
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
	if ($self->{type} eq 'collection') {
	    $Pages_Cache{$self->{uri}}->{elements} = $self->build_collection;
	}
	else {
	    $Pages_Cache{$self->{uri}}->{elements} = $self->build_page;
	}
    }
    my @params = $self->{params} ? @{$self->{params}} : ();
    my @values = $self->{values} ? @{$self->{values}} : ();
    die "Invalid page!" if scalar @values > scalar @params;
    if (scalar @params) {
	foreach my $x (0..scalar @params) {
	    N3->request->custom_param($params[$x], $self->{'values'}->[$x]);
	}
    }
    my $elements = $Pages_Cache{$self->{uri}}->{elements};
    my $contents;
    foreach my $element (@$elements) {
	$contents .= $self->render($element);
    }
    $self->contents($contents);
}

sub type {
    my $self = shift;
    $self->{type} = shift if @_;
    $self->{type} ||= 'page';
    return $self->{type};
}

sub subtype {
    my $self = shift;
    $self->{subtype} = shift if @_;
    $self->{subtype} ||= 'html';
    return $self->{subtype};
}

sub content_type {
    my $self = shift;
    $self->{content_type} = shift if @_;
    return $self->{content_type} || $Content_Type_Map{$self->subtype};
}

sub build_collection {
    my $self = shift;
    my @tmp_elements;
    my $html_content;
    my @jst_elements;
    my @files = $self->expand_collection_files;
    for my $file (@files) {
	my $contents = N3::Util::file_contents($file);
	my $name_space = $self->name_space_from_location($file);
	my $page_object = bless {}, $name_space;
	my $perl_contents = $self->package_perl_content("", $name_space);
	push @tmp_elements, $self->run_perl_content($page_object, $perl_contents);
	if ($self->{subtype} eq 'javascript') {
	    if ($file =~ m{\.jst$}i) {
		push @jst_elements, $self->create_jst_element($contents, $file);
	    }
	    elsif ($file =~ m{\.js$}i) {
		push @tmp_elements, $self->run_html_content($page_object, $contents, 1);
	    }
	}
	elsif ($self->{subtype} eq 'css') {
	    push @tmp_elements, $self->run_html_content($page_object, $contents, 1);
	}
	else {
	    push @tmp_elements, $self->run_html_content($page_object, $contents);
	}
    }
    if (@jst_elements) {
	push @tmp_elements, {
	    type => 'html',
	    html => "(function() { window.JST = window.JST || {}; " . join("\n", @jst_elements) ." });",
	};
    }
    return wantarray ? @tmp_elements : \@tmp_elements;
}

sub create_jst_element {
    my $self = shift;
    my $content = shift;
    my $file = shift;
    $content =~ s{'}{\\'}g;
    $content =~ s{\n}{\\n}g;
    my $short = $self->relative_file_location($file);
    return "window.JST['$short'] = _.template('$content');";
}

sub expand_collection_files {
    my $self = shift;
    my $base = "$ENV{SRCTOP}/$ENV{PROJECT}/htdocs";
    my @files;
    foreach my $file (@{$self->{collection}}) {
	my $full_path = $base . $file;
	my @tmp_files = glob $full_path;
	push @files, @tmp_files;
    }
    return wantarray ? @files : \@files;
}

sub run_html_content {
    my $self = shift;
    my $page_object = shift;
    my $html_contents = shift;
    my $no_runtime_scripts = shift;
    my @tmp_elements;
#    $html_contents =~ s{\s+}{ }gis;
#    $html_contents =~ s{^\s+}{}gis;
#    $html_contents =~ s{\s+$}{}gis;
#    $html_contents =~ s{>\s+<}{><}gis;
    $html_contents =~ s{<(\w+):\s*(.*?)>(?:(.*?)<:\1>)?}{$page_object->$1($self->parse_args($2), $3)}goe;
    if ($no_runtime_scripts) {
	push @tmp_elements, {
	    type => 'html',
	    html => $html_contents
	};
    }
    else {
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
    return wantarray ? @tmp_elements : \@tmp_elements;
}

sub run_perl_content {
    my $self = shift;
    my $page_object = shift;
    my $perl_contents = shift;
    eval $perl_contents;
    warn $@ if $@;
    my @tmp_elements;
    if ($page_object->can('init')) {
	push @tmp_elements, { 
	    type => 'object', 
	    object => $page_object,
	    method => 'init',
	};
    }
    return wantarray ? @tmp_elements : \@tmp_elements;
}

sub relative_file_location {
    my $self = shift;
    my $full_location = shift;
    my $short = $full_location;
    $short =~ s{.*(htdocs.*?$)}{$1};
    $short =~ s{\..*$}{}gis;
    $short =~ s{\-}{}gis;
    return $short;
}

sub name_space_from_location {
    my $self = shift;
    my $full_location = shift;
    return join("::", split(/\//, $self->relative_file_location($full_location)));
}

sub package_perl_content {
    my $self = shift;
    my $perl_contents = shift;
    my $name_space = shift;
    my $first_letter_capitalized_project = ucfirst($ENV{PROJECT});
    return "package $name_space; use base '${first_letter_capitalized_project}::Template'; use strict; $perl_contents 1;";
}

sub build_page {
    my $self = shift;
    my $add_index = $self->{local} =~ m{/$}gis ? "index" : "";
    my $full_location = $self->{local} . $add_index;
    my $base = "$ENV{SRCTOP}/$ENV{PROJECT}/htdocs$full_location";
    my $html_file = "$base.html";
    my $perl_file = "$base.pl";
    my $html_contents;
    my $perl_contents;
    if (-e $html_file) {
	$html_contents = N3::Util::file_contents($html_file);
    }
    if (-e $perl_file) {
	$perl_contents = N3::Util::file_contents($perl_file);
    }
    my @tmp_elements;
    my $name_space = $self->name_space_from_location($perl_file);
    my $page_object = bless {}, $name_space;
    $perl_contents = $self->package_perl_content($perl_contents, $name_space);
    push @tmp_elements, $self->run_perl_content($page_object, $perl_contents);
    push @tmp_elements, $self->run_html_content($page_object, $html_contents);
    N3->request->redirect('/error') unless @tmp_elements;
    return wantarray ? @tmp_elements : \@tmp_elements;
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

sub init {
    my $pages_file = "$ENV{SRCTOP}/$ENV{PROJECT}/pages.json";
    my $content = N3::Util::file_contents($pages_file);
    my $json = from_json($content);
    foreach my $data (@$json) {
	$Pages_Ref{$data->{uri}} = $data;
    }
}

1;
