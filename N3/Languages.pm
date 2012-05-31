package N3::Languages;

use strict;
use Exporter;
use base 'Exporter';

our @EXPORT = qw{str};

sub str {
    my $string = shift;
    my @params = @_;
    return sprintf($string, @params);
}

1;
