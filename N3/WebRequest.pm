package N3::WebRequest;

use strict;

use base 'N3::Request';
use base 'Apache2::Request';

use Apache2::Cookie;
use Apache2::Request;
use Apache2::Upload;

my $uploadHook = sub {
    return;
};

sub new {
    my $class = shift;
    my $req = shift;
    my $self = {
	r => Apache2::Request->new(
	    $req,
	    UPLOAD_HOOK => $uploadHook,
	    TEMP_DIR => "/$ENV{PROJECT}/tmp",
	),
    };

    my $cookies = Apache2::Cookie->fetch($req);
    foreach my $key (keys %$cookies) {
	my @value = $cookies->{$key}->value;
	$self->{cookies}{$key} = @value > 1 ? \@value : $value[0];
    }
    bless $self, $class;
    return $self;
}

sub canGzip {
    my $self = shift;
    return if $self->customParam('dontGzip');
    my $acceptEnc = $self->headers_in->get("Accept-Encoding");
    my $userAgent = $self->headers_in->get("User-Agent");
    if(index($acceptEnc, "gzip") >= 0 or
       $userAgent =~ m{^Mozilla/\d+\.\d+[\s\[\]\w\-]+(\(X11|Mac.+PPC,\sNav)})
    {
        return 1;
    }
    else {
        return 0;
    }
}

1;
