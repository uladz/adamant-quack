use strict;
use warnings;
use YAML::XS;
use Getopt::Long;
use Pod::Usage;

## Tab with # spaces.
my $opt_loot_file = "";
my $opt_boss_file = "";
my $opt_exec = "";
my $opt_man = 0;
my $opt_help = 0;

## Read and parse the tool command line.
GetOptions(
  "loot|l=s" => \$opt_loot_file,
  "boss|b=s" => \$opt_boss_file,
  "exec|x=s" => \$opt_exec,
  "help|?" => \$opt_help,
  "man" => \$opt_man)
  or pod2usage(2);
pod2usage(1) if $opt_help;
pod2usage(-exitval => 0, -verbose => 2) if $opt_man;

## Check inputs.
pod2usage("$0: LOOT input file is missing.") if $opt_loot_file eq "";

## Convert LOOT file into BOSS file format.
my $file = $opt_boss_file;
if ($file ne "") {
  print "Converting \"".$opt_loot_file."\"...";
}
my $ul = YAML::XS::LoadFile($opt_loot_file);
my $f;
if ($file ne "") {
  open $f, ">".$file or die $!;
}
else {
  $f = *STDOUT;
}
for (@{$ul->{plugins}}) {
  my $name = $_->{name};
  my $tags = $_->{tag};
  next unless defined $tags;
  print $f "$name"."\n";
  print $f " TAG: {{BASH: ";
  my $ptag = undef;
  for (@{$tags}) {
    print $f $ptag.", " if defined $ptag;
    $ptag = $_;
  }
  print $f $ptag if defined $ptag;
  print $f "}}"."\n";
}
if ($file ne "") {
  close $f;
  print " done.\n";
}

## Run external command after conversion.
if ($opt_exec ne "") {
  print "Starting \"".$opt_exec."\"...\n";
  system($opt_exec);
}
