package N3::Handler;

use strict;

use FileHandle;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::RequestUtil;
use Apache2::Const -compile => ':common';

use Compress::Zlib;

use N3;

my $ChunkSize = 32768;

sub handler {
    my $r = shift;
    my $request = N3->request($r);
    my $page = N3->page;
    $page->run;
    my $file = $request->pnotes('contentsFromFile');
    my $type = $request->customParam('contentType') || 'text/html';
    $request->content_type($type);
    if ($file) {
	my $contentLength = -s $file;
	my $fh = FileHandle->new($file);
	die "Non-existant file: $file" unless $fh;
	my $buf;
	my $sent = 0;
	while(read($fh, $buf, $ChunkSize)) {
	    $request->print($buf);
	    $sent += $ChunkSize;
	}
    }
    else {
	my $contents = $page->contents;
	if ($request->canGzip) {
	    $request->content_encoding('gzip');
	    $contents = Compress::Zlib::memGzip($contents);
	}
	$request->headers_out->set('Content-Length', length($contents));
	$request->status(200) unless $request->status;
	$request->print($contents) unless $request->customParam('headerOnly');
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

1;
