package N3::ShellRequest;

use strict;

use base 'N3::Request';

sub new {
    my $class = shift;
    my $req = shift;
    my $self = {
	r => $req,
    };
    return bless $self, $class;
}

sub uri {
    my $self = shift;
    if (@_) {
	$self->{uri} = shift;
    }
    return $self->{uri};
}

sub send_http_header {
    return;
}

sub pnotes {
    my $self = shift;
    my $key = shift;
    $self->{pnotes}->{$key} = shift if @_;
    return $self->{pnotes}->{$key};
}

1;
