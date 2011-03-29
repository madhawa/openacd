#!/bin/sh 
kill `cat /var/run/callcenter.pid`
./callcenter.pl &
    