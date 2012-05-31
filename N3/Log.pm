package N3::Log;

use strict;

use N3::Util;

*CORE::GLOBAL::warn = sub {
    my $message = join("", @_);
    N3::Log::_log($message, 'WARN');
};

*CORE::GLOBAL::die = sub {
    my $message = join("", @_);
    N3::Log::_log($message, 'FATAL');
};

*CORE::GLOBAL::log = sub {
    my $level = shift;
    my $message = join("", @_);
    N3::Log::_log($message, $level);
};

sub _log {
    my ($message, $level) = @_;
    my $extra = N3::Util::stackTrace(3) unless $level eq 'WARN';
    print STDERR $message . $extra . "\n";
    if ($level == $level * 1 && $level != 0) {
	return CORE::log($level);
    }
}

1;
