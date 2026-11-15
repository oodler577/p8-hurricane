#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Fixtures qw(cases);
use File::Path qw(make_path);
make_path('build');
open my $out,'>','build/expected.p8' or die $!;
sub array {
    my ($type,$name,@values)=@_;
    print {$out} "    $type\[\] $name = [",join(',',@values),"]\n";
}
print {$out} "; Generated independently by Perl; never edit by hand.\nexpected {\n";
my @cases=cases();
array('ubyte','valid',map { $_->[2] } @cases);
array('ubyte','counts',map { $_->[3] } @cases);
my @bits=(0)x76;
for my $year (1800..2400) {
    my $leap=($year%400==0 || ($year%4==0 && $year%100!=0));
    $bits[int(($year-1800)/8)]|=1<<(($year-1800)%8) if $leap;
}
array('ubyte','leap_bits',@bits);
my (@west,@north,@lat,@lon,@miles);
my $state=0xc641;
my $random=sub { $state=(1664525*$state+1013904223)%4294967296;return $state; };
my $pi=4*atan2(1,1);
for my $i (0..47) {
    my $w=450+$random->()%651;my $n=50+$random->()%401;
    my $clat=5+($random->()%4000)/100;
    my $clon=45+($random->()%6500)/100;
    my $slat=$n/10*$pi/180;
    my $rclat=$clat*$pi/180;
    my $a=sin(($rclat-$slat)/2)**2 + cos($slat)*cos($rclat)*sin(($clon-$w/10)*$pi/360)**2;
    my $distance=6880.13*atan2(sqrt($a),sqrt(1-$a));
    push @west,$w;push @north,$n;
    push @lat,sprintf('%.2f',$clat);push @lon,sprintf('%.2f',$clon);
    push @miles,int($distance+0.5);
}
array('uword','west',@west);array('uword','north',@north);
array('float','city_lat',@lat);array('float','city_west',@lon);
array('uword','miles',@miles);
print {$out} "}\n";
close $out or die $!;
