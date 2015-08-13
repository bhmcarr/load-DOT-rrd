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
RRDs::create($rrd, "-s 60", "DS:load:GAUGE:120:0:8", "RRA:AVERAGE:0.9:1:60");
$value = 0;

while(){
	my $cur_time = time();
	my $end_time = $cur_time;
	my $start_time = $end_time - 3600;
	open (STAT,"/proc/loadavg") or die "Cannot open /proc/loadavg";

	while(<STAT>){
		my @cpu = split /\s+/, $_;
		$value = $cpu[0];
	}

	RRDs::update($rrd, "--daemon", "unix:/tmp/rrdcached.sock", "N:$value");
	my $err=RRDs::error;
		print "$err\n" if $err;

	close STAT;

	# update the graph

	RRDs::graph("$rrd_graph",
				"--width", "710",
				"--height" , "300",
				"--start", "$start_time",
				"--end", "$end_time",
				"--lower-limit", "0",
				"--upper-limit", "8",
				"--title= CPU Load",
				"--vertical-label= load value",
				"DEF:load=$rrd:load:AVERAGE",
				"LINE1:load#FF0000:load",
				"GPRINT:load:MIN: %6.2lf min",
				"GPRINT:load:MAX: %6.2lf max",
				"GPRINT:load:AVERAGE: %6.2lf average");
			#print ("Updated RRD with value:$value\n");
	sleep 60;
}
