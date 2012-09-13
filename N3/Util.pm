package N3::Util;

use Crypt::CBC;
use MIME::Base64 ();

our $Cipher_Key = $ENV{ENCRYPTION_KEY};

sub file_contents {
    my $file = shift;
    open(my $fh, '<:utf8', $file) or return;
    my $buffer;
    read($fh, $buffer, -s $file);
    return $buffer;
}

sub stack_trace {
    my $skip = shift || 1;
    my $trace;
    my $i = $skip;
    while (my ($pack, $file, $line, $subname, $ha, $wa) = caller($i++)) {
	$trace .= ($wa ? '@ = ' : '$ = ') . "$pack::$subname called from $file:$line\n";
    }
    return $trace;
}

sub is_valid_email {
    my $email = shift;
    return $email =~ m{^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$}si;
}

sub encrypt {
    my ($junk, $string) = @_;
    $string .= "XXXXXXXX" if length $string < 8;
    my $encrypted;
    my $cipher = Crypt::CBC->new(
	-key => $Cipher_Key, 
	-cipher => 'Blowfish',
	-salt => 1,
	-header => 'salt',
    );
    $encrypted = $cipher->encrypt($string);
    my $encoded = MIME::Base64::encode($encrypted, '');
    $encoded =~ s/\//-/g;
    $encoded =~ s/\+/./g;
    return $encoded;
}

sub decrypt {
    my ($junk, $string) = @_;
    $string =~ s/,/\//g;
    $string =~ s/-/\//g;
    $string =~ s/\./+/g;
    my $decoded = MIME::Base64::decode($string);
    my $plaintext;
    my $cipher = Crypt::CBC->new(
	-key => $Cipher_Key, 
	-cipher => 'Blowfish',
	-salt => 1,
	-header => 'salt',
    );
    $plaintext = $cipher->decrypt($decoded);
    $plaintext =~ s/XXXXXXXX$//;
    return $plaintext;
}

1;
