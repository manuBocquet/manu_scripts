package PrintColors;
use strict;
use Fcntl;
use Exporter;
use Encode;
use Time::HiRes qw(usleep);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT     = qw(sprintfb qyn colorize printfb waitc stopc get_c cursor_up cursor_down cursor_left cursor_right gotoxy clear get_char show_menu optGet wrap);

my $col=undef;

sub nb_col {
        my $cl;
        open(RES,"/usr/bin/X11/resize|");
        while(<RES>){
                if (/^COLUMNS/){
                        $cl=($_ =~ /.*=(\d+)/)[0];
                }
        }
        close(RES);
        return $cl;
}

sub wrap {
        my $val=shift;
        $col=nb_col() if ($val);
}

sub waitc {
        my $counter=0;
        my @cha=('/','-','\\','|');
        my $fork=fork();
        if ($fork==0){
                $| = 1;
                do {
                        print $cha[$counter++];  
                        usleep(80000);
                        print "\033[1D";
                        $counter=0 if ($counter>3);
                }
                while(1);
                exit 0;
        }
        return $fork;
}

sub stopc {
        my $pid=shift;
        kill(1,$pid);
        print "\n";
}

sub colorize {
        my $str=shift;
        my %color=("</>"=>"\033[m",
        "<b>"=>"\033[1m","<g>"=>"\033[1;32m",
        "<r>"=>"\033[1;31m","<c>"=>"\033[1;36m");

        foreach(keys %color){
                $str =~ s/$_/$color{$_}/g ;
        }
        return $str;
}


sub sprintfb {
        my $format=shift;
        my %color=("</>"=>"\033[m",
	 "<b>"=>"\033[1m","<g>"=>"\033[1;32m",
        "<y>"=>"\033[1;33m","<u>"=>"\033[1;34m",
        "<p>"=>"\033[1;35m","<g>"=>"\033[1;32m",
        "<r>"=>"\033[1;31m","<c>"=>"\033[1;36m");
        my $format1=$format;
        my $format2=$format;
        foreach(keys %color){
                $format1 =~ s/$_/$color{$_}/g ;
                $format2 =~ s/$_//g ;
        }
        my $str1=sprintf $format1,@_; # With colors
        my $str2=sprintf $format2,@_; # without colors
        my $len1=length($str1);       # With colors
        my $len2=length($str2);       # without colors
        if (defined $col && $len2>=$col){         # si on wrap la ligne, on enleve les couleurs
        my $str=substr($str2, 0, $col);
        if ($str2 =~ /\n$/){
                $str .= "\n";
        }
        return $str;
}
elsif (-t STDOUT){
        return $str1;
}
else {
        return $str2;
}
}

sub printfb {
        print sprintfb(@_);
}


sub cursor_up {
        my $num=shift;
        print "\033[".$num."A";
}

sub cursor_down {
        my $num=shift;
        print "\033[".$num."B";
}

sub cursor_left {
        my $num=shift;
        print "\033[".$num."D";
}

sub cursor_right {
        my $num=shift;
        print "\033[".$num."C";
}

sub gotoxy {
        my $x=shift;
        my $y=shift;
        print "\033[".$x.";".$y."H";
        $|++;
}

sub clear {
        print "\033[2J";
        $|++;
}

sub optGet {
        my $var=shift;
        my $que=shift;
        if ($$var eq undef){
                printfb("<b>%s</>: ",$que);
                $$var=<STDIN>;
        }
}

sub get_c {
        system "stty", '-icanon', 'eol', "\001";
        my $key = getc(STDIN);
        system "stty", 'icanon', 'eol', '^@'; # ASCII null
        return $key;
}

#-----------------------------------------------------------
# return one keypress between 1 and 9
#

sub get_char {
        system "stty", '-icanon', 'eol', "\001";
        my $key = getc();
        while (ord($key)<49 || ord($key)>57){
                cursor_left(1);
                $key = getc();
        }
        system 'stty', 'icanon', 'eol', '^@'; # ASCII NUL
        print "\n";
        return $key;
}

#-----------------------------------------------------------
# Aks question with y or n for answer

sub qyn {
        my $title=shift;
        my $rep="";
        system "stty", '-echo','-icanon', 'eol', "\001";
        printfb "-> $title (y/n)? ";
        while ($rep ne "y" && $rep ne "n"){
                $rep=get_c();                
        }
        system "stty", 'echo','icanon', 'eol', '^@'; # ASCII null
        print "$rep\n";
        return $rep;
}


#-----------------------------------------------------------
# show a menu (one attribute by ligne)
#
# ""            : New ligne
# "T:string"    : Show Title
# "R:string"    : Show items
# "G:string"    : Show comment
# "C:"          : Clear string

sub show_menu {
        my @menu=@_;
        my $counter=1;
        foreach(@menu){
                my ($function,$value)=($_ =~ /(..)(.*)/)[0,1];
                if ($function =~ /T:/i){
                        printfb("<b>%s :</>\n\n",$value);
                }
                if ($function =~ /G:/i){
                        printfb("<c>%s</>\n",$value);
                }
                if ($function =~ /C:/i){
                        clear();
                        gotoxy(1,1);
                }
                if ($function =~ /R:/i){
                        printfb("\t%s) %s\n",$counter++,$value);
                }
                if (! length($function)){
                        print "\n";
                }
        }
        printfb("\nChoice :");
        my $ch=get_char();
        return $ch;
}

1;
