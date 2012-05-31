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

sub loadUser {
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

sub viewingUser {
    my $class = shift;
    return $class->new;
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}

sub numericId {
    my $self = shift;
    $self->{numericId} = shift if @_;
    return $self->{numericId};
}

sub password {
    my $self = shift;
    $self->{password} = shift if @_;
    return $self->{password};
}

sub isAnonymous {
    my $self = shift;
    $self->{isAnonymous} = shift if @_;
    return $self->{isAnonymous};
}

sub isNamed {
    my $self = shift;
    return !$self->isAnonymous;
}

sub userFilename {
    my $userId = shift;
    my $filename = shift;
    while (length "$userId" < 4) {
	$userId = "_" . $userId;
    }
    my ($firsttwo, $secondtwo) = $userId =~ m{^(..)(..)}si;
    my $fullpath = "$ENV{USERTOP}/" . bucket($userId) . "/$firsttwo/$secondtwo/$userId/$filename";
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
    return userFilename($self->id, "userdata.sto");
}

1;
