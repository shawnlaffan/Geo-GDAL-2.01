use strict;
use warnings;
use utf8;
use Scalar::Util 'blessed';  #  not used
use Encode qw(encode decode);
use Test::More tests => 13;
BEGIN { use_ok('Geo::GDAL') };

# test utf8 conversion in bindings

binmode STDERR, ":utf8"; # when debugging, we like to see the truth

my $fn = "__Äri"; # filename with a non-ascii character

touch ($fn); # touch it

my $e = -e $fn;
ok($e, "touch a file with non-ascii character"); # and it is there

# now use GDAL tools

my %files = map {$_=>1} Geo::GDAL::VSIF::ReadDir('./');

ok($files{$fn}, "Geo::GDAL::VSIF::ReadDir found file $fn")
or diag "Possible matches: " . join ' ', sort grep {/ri$/} keys %files;

eval {
    Geo::GDAL::VSIF::Unlink($fn);
};
diag $@ if $@;
$e = -e $fn;
ok(!$e, "file was deleted using Geo::GDAL::VSIF::Unlink");

# that works because the variable has utf8 flag set
ok(utf8::is_utf8($fn), "Perl knows it is utf8");

touch ($fn); # touch it again

$fn = "\xC4ri"; # same filename in Perl's internal format
ok(!utf8::is_utf8($fn), "Perl does not have utf8");

$e = -e $fn;
ok(!$e, "not there?");

$fn = encode("utf8", $fn); # convert from internal format to utf8
Encode::_utf8_on($fn); # yes, you have utf8 now
$e = -e $fn;
ok($e, "yes it is");

$fn = "\xC4ri"; # internal format, no utf8 flag
eval {
    Geo::GDAL::VSIF::Unlink($fn); # encoding is done in the bindings
};
$e = -e $fn;
ok(!$e, "encoding is done in the bindings");

my $fh = touch ("Äri"); # touch it again
%files = map {$_=>$_} Geo::GDAL::VSIF::ReadDir('./');
$fn = $files{'Äri'};
ok(utf8::is_utf8($fn), "utf8 flag is set in the bindings");

print {$fh} "Äri";
close $fh;
open $fh, '<', "Äri" or die "Cannot open file Äri";
$fn = <$fh>;
chomp($fn);
ok(!utf8::is_utf8($fn), "Perl does not know it has utf8");
eval {
    Geo::GDAL::VSIF::Unlink($fn);
};
ok($@, "decoding utf8 to utf8 is not a good idea");

Encode::_utf8_on($fn); # yes, you have utf8 now
eval {
    Geo::GDAL::VSIF::Unlink($fn);
};
diag $@ if $@;
$e = -e $fn;
ok(!$e, "show is over");


sub touch {
    my $fname = shift;
    open my $fh, '>>', $fname or die "Cannot open $fname";
    
    #  return the file handle if the caller wants it  
    return $fh if defined wantarray;
    #  otherwise close it
    close $fh;
    return;
}
