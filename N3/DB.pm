package N3::DB;

use strict;
use DBI;

sub db_query {
    my $self = shift;
    my $key = shift;
    my $sql = shift;
    my $params = shift;
    my $return_type = shift;
    my $dbh = $self->sql_db_host($key);
    my $sth = $dbh->prepare($sql) || die DBI->errstr;
    unless ($sth->execute(@$params)) {
	die "Failed to execute: $key: $sql\nError is: " . DBI->errstr;
    }
    if ($returnType eq 'hash') {
	my $ret = [];
	while (my $ref = $sth->fetchrow_hashref) {
	    push @$ret, $ref;
	}
	return $ret;
    }
    return $sth->fetchall_arrayref() if $return_type eq 'array';
    return $sth->fetchall_arrayref()->[0][0] if $return_type eq 'scalar';
    return $dbh->{mysql_insertid} if $return_type eq 'last_insert';
    return 1 if $return_type eq 'status';
    return unless $return_type;
    warn "Invalid returnType >$return_type<";
    return;
}

sub sql_db_host {
    my $self = shift;
    my $key = shift;
    my $server = $ENV{"DB_SERVER_$key"};
    die "NO >ENV{DB_SERVER_$key}< defined." unless $server;
    my ($host, $db) = split(/:/, $server);
    my $dbi = "dbi:mysql:database=$db;host=$host";
    return $self->dbi_connect($dbi, { dbi_connect_method => 'connect' });
}

sub dbi_connect {
    my $self = shift;
    my $dbi = shift;
    my $extras = shift;
    my $dbh = undef;
    foreach(1..5) {
	$dbh = DBI->connect($dbi, $ENV{DB_USER}, $ENV{DB_PASSWD}, $extras);
	last if $dbh;
	warn "Failed to connect to >$dbi<...trying again in 1 sec";
	sleep 1;
    }
    die "Unable to connect to >$dbi<" if not $dbh;
    return $dbh;
}

1;
