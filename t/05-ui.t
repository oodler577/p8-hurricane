#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Copy qw(copy);
use lib 't/lib';
use HurricaneTest qw(require_emulator run_emulator);
my $temp=require_emulator();
copy('data/HF.GILBERT',"$temp/hf.gilbert") or die $!;
my $ram=run_emulator('main',commands=>sub {
    my ($symbols)=@_;
    my $entry=$symbols->{'.prog8_entrypoint'} // die 'entry missing';
    my $wait=$symbols->{'.txt:waitkey'} // die 'waitkey missing';
    my $draw=$symbols->{'.p8b_chart:p8s_draw'} // die 'chart draw missing';
    # Reach the real menu, type the load command and filename, then open the map.
    return "break $wait\ng $entry\ndelete\nkeybuf \"lhf.gilbert\\nv\"\nbreak $draw\ng\ndelete\nbreak $wait\ng\n";
});
is(ord(substr($ram,0xd011,1)) & 0x20,0x20,'real application loads a file and opens the bitmap through keyboard input');
my $timestamp='07 PM 09 10 1988';
for my $i (0..length($timestamp)-1) {
    my $code=ord(substr($timestamp,$i,1));
    $code-=64 if $code>=64 && $code<=95;
    is(substr($ram,0x6000+22*320+$i*8,8),substr($ram,0xc000+$code*8,8),"loaded first observation glyph $i");
}
done_testing();
