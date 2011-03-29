#!/usr/bin/perl -w
use strict;
use IO::Socket;

my ($host, $port, $kidpid, $handle, $line);

# Для запуска - ./client.pl host port
# ./client.pl localhost 4583
unless (@ARGV == 2) { die "usage: $0 host port" }
($host, $port) = @ARGV;

$handle = IO::Socket::INET->new(Proto     => "tcp",
                                PeerAddr  => $host,
                                Timeout   => 0.2,
                                PeerPort  => $port) || print "Can't connect\n";

# чтобы вывод отправлялся сразу
$handle->autoflush(1);              

print STDERR "[Подключились к openACD]\n";

# разделяем программу на два идентичных процесса
die "ошибка fork: $!" unless defined($kidpid = fork());

# выполнится только в родительском процессе
if ($kidpid) {
    # копируем сокет на стандартный вывод
    while (defined ($line = <$handle>)) {
        if($line eq "=cut=\n"){
	    print STDERR "openACD>> ";
	} else {
    	    print STDOUT $line;
    	}
    }
    kill("TERM", $kidpid);                  # посылаем SIGTERM дочке
}
# выполнится только в дочернем процессе
else {
# копируем стандартный ввод в сокет
##	print $handle "op"."\015\012";
##	print $handle "exit"."\015\012";
    while (defined ($line = <STDIN>)) {
	print $handle $line;
    }
}
                                                                                                                                                                                                                                       
