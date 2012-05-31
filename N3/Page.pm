package N3::Page;

use strict;
use N3;
use N3::Util;
use HTML::TokeParser;
use Data::Dumper;

init();

my %PagesRef;
my %PagesCache;
my %ShortMap;

sub new {
    my $class = shift;
    my $uri = shift;
    my $self;
    if (!$PagesRef{$uri}) {
	my @parts = split(/\//, $uri);
	for(my $x = 0; $x < scalar @parts; $x++) {
	    my @tmpParts;
	    foreach my $y (1..$x) {
		push @tmpParts, $parts[$y];
	    }
	    my $tmpUri = "/" . join("/", @tmpParts);
	    if ($PagesRef{$tmpUri}) {
		$self = $PagesRef{$tmpUri};
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
        $self = $PagesRef{$uri};
    }

    return bless $self, $class;
}

sub run {
    my $self = shift;
    if (1 or !$PagesCache{$self->{uri}}) {
	my $addIndex = $self->{localLocation} =~ m{/$}gis ? "index" : "";
	my $fullLocation = $self->{localLocation} . $addIndex;
	my $base = "$ENV{SRCTOP}/$ENV{PROJECT}/htdocs$fullLocation";
	my $htmlFile = "$base.html";
	my $perlFile = "$base.pl";
	my $htmlContents;
	my $perlContents;
	if (-e $htmlFile) {
	    $htmlContents = N3::Util::fileContents($htmlFile);
	}
	if (-e $perlFile) {
	    $perlContents = N3::Util::fileContents($perlFile);
	}
	my @tmpElements;
	$fullLocation = "htdocs$fullLocation";
	my $nameSpaceString = $fullLocation;
	$nameSpaceString =~ s{\..*$}{}gis;
	$nameSpaceString =~ s{\-}{}gis;
	my $nameSpace = join("::", split(/\//, $nameSpaceString));
	my $firstLetterCapitalizedProject = uc(substr($ENV{PROJECT}, 0, 1)) . substr($ENV{PROJECT},1,length($ENV{PROJECT}) - 1);
	$perlContents = "package $nameSpace; use base '${firstLetterCapitalizedProject}::Template'; use strict; $perlContents 1;";
	my $pageObject = bless {}, $nameSpace;
	if ($htmlContents) {
	    eval $perlContents;
	    warn $@ if $@;
	    if ($pageObject->can('init')) {
		push @tmpElements, { 
		    type => 'object', 
		    object => $pageObject,
		    method => 'init',
		};
	    }
	    $htmlContents =~ s{\s+}{ }gis;
	    $htmlContents =~ s{^\s+}{}gis;
	    $htmlContents =~ s{\s+$}{}gis;
	    $htmlContents =~ s{>\s+<}{><}gis;
	    $htmlContents =~ s{<(\w+):\s*(.*?)>(?:(.*?)<:\1>)?}{$pageObject->$1($self->parseArgs($2), $3)}goe;
	    while($htmlContents =~ m{\G(.*?)(?:\$([a-zA-Z_]\w*)\.(\w+)(\(.*?\))?)}mcosg) {
		my $html = $1;
		push @tmpElements, {
		    type => 'html',
		    html => $html,
    		};
		if ($2) {
		    my ($objectName, $method, $args) = ($2, $3, $4);
		    $args =~ s{\(|\)}{}gis;
		    my $object;
		    if ($objectName eq 'self') {
			$object = $pageObject;
		    }
		    elsif ($objectName eq 'request') {
			$object = N3->request;
		    }
		    elsif ($objectName eq 'page') {
			$object = N3->page;
		    }
		    elsif ($objectName eq 'user') {
			$object = N3->user;
		    }
		    push @tmpElements, {
			type => 'object',
			object => $object,
			method => $method,
			argsString => $args,
		    };		    
		}
	    }
	    push @tmpElements, {
		type => 'html',
		html => substr($htmlContents, pos($htmlContents), length($htmlContents) - pos($htmlContents)),
	    };
	}
	elsif ($perlContents) {
	    eval $perlContents;
	    warn $@ if $@;
	    push @tmpElements, { 
		type => 'object', 
		object => $pageObject,
		method => 'init',
	    };
	}
	else {
	    N3->request->redirect('/error');
	}
	$PagesCache{$self->{uri}}->{elements} = \@tmpElements;
    }
    my @params = @{$self->{params}};
    if (scalar @params) {
	foreach my $x (0..scalar @params) {
	    N3->request->customParam($params[$x], $self->{'values'}->[$x]);
	}
    }
    my $elements = $PagesCache{$self->{uri}}->{elements};
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
	return $object->$method($self->parseArgs($element->{argsString}));
    }
}

sub contents {
    my $self = shift;
    if (@_) {
	$self->{contents} = shift;
    }
    return $self->{contents};
}

sub parseArgs {
    my $self = shift;	
    my $argsString = shift;
    return $argsString unless $argsString =~ m{=};
    my $p = HTML::TokeParser->new(\"<p $argsString>") || return {};
    my $token = $p->get_token;
    return $token->[2];
}

sub version {
    my $self = shift;
    return $self->{version};
}

sub uriToShort {
    my $self = shift;
    my $uri = shift;
    return $PagesRef{$uri}->{short}
}

sub shortToUri {
    my $self = shift;
    my $short = shift;
    return $ShortMap{$short};
}

sub init {
    my $pagesFile = "$ENV{SRCTOP}/$ENV{PROJECT}/pages.ref";
    open(PAGES, $pagesFile) or die "Unable to open pages file: $!";
    while(<PAGES>) {
	my $line = $_;
	my ($uri, $localLocation, $paramKeys, $version, $skipLoadUser, $short) = 
	    map { 
		my $tmp = $_; 
		$tmp =~ s{\s}{}gis; 
		$tmp; 
	    } 
	    split(/\|/, $line);
	my @params = split(/\//, $paramKeys);
	if ($uri and $localLocation) {
	    $PagesRef{$uri} = {
		uri => $uri,
		localLocation => $localLocation,
		skipLoadUser => $skipLoadUser,
		version => $version,
		params => \@params,
		short => $short,
	    };
	    $ShortMap{$short} = $uri;
	}
    }
    close(PAGES);
}

1;
