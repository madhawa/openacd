#!/usr/bin/perl

use strict;
use openACD;
use openACDserver;
use Data::Dump qw(dump);

my $pid = fork();
die "fork dont work: $!" unless defined $pid;

if ($pid) {

    my $config = openACD::sys_read_config("callcenter.conf");
    openACD::sys_print(dump($config));

    my $config = openACD::sys_read_config("callcenter.conf");
    my $pidfile=(defined($config->{"files.pid"}))?$config->{"files.pid"}:"callcenter.pid";

    openACD::sys_addlog( "openACD was started...");
    open(PIDFILE, ">$pidfile");
    print PIDFILE ($$);
    close(PIDFILE);

    openACD->run( port => '4573', user=>'nobody', group=>'nobody' );
    waitpid $$, 0;

}
