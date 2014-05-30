#!/usr/bin/perl
use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";

use Tools;
use Configuration;

use threads;
use threads::shared;
use Thread::Queue;

my $q = Thread::Queue->new();
die "usage: perl $0 <Config file>\n\n" unless $#ARGV==0;
my $Config = Configuration->new($ARGV[0]);

my $nThreads = $Config->get("OPTIONS","Threads");

warn "Recognizing $nThreads as max threading...\n";

my $ref=$Config->get("PATHS","reference");
warn "Finding Vectors...\n";
my $vecDir = $Config->get("PATHS","vector_dir");
my @LineNo = $Config->getAll("VECTORS");

foreach my $i (@LineNo){
      $q->enqueue($i);
}
for(my$i=0;$i<=$nThreads;$i++){
      my $thr=threads->create(\&worker);
}
while(threads->list()>0){
      my @thr=threads->list();
      $thr[0]->join();
}


sub worker {
	my $TID=threads->tid() -1 ;
	while(my$j=$q->dequeue_nb()){
		my $path=$Config->get("PATHS","vector_dir")."/".$Config->get("VECTORS",$j);
		warn "Loading $path ...\n";
		my $outputDir = $Config->get("PATHS","output_dir")."/".$Config->get("CELL_LINE",$j);
		mkdir $outputDir unless -e $outputDir;
		my $file=$outputDir."/".$Config->get("CELL_LINE",$j).".ref.fasta";
		my $cmd="cat $ref $path > $file";
		warn $cmd."\n";	
		`$cmd`;
		$cmd=$Config->get("PATHS","bwa")." index $file";
		warn $cmd."\n";
		`$cmd`;
	}
}

# /home/ec2-user/Store1/bin/delly  -t TRA -o TRA.vcf -q 20 -g TwoChrom.fasta pGC1_Raw.sorted.bam

exit(0);


