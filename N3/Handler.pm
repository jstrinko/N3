package N3::Handler;

use strict;

use FileHandle;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::RequestUtil;
use Apache2::Process;
use ModPerl::Util;
use Apache2::Const -compile => ':common';
use Compress::Zlib;
use JSON;
use N3;
use N3::Util;

our %Children;
my $Chunk_Size = 32768;
my %Mtimes = {};

sub handler {
    my $r = shift;
    my $request = N3->request($r);
    my $page = N3->page;
    $page->run;
    my $file = $request->pnotes('contents_from_file');
    my $type = $request->custom_param('content_type') || $page->content_type;
    $request->content_type($type);
    if ($file) {
	my $content_length = -s $file;
	my $fh = FileHandle->new($file);
	die "Non-existant file: $file" unless $fh;
	my $buf;
	my $sent = 0;
	while(read($fh, $buf, $Chunk_Size)) {
	    $request->print($buf);
	    $sent += $Chunk_Size;
	}
    }
    else {
	my $contents;
	if ($request->headers_in->{'Accept'} =~ m{(application/json|text/javascript)}si && $request->data) {
	    $contents = to_json($request->data);
	}
	else {
	    $contents = $page->contents;
	}
	if ($request->can_gzip) {
	    $request->content_encoding('gzip');
	    $contents = Compress::Zlib::memGzip($contents);
	}
	$request->headers_out->set('Content-Length', length($contents));
	$request->status(200) unless $request->status;
	
	$request->print($contents) unless $request->custom_param('headerOnly');
    }
    if ($request->status eq Apache2::Const::REDIRECT) {
	return Apache2::Const::REDIRECT;
    }
    else {
	return Apache2::Const::OK; 
    }
}

sub cleanup {
}

sub child_init {
    my ($pool, $s) = @_;
    warn "New Child $$";
}

sub child_exit {
    my ($pool, $s) = @_;
    warn "Dead Child $$";
}

sub reload_modules {
    my @files = grep { 
	$_ 
	} map { 
	    my $file = $INC{$_};
	    $file if substr($file, 0, length($ENV{SRCTOP})) eq $ENV{SRCTOP};
	} keys %INC;
    foreach my $file (@files) {
	if (is_stale($file)) {
	    warn "RELOADING $file";
	    my $contents = N3::Util::file_contents($file);
	    eval { $contents }
	}
    }
    if (is_stale(N3::Page::pages_file())) {
	warn "Pages file is stale - reloading";
	N3::Page::init();
    }
    my $page_files = N3::Page::files();
    foreach my $file (keys %$page_files) {
	if (is_stale($file)) {
	    warn "$file is stale, removing $page_files->{$file} from cache";
	    N3::Page::remove_cached_uri($page_files->{$file});
	}
    }
    return;
}

sub is_stale {
    my $file = shift;
    my $mtime = (stat $file)[9];
    $Mtimes{$file} = $mtime unless $Mtimes{$file};
    my $is_older = $mtime > $Mtimes{$file};
    $Mtimes{$file} = $mtime;
    return $is_older;
}

1;
