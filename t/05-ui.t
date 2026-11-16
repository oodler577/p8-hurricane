#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Copy qw(copy);
use lib 't/lib';
use HurricaneTest qw(require_emulator run_emulator);
my $temp=require_emulator();
copy('data/HF.GILBERT',"$temp/hf.gilbert") or die $!;
my $menu=run_emulator('main',commands=>sub {
    my ($symbols)=@_;
    my $entry=$symbols->{'.prog8_entrypoint'} // die 'entry missing';
    my $wait=$symbols->{'.txt:waitkey'} // die 'waitkey missing';
    my $menu=$symbols->{'.p8b_main:p8s_menu'} // die 'menu missing';
    return "break $menu\nkeybuf \" \"\ng $entry\ndelete\nbreak $wait\ng\n";
});
my $screen=substr($menu,0x0400,1000);
$screen=join('',map { my $c=$_ & 127;$c<32 ? chr($c+64) : chr($c) } unpack('C*',$screen));
like($screen,qr/SKIPPER JIM'S HURRICANE TRACKING CHART/,'full original title visible in real application menu');
like($screen,qr/BY JAMES R\. BROWN/,'original author visible in real application menu');
like($screen,qr/BASED ON THE ORIGINAL C64 PROGRAM:/,'origin clearly identified');
my $ram=run_emulator('main',commands=>sub {
    my ($symbols)=@_;
    my $entry=$symbols->{'.prog8_entrypoint'} // die 'entry missing';
    my $wait=$symbols->{'.txt:waitkey'} // die 'waitkey missing';
    my $menu=$symbols->{'.p8b_main:p8s_menu'} // die 'menu missing';
    my $draw=$symbols->{'.p8b_chart:p8s_draw'} // die 'chart draw missing';
    # Reach the real menu, type the load command and filename, then open the map.
    return "break $menu\nkeybuf \" \"\ng $entry\ndelete\nbreak $wait\ng\ndelete\nkeybuf \"lhf.gilbert\\nv\"\nbreak $draw\ng\ndelete\nbreak $wait\ng\n";
});
is(ord(substr($ram,0xd011,1)) & 0x20,0x20,'real application loads a file and opens the bitmap through keyboard input');
my $timestamp='07 PM 09 10 1988';
for my $i (0..length($timestamp)-1) {
    my $code=ord(substr($timestamp,$i,1));
    $code-=64 if $code>=64 && $code<=95;
    is(substr($ram,0x6000+23*320+5*8+$i*8,8),substr($ram,0xc000+$code*8,8),"loaded first observation glyph $i");
}
done_testing();
