package N3::User;

use strict;
use base 'N3::Savable';

use File::Path;

sub new {
    my $class = shift;
    my $request = shift;
    my $tmp = {
	isAnonymous => 1,
    };
    return bless $tmp, $class;
}

sub load_user {
    my $class = shift;
    my $id = shift;
    my $tmp = {
	id => $id,
    };
    bless $tmp, $class;
    my $self = $tmp->load;
    return $self if $self->loaded;
    return;
}

sub viewing_user {
    my $class = shift;
    return $class->new;
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}

sub numeric_id {
    my $self = shift;
    $self->{numeric_id} = shift if @_;
    return $self->{numeric_id};
}

sub password {
    my $self = shift;
    $self->{password} = shift if @_;
    return $self->{password};
}

sub is_anonymous {
    my $self = shift;
    $self->{is_anonymous} = shift if @_;
    return $self->{is_anonymous};
}

sub is_named {
    my $self = shift;
    return !$self->is_anonymous;
}

sub user_filename {
    my $user_id = shift;
    my $filename = shift;
    while (length "$user_id" < 4) {
	$user_id = "_" . $user_id;
    }
    my ($firsttwo, $secondtwo) = $user_id =~ m{^(..)(..)}si;
    my $fullpath = "$ENV{USERTOP}/" . bucket($user_id) . "/$firsttwo/$secondtwo/$user_id/$filename";
    my ($dirpath) = $fullpath =~ m{^(.*)/}si;
    mkpath($dirpath) unless -d $dirpath;
    return $fullpath;
}

sub bucket {
    my $string = shift; 
    my $count = 0;
    $string =~ s{(.)}{$count += ord($1) + 1234}goes;
    return $count % 2000;
}

sub filename {
    my $self = shift;
    return user_filename($self->id, "userdata.sto");
}

1;
