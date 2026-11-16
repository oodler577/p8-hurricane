#!/usr/bin/env perl
use strict;
use warnings;
use File::Path qw(make_path);
use File::Copy qw(copy);
use Cwd qw(abs_path);
my $video=$ENV{VICE_VIDEO}//'pal';
die 'VICE_VIDEO must be pal or ntsc' unless $video =~ /\A(?:pal|ntsc)\z/;
for my $key (qw(VICE VICE_DATA_DIR VICE_KERNAL VICE_BASIC VICE_CHARGEN)) {
    die "missing $key\n" unless $ENV{$key};
}
make_path(q(docs/screenshots),q(build/screenshots/disk));
copy(q(data/HF.GILBERT),q(build/screenshots/disk/hf.gilbert)) or die $!;
for my $stem (qw(title render)) {
    open my $f,'<',"build/$stem.vice-mon-list" or die "build --tests first: $!";
    my ($entry,$done);
    while (<$f>) {
        $entry=$1 if /^al (\w+) \.prog8_entrypoint$/;
        $done=$1 if /^al (\w+) \.p8b_main:p8s_start:p8l_finished$/;
    }
    die 'missing capture checkpoints' unless $entry && $done;
    my $program=abs_path("build/$stem.prg");
    my $name=$stem eq 'render' ? 'chart' : 'title';
    my $image=abs_path('docs/screenshots')."/$name-$video.png";
    my $mon=abs_path('build/screenshots')."/$name-$video.mon";
    open my $out,'>',$mon or die $!;
    print {$out} "break a474\ng\ndelete\nload \"$program\" 0\nbreak $done\ng $entry\ndelete\nstep 30000\nsave \"$image.ram\" 0 0000 ffff\nquit\n";
    close $out;
    my @args=('timeout',60,'xvfb-run','-a',$ENV{VICE},'-directory',$ENV{VICE_DATA_DIR},
        '-kernal',$ENV{VICE_KERNAL},'-basic',$ENV{VICE_BASIC},'-chargen',$ENV{VICE_CHARGEN},
        '+sound','+drive8truedrive','-virtualdev8','-iecdevice8','-device8',1,
        '-fs8',abs_path(q(build/screenshots/disk)),'-warp',$video eq 'ntsc' ? '-ntsc' : '-pal',
        '-limitcycles',100000000,'-refreshonbreak','-moncommands',$mon,'-exitscreenshot',$image);
    my $pid=fork();die $! unless defined $pid;
    if (!$pid) {
        open STDOUT,'>',"build/screenshots/$name-$video.log" or die $!;
        open STDERR,'>&',\*STDOUT or die $!;
        exec @args;die $!;
    }
    waitpid($pid,0);
    die "capture failed ($?): build/screenshots/$name-$video.log\n" if $? || !-s $image;
    open my $ram, q(<:raw), "$image.ram" or die $!;
    local $/;my $memory=<$ram>;
    die q(capture fixture failed to load or render) unless length($memory)==65538 && ord(substr($memory,2+0x2fe,1))==0xa5;
    print "$image\n";
}
