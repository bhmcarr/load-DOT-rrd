#!/usr/bin/perl

use RRDs;
use utf8;
use warnings 'all';
use List::Util qw(sum);

my $path = "./";
my $rrd = "load.rrd";
my $rrd_graph = "public/graph/load_graph.png";

if(-f "load.rrd"){
	unlink "load.rrd" or print "Unable to delete load.rrd: $!";
}
RRDs::create($rrd, "-s 20", "DS:load:GAUGE:60:0:8", "RRA:LAST:0.5:12:24");

$value = 0;
while(){
	my $cur_time = time();
	my $end_time = $cur_time - 60;
	my $start_time = $end_time - 1800;
	open (STAT,"/proc/loadavg") or die "Cannot open /proc/loadavg";
	while(<STAT>){
		my @cpu = split /\s+/, $_;
		$value = $cpu[0];
	}

	#$value = $cpu[0];
	RRDs::update($rrd, "N:$value");
	my $err=RRDs::error;
	print "$err\n" if $err;

	close STAT;

	# update the graph

	RRDs::graph("$rrd_graph",
				"--width", "710",
				"--height" , "200",
				"--start", "$start_time",
				"--end", "$end_time",
				"--lower-limit", "0",
				"--upper-limit", "8",
				"--title= CPU Load",
				"--vertical-label= load value",
				"DEF:load=$rrd:load:LAST",
				"LINE1:load#FF0000:Load",
				"GPRINT:load:MIN:\"%6.2lf min\l\"",
				"GPRINT:load:MAX:\"%6.2lf max\l\"",
				"GPRINT:load:AVERAGE:\"%6.2lf average\l\"");
	print ("Updated RRD with value:$value\n");
	sleep 20;
}
