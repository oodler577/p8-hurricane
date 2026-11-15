#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Copy qw(copy);
use lib 't/lib';
use HurricaneTest qw(require_emulator run_emulator);
my $temp=require_emulator();
copy('data/HF.GILBERT',"$temp/hf.gilbert") or die $!;
open my $bad,'>:raw',"$temp/hf.bad" or die $!;
print {$bad} "07 PM 09 10 1988\r80\r66.5\r15.7\r0\r";
close $bad;
my @names=(
    'valid legacy timestamp','leap day in 2000','reject leap day in 1900',
    'reject hour zero','reject April 31','reject bad AM/PM',
    'accept trailing zero precision','decimal coordinate in tenths',
    'reject unsupported nonzero precision','reject negative coordinate',
    'reject numeric overflow','reject numeric junk','reject excessive wind',
    'reject longitude outside map','add an observation','count and dirty flag',
    'load original Gilbert file','19 records and clean flag','first Gilbert observation',
    'last Gilbert observation','last Gilbert timestamp','save new sequential file',
    'reload saved sequential file','roundtrip preserves track','refuse overwrite',
    'reject missing END sentinel','clear incomplete import','fill 128 observations',
    'reject observation 129','Gilbert first fix to Houston: 1800 nm',
    'Gilbert last fix to Brownsville: 134 nm','coincident coordinates: zero distance'
);
my $ram=run_emulator('runtime');
is(ord(substr($ram,0x2fe,1)),0xa5,'runtime completion marker');
is(ord(substr($ram,0x2fc,1)),scalar @names,'expected runtime assertion count');
for my $i (0..$#names) { ok(ord(substr($ram,0xc801+$i,1)),$names[$i]); }
diag('distance results: '.join(', ',unpack('v3',substr($ram,0xc980,6)))) if ord(substr($ram,0x2fd,1));
is(ord(substr($ram,0x2fd,1)),0,'no runtime failures');
$ram=run_emulator('render');
is(ord(substr($ram,0x2fe,1)),0xa5,'Gilbert map rendered');
is(ord(substr($ram,0xd011,1)) & 0x20,0x20,'bitmap mode enabled');
ok(substr($ram,0x6000,8000) ne "\0"x8000,'nonempty bitmap');
# Verify the actual ROM glyphs in the rendered observation panel.
my $timestamp='11 AM 09 16 1988';
for my $i (0..length($timestamp)-1) {
    my $code=ord(substr($timestamp,$i,1));
    $code-=64 if $code>=64 && $code<=95;
    is(substr($ram,0x6000+22*320+$i*8,8),substr($ram,0xc000+$code*8,8),"timestamp glyph $i");
}
if ($ENV{RENDER_RAM}) {
    open my $out,'>:raw',$ENV{RENDER_RAM} or die $!;
    print {$out} $ram;
}
done_testing();
