#!/usr/bin/perl

use RRDs;
use utf8;
use warnings 'all';
use List::Util qw(sum);
use JSON;

my $rrd = "load.rrd";

while(){
	my $cur_time = time();
	my $end_time = $cur_time - 60;
	my $start_time = $end_time - 3600;

	my $json = RRDs::xport("-s", "$start_time", "-e" , "$end_time",
		"--step", "60", "--daemon", "unix:/tmp/rrdcached.sock", "--json",
		"DEF:load=load.rrd:load:AVERAGE",
		"XPORT:load");
	
	open my $fh, ">", "public/data_out.json";
	print $fh encode_json($json);
	close $fh;

	sleep 60;
}
