package N3::WebRequest;

use strict;

use base 'N3::Request';
use base 'Apache2::Request';

use Apache2::Cookie;
use Apache2::Request;
use Apache2::Upload;

my $Upload_Hook = sub {
    return;
};

sub new {
    my $class = shift;
    my $req = shift;
    my $self = {
	r => Apache2::Request->new(
	    $req,
	    UPLOAD_HOOK => $Upload_Hook,
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

sub can_gzip {
    my $self = shift;
    return if $self->custom_param('dontGzip');
    my $accept_enc = $self->headers_in->get("Accept-Encoding");
    my $user_agent = $self->headers_in->get("User-Agent");
    if (
	index($accept_enc, "gzip") >= 0 or
	$user_agent =~ m{^Mozilla/\d+\.\d+[\s\[\]\w\-]+(\(X11|Mac.+PPC,\sNav)}
    ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
