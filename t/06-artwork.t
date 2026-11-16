#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON::PP;
sub bytes { open my $f,'<:raw',$_[0] or die $!;local $/;return <$f>; }
my $manifest=decode_json(bytes('data/artwork/provenance.json'));
is($manifest->{original_title},"Skipper Jim's Hurricane Tracking Chart",'original artwork title recorded');
is($manifest->{original_author},'James R. Brown','original artwork author recorded');
for my $part (['bitmap',8000],['matrix',1000]) {
    my ($name,$size)=@$part;
    my $encoded=bytes("data/artwork/map-$name.rle");
    my $raw='';my $i=0;
    while ($i<length($encoded)) {
        my $token=ord(substr($encoded,$i++,1));
        next if $token==128;
        if ($token<128) {
            my $count=$token+1;
            die 'truncated literal' if $i+$count>length($encoded);
            $raw.=substr($encoded,$i,$count);$i+=$count;
        } else {
            die 'truncated repeat' if $i>=length($encoded);
            $raw.=substr($encoded,$i++,1)x(257-$token);
        }
        die 'artwork overrun' if length($raw)>$size;
    }
    is(length($raw),$size,"$name expands to exact C64 region");
    is(sha256_hex($raw),$manifest->{"${name}_sha256"},"$name reproduces recorded artwork bytes");
}
done_testing();
