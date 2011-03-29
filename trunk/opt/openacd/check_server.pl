#!/usr/bin/perl

use strict;

alarm 1;

my $ps = `ps aux | grep ./callcenter_server.pl | grep -v grep`;

`cd /opt/openacd/;./callcenter_server.pl &` if(!$ps);

alarm 0;

1;