package openACDserver;

use strict;
use openACD;
use Data::Dump qw(dump); 
use Class::Date qw(date);
use Socket;
use IO::Socket::INET;
use Net::hostent;

use vars '$config';

=head sys_server
 Запускается сервер, как отдельный процесс.
=cut
sub sys_server{

    my $self = shift;
    
    $config = openACD::sys_read_config("callcenter.conf");

    my $pidfile=(defined($config->{"files.pid"}))?$config->{"files.pid"}:"callcenter.pid";
    my $PORT = $config->{"server.port"};
    my $server = IO::Socket::INET->new( Proto => 'tcp', LocalPort => $PORT, Listen => SOMAXCONN, Reuse => 1);
    die "server on port ".$config->{"server.port"} unless $server;

    while (my $client = $server->accept()) {

	$client->autoflush(1);
	print $client "openACD. Welcome on the board! type help for getting some informations.\n";
	print $client "=cut=\n";

        my $hostinfo = gethostbyaddr($client->peeraddr);

        while ( <$client>) {
	    push my @command, split;
	    openACD::sys_addlog("CLIENT says: ".join(' ',@command),$config->{"files.server"});

	    if($command[0] eq 'help')
		{
        	    print $client "Commands:\nquit | exit \t- exit from client\necho on|off \t- on/off verbose mode";
		}

	    if($command[0] eq 'echo')
		{
		    if ($command[1] eq 'off') {
			$client->autoflush(0);
		    }
		    if ($command[1] eq 'on') {
			$client->autoflush(1);
		    }
		}

	    if($command[0] eq 'quit' || $command[0] eq 'exit')
		{
		    last;
		}

	    if($command[0] eq 'date' || $command[0] eq 'time')
		{
		    printf $client "%s\n", scalar localtime;
		}

	    print $client "=cut=\n";

        } continue {

        }

        close $client;

    }
}    



1;
