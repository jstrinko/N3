package N3::Replace;

use strict;

sub find_replaceable_words {
    my $string = shift;
    my $words = {};
    while ($string =~ m{(__.+?__)}gis) {
	my $word = $1;
	$word =~ s{__}{}g;
	$words->{$1}++;
    }
    return $words;
}

sub replace_words {
    my $string = shift;
    my $replacements = shift;
    my $padded = {};
    map { $padded->{'__' . $_ . '__'} = $replacements->{$_} } keys %{$replacements};
    $string =~ s/(__.+?__)/$padded->{$1}/g;
    return $string;
}

1;
