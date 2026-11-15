package HurricaneTest;
use strict;
use warnings;
use Exporter 'import';
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Copy qw(copy);
use Cwd qw(abs_path);
our @EXPORT_OK = qw(require_emulator run_emulator fixture_dir);
my $root;
my $runs=0;

sub require_emulator {
    BAIL_OUT(q(invalid VICE_VIDEO)) unless ($ENV{VICE_VIDEO}//q(pal)) =~ /\A(?:pal|ntsc)\z/;
    BAIL_OUT(q(invalid VICE_DRIVE)) unless ($ENV{VICE_DRIVE}//q(filesystem)) =~ /\A(?:filesystem|1541)\z/;
    for my $key (qw(VICE VICE_DATA_DIR VICE_KERNAL VICE_BASIC VICE_CHARGEN)) {
        next if $ENV{$key} && (-e $ENV{$key});
        BAIL_OUT("required emulator prerequisite missing: $key") if $ENV{REQUIRE_EMULATOR};
        plan skip_all => "set $key to run compiled C64 tests";
    }
    if (($ENV{VICE_DRIVE} // 'filesystem') eq '1541') {
        BAIL_OUT('real 1541 testing requires VICE_DOS1541II') unless -f ($ENV{VICE_DOS1541II}//'');
    }
    $root=tempdir(CLEANUP => !$ENV{KEEP_EMULATOR_FILES});
    return $root;
}

sub fixture_dir { return $root // die 'call require_emulator first'; }

sub run_emulator {
    my ($stem,%opt)=@_;
    my $program=abs_path("build/$stem.prg");
    BAIL_OUT("build $stem first") unless $program;
    open my $symbols,'<',"build/$stem.vice-mon-list" or BAIL_OUT("symbols for $stem: $!");
    my ($entry,$done);
    my %labels;
    while (<$symbols>) {
        $labels{$2}=$1 if /^al (\w+) (\S+)/;
        $entry=$1 if /^al (\w+) \.prog8_entrypoint$/;
        $done=$1 if /^al (\w+) \.p8b_main:p8s_start:p8l_finished$/;
    }
    BAIL_OUT("entry/completion symbols missing for $stem") unless $entry && ($done || $opt{commands});
    my $dir="$root/run-".++$runs."-$stem";
    make_path($dir);
    my $disk="$dir/test.d64";
    if (($ENV{VICE_DRIVE}//'filesystem') eq '1541' && !$opt{commands}) {
        opendir my $dh,$root or die $!;
        my @files=sort grep { -f "$root/$_" && /^hf\./ } readdir $dh;
        closedir $dh;
        @files=grep { $_ ne 'hf.gilbert' } @files;
        my @args=map { uc($_).'='.$root.'/'.$_ } @files;
        system($^X,'tools/disk.pl',$disk,$program,'data/HF.GILBERT',@args)==0 or BAIL_OUT('test disk build failed');
    }
    open my $mon,'>',"$dir/commands.mon" or die $!;
    print {$mon} "break a474\ng\ndelete 1\nload \"$program\" 0\n";
    if ($opt{commands}) {
        my $commands=$opt{commands}->(\%labels);
        print {$mon} $commands;
    } else {
        print {$mon} "break $done\ng $entry\n";
    }
    print {$mon} "save \"$dir/memory.prg\" 0 0000 ffff\nquit\n";
    close $mon;
    my @args=($ENV{VICE},'-console','-directory',$ENV{VICE_DATA_DIR},
        '-kernal',$ENV{VICE_KERNAL},'-basic',$ENV{VICE_BASIC},'-chargen',$ENV{VICE_CHARGEN},
        '+sound','-warp','-seed',($ENV{VICE_SEED}//42),
        ($ENV{VICE_VIDEO}//'pal') eq 'ntsc' ? '-ntsc' : '-pal',
        '-limitcycles',300000000,'-moncommands',"$dir/commands.mon");
    if (($ENV{VICE_DRIVE}//'filesystem') eq '1541' && !$opt{commands}) {
        push @args,'-dos1541II',$ENV{VICE_DOS1541II},'-drive8type',1542,'-drive8truedrive',
            '+virtualdev8','+iecdevice8','-8',$disk;
    } else {
        push @args,'+drive8truedrive','-virtualdev8','-iecdevice8','-device8',1,'-fs8',$root;
    }
    my $pid=fork();
    BAIL_OUT("fork: $!") unless defined $pid;
    if (!$pid) {
        open STDOUT,'>',"$dir/emulator.log" or die $!;
        open STDERR,'>&',\*STDOUT or die $!;
        exec @args;
        die "exec VICE: $!";
    }
    local $SIG{ALRM}=sub { kill 'KILL',$pid; waitpid($pid,0); BAIL_OUT("VICE timed out ($stem)"); };
    alarm($ENV{VICE_TIMEOUT}//90);
    waitpid($pid,0);
    my $status=$?;
    alarm 0;
    my $artifacts=$ENV{TEST_ARTIFACTS}//'build/test-results';
    make_path($artifacts);
    my $prefix=join('-',($ENV{VICE_VIDEO}//'pal'),($ENV{VICE_DRIVE}//'filesystem'),$stem,$runs);
    copy("$dir/emulator.log","$artifacts/$prefix.log");
    copy("$dir/commands.mon","$artifacts/$prefix.mon");
    copy($disk,"$artifacts/$prefix.d64") if -f $disk;
    copy("$dir/memory.prg","$artifacts/$prefix.ram") if -f "$dir/memory.prg";
    BAIL_OUT("VICE exited unsuccessfully: $status; see $artifacts/$prefix.log") if $status;
    BAIL_OUT("completion breakpoint not reached: $stem; see emulator log") unless -f "$dir/memory.prg";
    open my $fh,'<:raw',"$dir/memory.prg" or die $!;
    local $/;my $bytes=<$fh>;
    BAIL_OUT('truncated monitor memory snapshot') unless length($bytes)==65538;
    return substr($bytes,2);
}
1;
