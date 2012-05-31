package N3::DB;

use strict;
use DBI;

sub dbQuery {
    my $self = shift;
    my $key = shift;
    my $sql = shift;
    my $params = shift;
    my $returnType = shift;
    my $dbh = $self->sqlDbHost($key);
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
    return $sth->fetchall_arrayref() if $returnType eq 'array';
    return $sth->fetchall_arrayref()->[0][0] if $returnType eq 'scalar';
    return $dbh->{mysql_insertid} if $returnType eq 'last_insert';
    return 1 if $returnType eq 'status';
    return unless $returnType;
    warn "Invalid returnType >$returnType<";
    return;
}

sub sqlDbHost {
    my $self = shift;
    my $key = shift;
    my $server = $ENV{"DB_SERVER_$key"};
    die "NO >ENV{DB_SERVER_$key}< defined." unless $server;
    my ($host, $db) = split(/:/, $server);
    my $dbi = "dbi:mysql:database=$db;host=$host";
    return $self->dbiConnect($dbi, { dbi_connect_method => 'connect' });
}

sub dbiConnect {
    my $self = shift;
    my $dbi = shift;
    my $extras = shift;
    my $dbh = undef;
    foreach(1..5) {
	$dbh = DBI->connect($dbi, $ENV{STRINKO_DB_USER}, $ENV{STRINKO_DB_PASSWD}, $extras);
	last if $dbh;
	warn "Failed to connect to >$dbi<...trying again in 1 sec";
	sleep 1;
    }
    die "Unable to connect to >$dbi<" if not $dbh;
    return $dbh;
}

1;
