package N3;

use strict;

use Exporter;
our @ISA = qw{Exporter};
our @EXPORT = qw{error fatal};
use N3::Log;
use N3::ShellRequest;
use N3::WebRequest;

our $Request;
our $Page;
our $User;

sub request {
    my $class = shift;
    if (@_) {
	my $req = shift;
	if (ref $req eq 'HASH') {
	    warn "REF IS " . ref $req;
	    $Request = N3::ShellRequest->new({@_});
	}
	elsif (ref $req and $req->isa('N3::Request')) {
	    $Request = $req;
	}
	elsif (ref $req and $req->isa('Apache2::RequestRec')) {
	    $Request = N3::WebRequest->new($req);
	}
	else {
	    warn "REF IS " . ref $req;
	    $Request = N3::ShellRequest->new($req);
	}
	my $uri = $Request->uri;
	if ($uri) {
	    $Request->set_page;
	}
	else {
	    die "No URI: $uri";
	}
    }
    return $Request;
}

sub page {
    my $class = shift;
    if (@_) {
	$Page = shift;
	die "Type Mismatch - not a N3::Page: $Page" unless $Page->isa('N3::Page');
    }
    return $Page;
}

sub user {
    my $class = shift;
    if (@_) {
	$User = shift;
	die "Type Mismatch - not a N3::User: $User" unless $User->isa('N3::User');
    }
    unless ($Request->pnotes('hasSetUser')) {
	my $key = $Request->key;
	my $class = $key . "::User";
	eval "use $class";
	warn "Eval error when calling $class: $@" if $@;
	$User = $class->viewing_user();
	$Request->pnotes('hasSetUser', 1);
    }
    return $User;
}

sub error (@) {
    my $message = join("", @_);
    N3::Log::_log($message, 'ERROR');
}

sub fatal (@) {
    my $message = join("", @_);
    N3::Log::_log($message, 'FATAL');
}



1;
