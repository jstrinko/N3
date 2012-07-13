package N3::Request;

use strict;

use N3;
use N3::Page;
use N3::User;
use N3::Montage;
use Apache2::Const -compile => qw(REDIRECT);

sub set_page {
    my $self = shift;
    my $page = N3::Page->new($self->uri);
    N3->page($page);
}

sub setUser {
    my $self = shift;
    my $key = $self->key;
    my $class = $key . "::User";
    eval "use $class;";
    warn "Eval error when calling $class: $@" if $@;
    my $user = $class->viewing_user();
    N3->user($user);
}

sub key {
    my $self = shift;
    unless ($self->{key}) {
	my $project = $ENV{PROJECT};
	my $length = length $project;
	$self->{key} = uc(substr($project, 0, 1)) . lc(substr($project, 1, ($length - 1)));
    }
    return $self->{key};
}

sub lang {
    my $self = shift;
    return 'en';
}

sub cookie {
    my $self = shift;
    my $name = shift;
    $self->{cookies}{$name} = shift if @_;
    return $self->{cookies}{$name};
}

sub customParam {
    my $self = shift;
    my $name = shift;
    if (@_) {
        $self->{custom_params}->{$name} = shift;
    }
    return $self->{custom_params}->{$name}
}

sub redirect {
    my $self = shift;
    my $location = shift;
    $self->headers_out->set(Location => $location);
    $self->status(Apache2::Const::REDIRECT);
}

1;
