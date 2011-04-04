package openACD;

use strict;
use base 'Asterisk::FastAGI';
use Class::Date qw(date now);
use Data::Dump qw(dump); 
use DBI;
use Switch;
use DateTime;
use Socket;
use File::Copy;
use Text::Iconv;
use Time::HiRes qw(gettimeofday);
use Net::Ping;

use vars '$config';  # глобальная переменная - массив конфигурации
#use vars '%sip-ip';  # хеш-соответствие SIP - IP
#use vars '%ip-sip';  # хеш-соответствие IP - SIP
use vars '$dbh';  # глобальная переменная соединения с сервером
use vars '$err_conn';
use vars '$log_uniqueid'; #глобальная - для логов uniqueid asterisk

$log_uniqueid = 0;

### Читаем conf-файл
sys_read_main_config();
#sys_print(dump($config));

### КОНФИГУРАЦИЯ ФАЙЛОВ
# Имя лог-файла
my $logfile=(defined($config->{"files.log"}))?$config->{"files.log"}:"callcenter.log";
# Имя pid-файла (для перезагрузки процесса kill `cat callcenter.pid`)
my $pidfile=(defined($config->{"files.pid"}))?$config->{"files.pid"}:"callcenter.pid";

# Записываем PID процесса в файл $pidfile
my $pid = $$;
sys_addlog( "openACD стартовал...ID ".$pid);
open(PIDFILE, ">$pidfile");
print PIDFILE ($pid);
close(PIDFILE);

=head sys_print
 Выводим на экран информацию $msg
 sys_print("test");
=cut
sub sys_print {
    my ( $msg ) = @_;
    my $old = select(STDERR);
    print "$msg\n";
    select($old);
}

=head sys_send_message
 Отсылаем сообщение $msg компьютеру $ip
=cut
sub sys_send_message {
    my ( $msg, $ip, $group ) = @_;
    $group = 'message' unless(defined $group);
    sys_addlog("Сообщение для $ip:".$config->{$group.".port"}." : $msg");
    my $cv = Text::Iconv->new('utf-8','windows-1251');
    my $msg = $cv->convert($msg);
    my ($handle);
    foreach my $j (1..$config->{$group.".count"}){
	if($handle = IO::Socket::INET->new(Proto     => "tcp",
	                            PeerAddr  => $ip,
	                            Timeout   => $config->{$group.".timeout"},
        	                    PeerPort  => $config->{$group.".port"},
				    Type      => SOCK_STREAM)) {
	    $handle->autoflush(1);
	    print $handle $msg;
	    close($handle);
	    last;
	} elsif($j==$config->{$group.".count"}) {
	    sys_addlog("Сообщение для $ip:".$config->{$group.".port"}." не отправлено - $@");
	}
    }
}

=head sys_prepare_send_message
 Подгатавливаем и отсылаем сообщение компьютеру $ip
=cut
sub sys_prepare_send_message {
	my $self = shift;
	my ( $group, $message_type, $calleridname, $service_id, $operator, $ip, $callerid, $addition, $callfilename, $callExtension, $calluniqueid ) = @_;
	$group = 'message' unless(defined $group);

	my $message_to_send = sys_request('message_white_list', $callerid);
	if ( !$message_to_send && $service_id ) {
	    $message_to_send = sys_request('message_by_service_id', $service_id);
	}

	my $operator_password = sys_request('operator_password_by_id', $operator) if($operator);

##если сообщение старого типа
	if($message_to_send =~ / - .*\|/ && ($message_type eq 'before'||$message_type eq 'after')) {
	    if($addition==0) {
		my @message_to_send_split = split('\|',$message_to_send);
		$message_to_send = $message_to_send_split[0];
	    }
	} else {
	    my $text_to_send = $message_to_send;
	    $message_to_send = $config->{$group.'.'.$message_type};
	    if($message_to_send =~ /%title%|%test%/) {
		my @message_to_send_split = split('\|',$text_to_send);
		my $title = $message_to_send_split[0];
		my $text = $message_to_send_split[1];
#		$text = $config->{$group.".white_list"}.$text if ($self->agi->get_variable('ClientWhiteList')==1);
		$message_to_send =~ s/%title%/$title/g;
		$message_to_send =~ s/%text%/$text/g;
	    }
	}

	if($message_to_send =~ /%name%/) {
	    my $operator_name = sys_request('operator_name_by_id', $operator);
	    $operator_name =~ /^(\S*) (\S*)/;
	    $operator_name = $2;
	    $message_to_send =~ s/%name%/$operator_name/g;
	}

	if($message_to_send =~ /%service_number%/ && $calleridname =~ /^SC(.*)/) {
	    $calleridname =~ /^SC(.*)/;
	    my $service_number = $1;
	    $message_to_send =~ s/%service_number%/$service_number/g;
	}

	if($message_to_send =~ /%service%/) {
	    my $service_name = sys_request('service_by_service_id', $service_id);
	    $message_to_send =~ s/%service%/$service_name/g;
	    if($message_to_send =~ /%maxanswertime%/) {
		my $maxanswertime=($config->{"operators.$service_name.maxanswertime"})?$config->{"operators.$service_name.maxanswertime"}:$config->{"operators.default.maxanswertime"};
		$message_to_send =~ s/%maxanswertime%/$maxanswertime/g;
	    }
	}

	if($message_to_send =~ /%prefix%/) {
	    my $calleridprefix = '';
	    my $calleridname1 = substr($calleridname, 0, 1);
	    $calleridprefix = 'Kyivstar' if($calleridname1 eq 'K');
	    $calleridprefix = 'MTS' if($calleridname1 eq 'U' || $calleridname1 eq 'M');
	    $calleridprefix = 'Beeline' if($calleridname1 eq 'B');
	    $calleridprefix = 'Life' if($calleridname1 eq 'L');
	    $calleridprefix = $calleridname if($calleridname1 eq 'S');
	    $message_to_send =~ s/%prefix%/$calleridprefix/g;
	}

	if($message_to_send =~ /%number%/) {
#	    $callerid = int($callerid);
	    $callerid = substr($callerid, -9) if(length($callerid)==11 || length($callerid)==10);
	    $callerid = substr($callerid, -7) if(substr($callerid, 0, 2)==44);
	    $message_to_send =~ s/%number%/$callerid/g;
	}
	
	if($message_to_send =~ /%hello%/) {
	    my $date_now = now;
	    if($date_now->hour<5){
	        $message_to_send =~ s/%hello%/$config->{$group.".night"}/;
	    }
	    elsif($date_now->hour<10){
		$message_to_send =~ s/%hello%/$config->{$group.".morning"}/;
	    }
	    elsif($date_now->hour<17){
		$message_to_send =~ s/%hello%/$config->{$group.".day"}/;
	    }
	    else{
		$message_to_send =~ s/%hello%/$config->{$group.".evening"}/;
	    }
	}

	if($message_to_send =~ /%phone%/) {
	    my $operators_phone = sys_request('sip_by_ip', $ip);
	    $operators_phone =~ m{(.*)/(.*)};
	    $operators_phone = $2;
	    $message_to_send =~ s/%phone%/$operators_phone/g;
	}

	if($message_to_send =~ /%services%/) {
	    $message_to_send =~ s/%services%/$addition/g;
	}

	if($message_to_send =~ /%cityid%/) {
	    $message_to_send =~ s/%cityid%/$config->{"server.city"}/g;
	}

	$message_to_send =~ s/%filename%/$callfilename/g;
	$message_to_send =~ s/%extension%/$callExtension/g;
	$message_to_send =~ s/%uniqueid%/$calluniqueid/g;
	$message_to_send =~ s/%operatorid%/$operator_password/g;

	sys_send_message($message_to_send, $ip, $group);
}

=head sys_send_command
 Отсылаем команду $msg компьютеру $ip на порт $port. При ошибке соединения возращается 0
 sys_send_command('help','127.0.0.1',4583);
=cut
sub sys_send_command {
    my ( $msg, $ip, $port ) = @_;
    sys_addlog("Команда для $ip:$port : $msg");
    my ($handle);
    my $connected = 0;
    my $count = 0;
    while ($connected==0 && $count<2){
	$count++;
	if($handle = IO::Socket::INET->new(Proto     => "tcp",
	                            PeerAddr  => $ip,
	                            Timeout   => $config->{"message.timeout"},
        	                    PeerPort  => $port)) {
    	    $connected=1;
	}        	                    
	if ($connected==0) {select(undef,undef,undef,(int(rand(200))+200)/1000);}    
    }
    if ($connected==1) {
	$handle->autoflush(1);
	print $handle $msg."\n\n";

	my ($ret, $reg);
	alarm 2;

	while ($ret ne "=cut=\n") {
	    $ret = $handle->getline;
	}

	$ret="";
	while ($ret ne "=cut=\n") {
    	    $ret = $handle->getline();
	    $reg = $reg.$ret if ($ret ne "=cut=\n");
	}
    
	alarm 0;
	$reg =~ s/\n//i;

	print $handle "exit\n";
	$handle->close();

	return $reg;

    } else {
	sys_addlog("Команда для $ip:$port не отправлена");
	return 0;
    }
}

=head sys_addlog
 Дописываем $logline в файл $logfile или дописываем $logline в файл $file
 sys_addlog("test");
 sys_addlog("test", "DB/test.sql");
=cut
sub sys_addlog {
    my ( $logline, $file ) = @_;
    $file = $logfile unless(defined $file);
    my $curr_date = date(time);
    $logline = $curr_date." [".$log_uniqueid."] ".$logline;
    open(LOGFILE, ">>$file");
    print LOGFILE ($logline."\n");
    close(LOGFILE);
}

=head sys_callers_dump
 Дописываем $logline в файл $phone - информация о телефонном звонке
 sys_addlog("test");
 sys_callers_dump("5550000", "поступил звонок");
 sys_callers_dump("5550000", "поступил звонок", "10:00:32");
=cut
sub sys_callers_dump {
    my ( $phone, $logline, $logtime ) = @_;
    sys_addlog("$phone, $logline");
    $phone='undefined' unless(defined $phone);
    if(!defined($logtime)) {
#	my $curr_date = date(time);
	my ($curr_date, $microseconds) = gettimeofday;
	$logline = date($curr_date).".".$microseconds. " ".$logline;
    } else {
	$logline = $logtime. " ".$logline;
    }
    my $subdir = '/';
    if($config->{"files.callers_dump_subdir"} eq "on" && $phone=~/^(\d{3})/) {
	mkdir $config->{"files.callers_dump"}.$subdir.$1 unless(-d $config->{"files.callers_dump"}.$subdir.$1);
	$subdir .= $1.'/';
	if($phone=~/^\d{3}(\d{2})/) {
	    mkdir $config->{"files.callers_dump"}.$subdir.$1 unless(-d $config->{"files.callers_dump"}.$subdir.$1);
	    $subdir .= $1.'/';
	}
    }
    open(LOGFILE, ">>".$config->{"files.callers_dump"}.$subdir.$phone);
    print LOGFILE ($logline."\n");
    close(LOGFILE);
}

sub sys_read_config {
    my ( $configfile ) = @_;
    my ($conf,$line,$section);
    open (CONFIGFILE, $configfile) or return 0;
    $conf->{'_filename'} = $configfile;
    while ($line = <CONFIGFILE>) {
        if ($line =~ /^\[(.*)\]/) {
    	    $section = $1;
        } elsif ($line =~ /^[\ \t]*([^=\ \t]+)[\ \t]*=[\ \t]*(.*)[\ \t]*/) {
    	    my ($config_name, $config_val) = ($1, $2);
            if ($section) {
        	$conf->{"$section.$config_name"} = $config_val;
    	    } else {
    		$conf->{$config_name} = $config_val;
    	    }
        }                           
    }
    close CONFIGFILE;
    return $conf;
}

=head sys_read_main_config
 Функция обновляет глобальную конфигурацию из файла callcenter.conf
=cut
sub sys_read_main_config {
    $config = sys_read_config("callcenter.conf");
    sys_addlog("Прочитали conf-файл");
    sys_addlog(dump($config));
}

sub sys_stream_file {
    my $self = shift;
    my $file = shift;
    $self->agi->stream_file($file);
}

sub sys_say_number {
    my $self = shift;
    my ($num, $path, @add) = @_;
    my $dec = int($num/10)*10;
    if($dec>=20) {
	$num = $num-$dec;
	sys_stream_file($self, "$path/$dec");
	$add[$num] = '' unless $add[$num];
	sys_stream_file($self, "$path/$num".$add[$num]) if($num!=0);
    } else {
	$num=0 if($num eq '');
	$add[$num] = '' unless $add[$num];
	sys_stream_file($self, "$path/$num".$add[$num]);
    }
}


=head sys_db_connect
 Подключаемся к базе данных
=cut
sub sys_db_connect {
    #Подключение к базе данных
    my ( $server ) = @_;
    my $err_conn = 0;
    $server = '.'.$server if ($server ne '');
    $dbh = DBI->connect_cached("dbi:Pg:dbname=".$config->{"base$server.name"}.";host=".$config->{"base$server.host"}.";port=".$config->{"base$server.port"},
		    $config->{"base$server.username"},
		    $config->{"base$server.password"}, 
		    {PrintError => 0}) or $err_conn = 1;
}

=head sys_db_connect
 Отключаемся от базы данных
=cut
sub sys_db_disconnect {
	$dbh->disconnect() if($err_conn == 0);
}

=head sys_db_request
 Выполняем sql-запрос $sql
    @result = sys_db_request("select * from table");
 $result[x][y] - результат - таблица.
 Для перебора
    foreach $i (@result) {
    	$res{$i->[0]} = $i->[1];
    }
=cut
sub sys_db_request {
    my ( $sql, $server, $type_result ) = @_;
    $server='' if(!defined $server);
    $type_result = 'array' if(!defined $type_result);

    if ($server eq '' && $DBI::err != 0) {
        sys_addlog( "Cannot connect to DataBase... ".$DBI::errstr);
        sys_print( "Cannot connect to DataBase... ".$DBI::errstr);
	exit($DBI::err);
    }

    
	my $rv = 0;
	my @result = ();
	if($sql ne "TEST" && $err_conn == 0) {
	    my $sth = $dbh->prepare($sql);
	    $rv = $sth->execute();
	    if (!defined $rv) {
    		sys_addlog("При выполнении запроса '$sql' возникла ошибка: " . $dbh->errstr);
	    }

#	my $result = $sth->fetchrow_array();
	    while(my @row = $sth->fetchrow_array()) {
        	push(@result, [@row]);
	    }

	    $sth->finish();
	}

	if ($type_result eq 'int') {
	    return int($rv);
	} else {
	    return @result;
	}
}

=head sys_request
 Опрос флагов (сейчас это - релоад конфигурации из файла)
 Запрос к системе на выдачу результата
 Необходим для работы как с базой, так и без базы
 sys_request ( $request, $param )
    $request:
     - ip_by_sip - возвращает ip адрес компьютера, возле которого установлен телефон SIP $param1 -- sys_request('ip_by_sip', 'SIP/1234');
     - sip_by_ip - возвращает SIP/номер телефона по ip адресу компьютера $param1 -- sys_request('sip_by_ip', '127.0.0.1');
     - operator_id_by_password - возвращает id оператора по паролю $param1 -- sys_request('operator_id_by_password', '1234');
     - operator_name_by_password - возвращает ФИО оператора по паролю $param1 -- sys_request('operator_id_by_password', '1234');
     - operator_id_by_channel - возвращает id оператора по имени канала $param1 -- sys_request('operator_id_by_channel', 'SIP/1234');
     - operator_id_by_channel_like - возвращает id оператора по совпадению имени канала $param1 -- sys_request('operator_id_by_channel_like', '%/1234');
     - channel_by_operator_id - возвращает имя канала по id оператора $param1 -- sys_request('channel_by_operator_id', '1');
     - operator_city_by_operator_id - возвращает город оператора по id $param1 -- sys_request('operator_city_by_operator_id', '1');
     - operator_is_login - Возвращает status оператора, если оператор с id $param1 залогинен -- sys_request('operator_is_login', '1');
     - operator_is_outgoing_calls - можно ли совершать исходящие звонки
     - operator_events - Записывает событие $param2 оператора $param1. Номер звонившего - $param3 и таймер события, сек - $param4 по умолчанию 0 -- sys_request('operator_events', '1', '21');
     - operator_login - Оператор добавляется в таблицу залогиненых. Если оператор был залогинен, то он предварительно разлогинивается. Id оператора - $param1, расположение оператора - $param2 -- sys_request('operator_login', 1, 'SIP/1000');
     - operator_logout - Оператор удаляется из таблицы залогиненых. Id оператора - $param1 -- sys_request('operator_logout', 1);
     - operator_values - Возвращает номер и службу текущего разговора по id оператора
     - operator_status - Обновление статуса оператора. Id оператора - $param1, статус оператора - $param2, канал/дополнительно - $param3 -- sys_request('operator_status', 1, 1, 'login');
     - operators_online - Возвращает количество операторов сервиса $param1 свободных ($param2=free) или всех ($param2=all) -- sys_request('operators_online', 1, 'all');
     - operators_bussy - Количество занятых операторов
     - operators_free_online - Возвращает массив - список id свободных операторов (status=1 && time<NOW()) согласно правилу выборки $param1 и id сервиса $param2 -- sys_request('operators_free_online', 'random', '453-Kyiv');
     - operator_password_by_id - возвращает пароль оператора по его id -- sys_request('operator_password_by_id', '1');
     - operator_login_addtime - опрератор id $param1 на протяжении $param2 секунд не будет выбираться для ответа на звонок клиента
     - operator_login_add_timecall - оператору id $param1 добавляется один принятый звонок продолжительностью $param2
     - get_service_by_service_name - возвращаются вес, имя и id услуги по её названию
     - get_services_by_operator_id - возвращает список сервисов оператора по его id
     - message_by_service_id - возвращает текстовое сообщение для оператора по id очереди
     - service_by_service_id - имя сервиса по его id
     - check_black_list - изменяет значение счетчика черного списка и возвращает кол-во измененных полей
     - check_white_list - изменяет значение счетчика белого списка и возвращает кол-во измененных полей
     - client_queue_add - добавление в очередь клиента очереди $param1, веса $param2, номера телефона $param3 и канала $param4. Возвращает ID в очереди
     - client_queue_next - выборка id очередных клиентов из очереди первых в каждой из служб с сортировкой по весу службы
     - client_queue_bussy - обновление параметра занятости $param2 с ID очереди $param1
     - client_queue_place - сколько клинетов в очереди до ID очереди $param1 с услугой $param2
     - client_queue_total - сколько клинетов в очереди с услугой $param1
     - client_queue_carry - обновление времени последнего опроса у клиента в очереди ID $param1 и удаляем тех, у кого время > $param2
     - client_queue_remove - удаление из очереди ID $param1
     - calls_log - запись в таблицу log информации о звонке. входные данные: id_звонившего, пароль оператора, время начала (unix timestamp), статус звонка, общее время звонка, время ответа, время в очереди, максимальное положение в очереди, ACD группа, Extension. данные передаются одной строкой с разделителем "`" -- sys_request('calls_log', join("`",($params->{callerid}, $operator_password, $time_begin, $status, $time_total, $answeredtime, $time_total_queue, $queue_maximum, $acdgroup, $extension, 0, 0)));

=cut
sub sys_request {
    my ( $request, $param1, $param2, $param3, $param4, $param5, $param6 ) = @_;
#sys_addlog(dump(@_));

    switch($request){
	case 'ip_by_sip' {
		my @result = sys_db_request("SELECT dst_ip FROM public.destination WHERE dst_name='$param1'");
		return $result[0][0];
	}
	case 'sip_by_ip' {
		my @result = sys_db_request("SELECT dst_name FROM public.destination WHERE dst_ip='$param1'");
		return $result[0][0];
	}
	case 'operator_id_by_password' {
		$param2='' if(!defined $param2);
		my @result = sys_db_request("SELECT opr_id FROM public.operators WHERE opr_password='$param1' AND opr_date_end IS NULL", $param2);
		return $result[0][0];
	}
	case 'operator_values' {
		my @result = sys_db_request("SELECT opl_number, srv_id, opl_channels FROM public.operators_login WHERE opr_id='$param1'");
		return $result[0];
	}
	case 'operator_name_by_id' {
		my @result = sys_db_request("SELECT opr_name FROM public.operators WHERE opr_id='$param1'");
		return $result[0][0];
	}
	case 'operator_id_by_channel' {
		my @result = sys_db_request("SELECT opr_id FROM public.operators_login WHERE opl_destination='$param1'");
		return $result[0][0];
	}
	case 'operator_id_by_channel_like' {
		my @result = sys_db_request("SELECT opr_id FROM public.operators_login WHERE opl_destination like '$param1'");
		return $result[0][0];
	}
	case 'channel_by_operator_id' {
		$param2='' if(!defined $param2);
		my @result = sys_db_request("SELECT opl_destination FROM public.operators_login WHERE opr_id='$param1'", $param2);
		return $result[0][0];
	}
	case 'operator_city_by_operator_id' {
	    my @result = sys_db_request("SELECT opr_city FROM public.operators WHERE opr_id='$param1'");
	    return $result[0][0];
	}
	case 'operator_is_login' {
		my @result = sys_db_request("SELECT opl_status FROM public.operators_login WHERE opr_id='$param1'");
		return $result[0][0];
	}
	case 'operator_is_outgoing_calls' {
		return 1 unless $param1;
		my @result = sys_db_request("SELECT opr_outgoing_call FROM public.operators WHERE opr_id='$param1'");
		return $result[0][0];
	}
	case 'operator_events' {
	    $param5 = '' if(!defined($param5));
	    $param3=0 if(!defined $param3);
            my @addition;
            if(!defined($param4)){
                $addition[0]=$addition[1]=$addition[2]=$addition[3]=$addition[4]=$addition[5]=$addition[6]=0;
            } else {
                @addition = split('`',$param4);
            }
	    $addition[0] = 0 unless $addition[0];
            $addition[5]=time() if($addition[5] eq '' || $addition[5]==0);
	    if ( $addition[6] ) {
		my @result = sys_db_request("SELECT record_id FROM public.records WHERE record_file_name='$addition[6]'");
		$addition[6] = $result[0][0] || 0;
	    } else {
		$addition[6] = 0;
	    }
	    sys_db_request("INSERT INTO public.agents_logs (dt, agent, event, callid, timer, acdgroup, exten, beforeanswertime, dialstatus, dt_begin, record_id) VALUES (NOW(), '$param1', '$param2', '$param3', '$addition[0]', '$addition[1]', '$addition[2]', '$addition[3]', '$addition[4]', TIMESTAMP WITH TIME ZONE 'epoch' + $addition[5] * INTERVAL '1 second', $addition[6])", $param5);
#	    sys_callers_dump("agents_logs.sql", "INSERT INTO agents_logs (dt, agent, event, callid, timer, acdgroup, exten, beforeanswertime, dialstatus, dt_begin, record_id) VALUES (".time().", '$param1', '$param2', '$param3', '$addition[0]', '$addition[1]', '$addition[2]', '$addition[3]', '$addition[4]', TIMESTAMP WITH TIME ZONE 'epoch' + $addition[5] * INTERVAL '1 second', $addition[6]);", "");
	}
	case 'operator_login' {
		sys_request('operator_logout',$param1) if (defined sys_request('operator_is_login', $param1));
		my $city = sys_request('operator_city_by_operator_id',$param1);
		sys_db_request("INSERT INTO public.operators_login 
				(opr_id, opl_time, opl_status, opl_destination, opl_calls, opl_calls_time, opl_rate, opl_timestamp) 
				VALUES ('$param1', NOW(), 1,'$param2', 0, 0, '$city', ".time().")");
		sys_request('operator_events',$param1,21);
	}
	case 'operator_logout' {
		sys_request('operator_events',$param1,22);
		sys_db_request("DELETE FROM public.operators_login WHERE opr_id='$param1'");
	}
	case 'operator_status' {
		$param3='' if(!defined($param3));
		$param4=0 if(!defined($param4));
		$param5='' if(!defined($param5));
		$param6='' if(!defined($param6));
		my $opl_time = 'opl_time';
		$opl_time = 'NOW()' if ($param2==4);
		my $opl_timestamp = 'opl_timestamp';
		$opl_timestamp = time() if ($param2==4);
		if($param2 == 4) {
		    my $ch = sys_db_request("UPDATE public.operators_login SET opl_status='$param2', opl_time=$opl_time, opl_timestamp=$opl_timestamp, opl_number='$param3', srv_id=$param4, opl_channels='$param5', opl_channels_check=1 WHERE opl_status!=4 AND opl_status!=3 AND opr_id='$param1'", $param6, "int");
		    if ($ch==0) {
			my $ch3 = sys_db_request("UPDATE public.operators_login SET opl_status=1, opl_time=$opl_time, opl_timestamp=$opl_timestamp, opl_number='$param3', srv_id=$param4, opl_channels='$param5', opl_channels_check=1 WHERE opl_status=3 AND opr_id='$param1'", $param6);
			sys_addlog("ERROR: $param3 повесил трубку очень быстро") if ($ch3!=0);
		    }
		    return $ch;
		} elsif($param2 == 3) {
		    my $ch = sys_db_request("UPDATE public.operators_login SET opl_status='$param2', opl_time=$opl_time, opl_timestamp=$opl_timestamp, opl_number='$param3', srv_id=$param4, opl_channels='$param5', opl_channels_check=1 WHERE opl_status!=4 AND opr_id='$param1'", $param6, "int");
		    if ($ch==0) {
			my $ch3 = sys_db_request("UPDATE public.operators_login SET opl_status=1, opl_time=$opl_time, opl_timestamp=$opl_timestamp, opl_number='$param3', srv_id=$param4, opl_channels='$param5', opl_channels_check=1 WHERE opl_status=4 AND opr_id='$param1'", $param6);
			sys_addlog("ERROR: $param3 повесил трубку не очень быстро") if ($ch3!=0);
		    }
		} elsif($param2 == 1) {
		    return sys_db_request("UPDATE public.operators_login SET opl_status='$param2', opl_time=$opl_time, opl_timestamp=$opl_timestamp, opl_number='$param3', srv_id=$param4, opl_channels='$param5', opl_channels_check=1 WHERE opl_status!=1 AND opr_id='$param1'", $param6, "int");
		} else {
		    sys_db_request("UPDATE public.operators_login SET opl_status='$param2', opl_time=$opl_time, opl_timestamp=$opl_timestamp, opl_number='$param3', srv_id=$param4, opl_channels='$param5', opl_channels_check=1 WHERE opr_id='$param1'", $param6, "int");
		}
	}
	case 'operators_online' {
	    $param2 = 'all' if(!defined($param2));
	    $param3 = '' if(!defined($param3));
		my @result;
		if($param2 eq 'free'){
		    @result = sys_db_request("SELECT COUNT(*) FROM public.operators_login ol 
					    LEFT JOIN public.operators_services os ON (ol.opr_id=os.opr_id)
					    LEFT JOIN public.services se ON (os.srv_id=se.srv_id)
					    WHERE ol.opl_status=1 AND ol.opl_timestamp<".time()."
					    AND se.srv_name='$param1'", $param3);
		} else {
		    @result = sys_db_request("SELECT COUNT(*) FROM public.operators_login ol 
					    LEFT JOIN public.operators_services os ON (ol.opr_id=os.opr_id)
					    LEFT JOIN public.services se ON (os.srv_id=se.srv_id)
					    WHERE se.srv_name='$param1'", $param3);
		}
		return $result[0][0];
	}
	case 'operators_online_all' {
		my @c = sys_db_request("SELECT COUNT(*) FROM public.operators_login");
		return $c[0][0];
	}
	case 'operators_last_vip_service' {
		my @result = sys_db_request("SELECT COUNT(*), MAX(ol.opr_id) 
			    FROM public.operators_services os 
			    INNER JOIN public.services sr ON (sr.srv_id=os.srv_id) 
			    INNER JOIN public.operators_login ol ON (ol.opr_id=os.opr_id) 
			    WHERE sr.srv_weight>=100 AND opl_status=1 
			    GROUP BY srv_name");
		foreach (@result) {
	    	return 1 if($_->[0]<= $config->{"operators.default.allways-free"} && $_->[1]==$param1);
		}
		return 0;
	}
	case 'pop_the_poo' {
		return 0 unless($param1);
		my @result = sys_db_request("SELECT ol.opr_id, ol.opl_channels
			    FROM public.operators_services os
			    INNER JOIN public.services sr ON (sr.srv_id=os.srv_id)
			    INNER JOIN public.operators_login ol ON (ol.opr_id=os.opr_id AND ol.srv_id=os.srv_id)
			    WHERE sr.srv_weight<=35 AND opl_status!=1
			    ORDER BY ol.opl_timestamp");
		foreach my $check (@result) {
		    my @services = sys_request('get_services_by_operator_id', $check->[0]);
		    return $check->[1] if grep (/^$param1$/, @services);
		}
		return 0;
	}
	case 'limit_operators' {
#		$config->{"operators.default.max"} = 5;
		return 0 unless $config->{"operators.default.max"};
		my $ctd = sys_request('operators_online_all')-$config->{"operators.default.max"};
		return 0 if $ctd <= 0;
		sys_db_request( "DELETE FROM public.operators_login WHERE opl_id = any (array(select opl_id from public.operators_login where opl_status=1 limit $ctd))" );
	}
	case 'operators_busy' {
		my @result = sys_db_request( "SELECT COUNT(*) c FROM public.operators_login op 
			    INNER JOIN public.operators_services os ON (op.opr_id=os.opr_id)
			    INNER JOIN public.services sr ON (sr.srv_id=os.srv_id)
			    WHERE op.opl_status!=1 AND op.opl_timestamp<".time() );
		return $result[0][0];
	}
	case 'operators_free_online' {
		sys_request('limit_operators');
		$param3 = '' if(!defined($param3));
		    my $sql = "SELECT op.opr_id, sr.srv_weight
			    FROM public.operators_login op 
			    INNER JOIN public.operators_services os ON (op.opr_id=os.opr_id)
			    INNER JOIN public.services sr ON (sr.srv_id=os.srv_id)
			    WHERE op.opl_status=1 AND op.opl_timestamp<".time()." AND sr.srv_id='$param2'";
		    my $order="";
		    if ($param1 eq "justice") {
			$order="ORDER BY os.ops_value DESC, op.opl_calls ASC";
		    }
		    elsif ($param1 eq "random") {
			$order="ORDER BY RANDOM()";
		    }
		    elsif ($param1 eq "qualification") {
			$order="ORDER BY os.ops_value DESC, op.opl_rate DESC";
		    }
		    elsif ($param1 eq "standing") {
			$order="ORDER BY os.ops_value DESC, op.opl_timestamp ASC";
		    }
		    elsif ($param1 eq "notload") {
			$order="ORDER BY os.ops_value DESC, op.opl_calls_time ASC";
		    }
		    my @result = sys_db_request($sql." ".$order, $param3);
# Если вес очереди меньше 100, значит не занимать последнего оператора, на службе 100 и больше
# и не учитывать эту логику, если количество операторов меньше 4
		    if($result[0][1]<100) {
			$result[0][0] = 0 if(sys_request('operators_last_vip_service', $result[0][0]) && sys_request('operators_online_all')>3);
#			foreach my $service (sys_request('get_services_by_operator_id', $result[0][0])) {
#			    $result[0][0] = 0 if( $service->[6]>=100 && sys_request('operators_online', $service->[5], 'free')<=1 );
#			}
		    }
		    my $added_time = sys_request('operator_login_addtime', $result[0][0], 1, $param3) if ($result[0][0]>0);
		    $result[0][0] = 0 if (!defined $added_time || $added_time==0);
		    return (@result);
	}
	case 'operator_password_by_id' {
		$param2 = '' if(!defined($param2));
		my @result = sys_db_request("SELECT opr_password FROM public.operators WHERE opr_id='$param1'", $param2);
		return $result[0][0];
	}
	case 'operator_login_addtime' {
	        $param3 = '' if(!defined($param3));
	        #sys_db_request("UPDATE public.operators_login SET opl_timestamp=".(time()+$config->{"operators.default.timeout-delta"}).", opl_time=NOW()+INTERVAL '".$config->{"operators.default.timeout-delta"}." seconds' WHERE opr_id='$param1' AND opl_time<NOW() AND opl_state=-2", $param3);
		#return sys_db_request("UPDATE public.operators_login SET opl_timestamp=".(time()+$param2).", opl_time=NOW()+INTERVAL '$param2 seconds', opl_state=0 WHERE opr_id='$param1' AND (opl_time<NOW() OR opl_state=-2)", $param3, "int");
		return 0 unless $param2;
		return sys_db_request("UPDATE public.operators_login SET opl_timestamp=".(time()+$param2).", opl_time=NOW()+INTERVAL '$param2 seconds', opl_state=0 WHERE opr_id='$param1'", $param3, "int");
	}
	case 'operator_login_add_timecall' {
		$param3 = '' if(!defined($param3));
		sys_db_request("UPDATE public.operators_login SET opl_calls_time=opl_calls_time+$param2, opl_calls=opl_calls+1 WHERE opr_id='$param1'", $param3);
	}
	case 'get_service_by_service_name' {
		$param2='' if(!defined($param2));
		my @result = sys_db_request("SELECT * FROM public.services WHERE srv_name='$param1'", $param2);
		return ([$result[0][2],$result[0][1],$result[0][0],$result[0][5]]);
	}
	case 'get_services_by_operator_id' {
		return sys_db_request("SELECT * FROM public.operators_services os INNER JOIN public.services sr ON (sr.srv_id=os.srv_id) WHERE os.opr_id='$param1'");
	}
	case 'message_white_list' {
		my @result = sys_db_request("SELECT wll_text FROM public.white_list WHERE wll_number='$param1'");
		return $result[0][0];
	}
	case 'message_by_service_id' {
		my @result = sys_db_request("SELECT srv_message FROM public.services WHERE srv_id='$param1'");
		return $result[0][0];
	}
	case 'service_by_service_id' {
		my @result = sys_db_request("SELECT srv_name FROM public.services WHERE srv_id='$param1'");
		return $result[0][0];
	}
	case 'client_queue_add' {
		sys_db_request("INSERT INTO public.queues (que_id, srv_id, que_weight, que_bussy, que_number, que_channel, que_time, que_time_from, que_timestamp, que_timestamp_from) 
					VALUES (DEFAULT, $param1, $param2, 0, '$param3', '$param4', NOW(), NOW(), ".time().", ".time().")");
		my @result = sys_db_request("SELECT que_id FROM public.queues WHERE srv_id=$param1 AND que_number='$param3' AND que_channel='$param4' AND que_bussy=0");
		return $result[0][0];
	}
	case 'client_queue_next' {
#		my @result = sys_db_request("SELECT que_id FROM public.queues WHERE srv_id=$param1 AND que_bussy=0 order by que_weight desc, que_id asc");
		my @result = sys_db_request("SELECT min(qu.que_id) FROM public.queues qu  
						JOIN public.operators_services os ON (os.srv_id = qu.srv_id) 
						JOIN public.operators_login ol ON (ol.opr_id = os.opr_id) 
						WHERE qu.que_bussy=0 AND ol.opl_status=1
						GROUP BY qu.srv_id, qu.que_weight
						ORDER by qu.que_weight desc
					    ");
		return @result;
	}
	case 'client_queue_bussy' {
		sys_db_request("UPDATE public.queues SET que_bussy=$param2 WHERE que_id=$param1");
	}
	case 'client_queue_place' {
		my @result = sys_db_request("SELECT COUNT(*) FROM public.queues WHERE que_bussy=0 AND que_id<=$param1 AND srv_id=$param2");
		return $result[0][0];
	}
	case 'client_queue_total' {
		my @result = sys_db_request("SELECT COUNT(*) FROM public.queues WHERE que_bussy=0 AND srv_id=$param1");
		return $result[0][0];
	}
	case 'client_queue_carry' {
		sys_db_request("UPDATE public.queues SET que_time=NOW(), que_timestamp=".time()." WHERE que_id=$param1");
		sys_db_request("DELETE FROM public.queues WHERE que_timestamp<".(time()-$param2));
	}
	case 'client_queue_remove' {
		sys_db_request("DELETE FROM public.queues where que_id=$param1");
	}
	case 'client_queue_down_check' {
		my @result = sys_db_request("SELECT opr_id, opl_channels FROM public.operators_login WHERE opl_channels!='external' AND opl_status=4 AND opl_timestamp<".time()."-(opl_channels_check)*".$config->{"server.middletime"});
		sys_db_request("UPDATE public.operators_login SET opl_channels_check=opl_channels_check+1 WHERE opl_status=4 AND opl_timestamp<".time()."-(opl_channels_check)*".$config->{"server.middletime"});
		return @result;
	}
	case 'check_black_list' {
		return sys_db_request("UPDATE public.black_list SET bll_count=bll_count+1 WHERE bll_number='$param1' AND bll_service='$param2'", '', "int");
	}
	case 'check_white_list' {
		return sys_db_request("UPDATE public.white_list SET wll_count=wll_count+1 WHERE wll_number='$param1' AND wll_service='$param2'", '', "int");
	}
	case 'calls_log' {
	    my @param1 = split('`',$param1);
		$param1[0]=0 if($param1[0] eq 'unknown');
		$param1[1] = 0 if(!defined($param1[1]) || $param1[1] eq '');
		$param1[6] = 0 if(!defined($param1[6]) || $param1[6] eq '');
		$param1[8] = 0 if(!defined($param1[8]) || $param1[8] eq '');
		$param1[5] = 0 if(!defined($param1[5]) || $param1[5] eq '');
		$param1[4] = 0 if(!defined($param1[4]) || $param1[4] > 100000 );
		$param1[2] = time() if(!defined($param1[2]) || $param1[2] eq '');
		my $incoming_number = $param1[0];
		if($param1[4]-$param1[5]-$param1[6]>10000000 || $param1[4]-$param1[5]-$param1[6]<0){
		    sys_addlog("ALERT! param1[4]-param1[5]-param1[6]=".($param1[4]-$param1[5]-$param1[6]));
		}
		if($param1[5]>10000000 || $param1[5]<0){
		    sys_addlog("ALERT! param1[5]=".$param1[5]);
		}
		$incoming_number = "" if($incoming_number eq 'unknown' || $incoming_number eq 'Unknown' || $incoming_number eq '80anonymous');
		sys_addlog("INSERT INTO calls (id1, id, dt, acdgroup, agent, status, beforeanswertime, answertime, queuetime, queuecount, callerid, exten, holdtime, crossid, operator) VALUES (NULL, $param1[2], FROM_UNIXTIME($param1[2]), '$param1[8]', $param1[1], $param1[3], $param1[4]-$param1[5]-$param1[6], $param1[5], $param1[6], $param1[7], '$incoming_number', '$param1[9]', $param1[10], $param1[11], '$param1[12]')", '/tmp/calls_log.sql');
		sys_db_request("INSERT INTO public.calls 
		    (id1, id, dt, 
		    acdgroup, agent, status, 
		    beforeanswertime, answertime, queuetime, queuecount, 
		    callerid, exten, holdtime, crossid, operator)
		    VALUES (DEFAULT, $param1[2], TIMESTAMP WITH TIME ZONE 'epoch' + $param1[2] * INTERVAL '1 second', '$param1[8]', 
		    $param1[1], $param1[3], $param1[4]-$param1[5]-$param1[6], 
		    $param1[5], $param1[6], $param1[7], '$incoming_number', 
		    '$param1[9]', $param1[10], $param1[11], '$param1[12]')");

		sys_callers_dump("calls.sql", "INSERT INTO calls (id1, id, dt, acdgroup, agent, status, beforeanswertime, answertime, queuetime, queuecount, callerid, exten, holdtime, crossid) VALUES (NULL, $param1[2], FROM_UNIXTIME($param1[2]), $param1[8], $param1[1], $param1[3], $param1[4]-$param1[5]-$param1[6], $param1[5], $param1[6], $param1[7], '$incoming_number', '$param1[9]', $param1[10], $param1[11]);", "");
###mysql Kyiv Moscow
	}

    }
    
}

=head sys_get_foreign_server
 Опрос серверов с целью узнать количество свободных операторов очереди $acdgroup
 Возвращает имя сервера из conf-файла, на котором свободных операторов больше если сервер пингуется
=cut
sub sys_get_foreign_server {
    my ($acdgroup) = @_;
    my @service_id = sys_request('get_service_by_service_name', $acdgroup);
    $config->{"server.servers"} =~ s/\ //ig;
    my @server_list = split (',', $config->{"server.servers"});
    my $operators_max = 0;
    my $operator_max = 0;
    my $operator_server = '';

    foreach my $each_server (@server_list){
	my $ping = Net::Ping->new();
	if ($ping->ping($config->{"base.$each_server.host"}, 1)) {
		sys_db_connect($each_server);
		$operator_max = sys_request('operators_online', $service_id[0][1], "free", $each_server);
		sys_db_disconnect();

#правило "один оператор на удаленном сервере всегда свободный"
	    $operator_max = 0 if( $operator_max <= $config->{"servers.$each_server.allwaysfree"} );

	    if ($operator_max > $operators_max){
		$operators_max = $operator_max;
		$operator_server = $each_server;
	    }
	}
	$ping->close();
    }

    sys_db_connect();

    return $operator_server;
}

=head login
 Вход/Выход оператора
 exten => 1800,1,agi(agi://127.0.0.1/login?event=login)
 exten => 1899,1,agi(agi://127.0.0.1/login?event=logout)
=cut
sub login {
    my $self = shift;

    sys_db_connect();
    
    my $params = $self->{server}->{agi}->{env};
    my $event = $self->param('event');
    my $password = 0;
    
    my $operator = sys_request('operator_id_by_channel', $params->{type}.'/'.$params->{callerid});
    
    sys_request('operator_status', $operator, 0) if($operator!=0);
    
    $password = $self->agi->get_data($config->{"voice.login"},5000,5) if($event eq "login");
    $password = $self->agi->get_data($config->{"voice.logout"},5000,5) if(($event eq "logout")&&($operator!=0));

    my($operator_id, $operator_test);
    if($password ne '') {
	$operator_id = sys_request('operator_id_by_password', $password);
	$operator_test = sys_request('channel_by_operator_id', $operator_id) if($operator_id ne '');
    }

    if(($event eq "logout")&&($operator==0)){
	$self->agi->control_stream_file($config->{"voice.yourenotin"});
	sys_addlog("Оператор выходит но он еще не залогинился");
    }
    elsif (!defined $operator_id
	    || ($operator != $operator_id && defined $operator) 
	    || ($operator_test ne $params->{type}.'/'.$params->{callerid} && defined $operator_test)) {
	$self->agi->control_stream_file($config->{"voice.passwrong"});
	sys_request('operator_status', $operator, 1) if($operator!=0);
	sys_addlog("Опреатор $operator ввел неверный пароль");
    }
    else {
	if($event eq "login") {
	    sys_request('operator_login', $operator_id, $params->{type}.'/'.$params->{callerid});
	    
	    #отправка сообщения о входе
	    my $message_ip = sys_request('ip_by_sip', $params->{type}.'/'.$params->{callerid});
	    my @service;
	    my @services = sys_request('get_services_by_operator_id', $operator_id);
	    push (@service, $_->[5]) foreach (@services);
	    sys_prepare_send_message ($self, 'message', 'login', undef, undef, $operator_id, $message_ip, undef, join('\n', @service));

	    $self->agi->control_stream_file($config->{"voice.yourein"});
	    sys_addlog("Оператор $operator_id вошел в систему");
	}
	if($event eq "logout") {
	    my $channel = sys_request('channel_by_operator_id', $operator_id);
	    my $message_ip = sys_request('ip_by_sip', $channel);
	    sys_prepare_send_message ($self, 'message', 'logout', undef, undef, undef, $message_ip);
	    sys_request('operator_logout', $operator_id);
	    $self->agi->control_stream_file($config->{"voice.youreout"});
	    sys_addlog("Оператор $operator_id вышел из системы");
	}
    }

    sys_db_disconnect();
}


=head local_call, local_after
 Локальные звонки оператора. Для примера - звонки только на четырехзначный номер.
 exten => _XXXX,1,Answer()
 exten => _XXXX,n,agi(agi://127.0.0.1/local_call)
 exten => _XXXX,n,Hangup()

 [local]
 exten => _X.,1,Answer()
 exten => _X.,n,Dial(SIP/${EXTEN},60,g)
 exten => h,1,DeadAGI(agi://127.0.0.1/local_after?answertime=${ANSWEREDTIME})
 exten => h,n,Hangup()
=cut
sub local_call {
    sys_db_connect();

    my $self = shift;
    $log_uniqueid = $self->{server}->{agi}->{env}->{uniqueid};
    my $params = $self->{server}->{agi}->{env};

    my $call_is_transfered = 0;

    my ($phone_from, $phone_to) = ($params->{callerid}, $params->{extension});
    my $operator = sys_request('operator_id_by_channel_like', '%/'.$phone_from);
    my $operator_to = sys_request('operator_id_by_channel_like', '%/'.$phone_to);

    unless ( sys_request('operator_is_outgoing_calls', $operator) ) {
	$self->agi->hangup;
	return 0;
    }

    $self->agi->set_variable('local_number_from', $phone_from);
    $self->agi->set_variable('local_number_to', $phone_to);
    $self->agi->set_variable('local_begin_time', time());
    $self->agi->set_variable('local_to_bussy', 0);

#если звонит залогиненный оператор
    if(defined $operator) {
	$self->agi->set_variable('local_operator_from', $operator);
	my @operator_values = sys_request('operator_values', $operator);
	my $phone_transfered = $operator_values[0][0];
	my $operator_status = sys_request('operator_is_login', $operator);
	sys_request('operator_status', $operator, 9, $phone_to, 0, $params->{channel}) if($operator_status==1);
#если в это время оператор занят, то выполняется трансфер
	if($operator_status==4) {
	    $call_is_transfered = 1;
#	    my $callerid_name = $self->agi->get_full_variable('CallerIdName', $operator_values[0][2]);
#	    sys_addlog("CALLERID(name) = $callerid_name");
#	    my $caller_prefix = '';
#	    $caller_prefix = $1 if( $callerid_name =~ /^([KMBL])/ );
	    my $operator_password = sys_request('operator_password_by_id', $operator);
	    $self->agi->set_variable('local_incoming_number', $phone_transfered);
	    $self->agi->set_variable('local_transfer_operator_password', $operator_password);
	    $self->agi->database_put('transfer', $phone_transfered.'.'.$operator_password, 1);
	    $self->agi->database_put('transfer_begin_time', $phone_transfered.'.'.$operator_password, time());
#	    $self->agi->database_put('prefix', $phone_transfered.'.'.$operator_password, $caller_prefix);
	}
    }

#если звонок на залогиненого оператора
    if(defined $operator_to) {
	my $operator_to_status = sys_request('operator_is_login', $operator_to);
	if($operator_to_status!=1) {
	    $self->agi->set_variable('local_to_bussy', 1);
	    $self->agi->hangup();
	} else {
	    sys_request('operator_status', $operator_to, 8, $phone_from, 0, $params->{channel});
	}
    }

    $self->agi->set_variable('call_is_transfered', $call_is_transfered);

#пишем в логи трансфер или локальный звонок
    if($call_is_transfered == 1) {
	sys_addlog("VERBOSE: transfer from $phone_from ($operator) to $phone_to ($operator_to)");
    } else {
	sys_addlog("VERBOSE: local call from $phone_from ($operator) to $phone_to ($operator_to)");
    }

    sys_db_disconnect();
}

sub local_after {
    sys_db_connect();

    my $self = shift;
    $log_uniqueid = $self->{server}->{agi}->{env}->{uniqueid};
    my $params = $self->{server}->{agi}->{env};

    my($time_begin, $acdgroup, $extension) = (time(), 0, 0);

#выбираем значения из переменных Asterisk и находим операторов
    my $is_transfered = $self->agi->get_variable('call_is_transfered');
    my $phone_from = $self->agi->get_variable('local_number_from');
    my $phone_to = $self->agi->get_variable('local_number_to');
    my $transfer_done = 0;
    my $callfilename = $self->agi->get_variable('CALLFILENAME');

#Если трансфер, вычисляем начало и общее время разговора
    if($is_transfered == 1) {
	my $phone_transfered = $self->agi->get_variable('local_incoming_number');
	my $operator_password = $self->agi->get_variable('local_transfer_operator_password');

	my $acdgroup = $self->agi->database_get('acdgroup', $phone_transfered.'.'.$operator_password);
	$self->agi->database_del('acdgroup', $phone_transfered.'.'.$operator_password);
	my $extension = $self->agi->database_get('extension', $phone_transfered.'.'.$operator_password);
	$self->agi->database_del('extension', $phone_transfered.'.'.$operator_password);
	my $time_begin = $self->agi->database_get('transfer_begin_time', $phone_transfered.'.'.$operator_password);
	$self->agi->database_del('transfer_begin_time', $phone_transfered.'.'.$operator_password);
	$transfer_done = $self->agi->database_get('transfer', $phone_transfered.'.'.$operator_password);
	$self->agi->database_del('transfer', $phone_transfered.'.'.$operator_password);
	my $transfer_prefix = $self->agi->database_get('prefix', $phone_transfered.'.'.$operator_password);
	$self->agi->database_del('prefix', $phone_transfered.'.'.$operator_password);

#Если трансфер произошел (первый агент повесил трубку, освободился, статистика в базу занеслась)
	if($transfer_done==2) {
	    my $time_total = time() - $time_begin;
	    my $answeredtime = $time_total;
	    my $time_total_queue = 0;
	    my $queue_maximum = 0;
	    sys_request('calls_log', join("`",($phone_transfered, $operator_password, $time_begin, 0, $time_total, $answeredtime, $time_total_queue, $queue_maximum, $acdgroup, $extension, 0, $phone_to, $transfer_prefix)));
	    sys_addlog("VERBOSE: End of transfer. Caller $phone_transfered calls to $operator_password. Answered time: $answeredtime");
	    sys_callers_dump($phone_transfered, "конец трансфера. время ответа $answeredtime.");
	}
    }

#Записываем статистику операторов и освобождаем операторов от локального и от трансфера
    my $operator = sys_request('operator_id_by_channel_like', '%/'.$phone_from);
    my $operator_to = sys_request('operator_id_by_channel_like', '%/'.$phone_to);
    my $time_begin = $self->agi->get_variable('local_begin_time');

    return 0 unless sys_request('operator_is_outgoing_calls', $operator);

    if(defined $operator) {
	my $operator_status = sys_request('operator_is_login', $operator);
	sys_request('operator_status', $operator, 1, '', 0, '') if($operator_status==9);
#Записываем статистику локальных, если трансфер не состоялся
	if($transfer_done!=2) {
	    my $total_time = time()-$time_begin;
	    my $wait_time = 0;
	    my $event = 31;
	    if ( $self->agi->get_variable('DIALSTATUS') =~ /^(BUSY)|(NOANSWER)|(CANCEL)|(CONGESTION)$/ ) {
		($total_time, $wait_time) = ($wait_time, $total_time);
		$callfilename = '';
		$event = 36;
	    }
	    sys_request('operator_events', $operator, $event, $phone_to, join("`",($total_time, 0, 0, $wait_time, 0, $time_begin, $callfilename)));
	}
    }

    if(defined $operator_to) {
	my $operator_to_status = sys_request('operator_is_login', $operator_to);
	sys_request('operator_status', $operator_to, 1, '', 0, '') if($operator_to_status==8 && $self->agi->get_variable('local_to_bussy')==0);
#Записываем статистику локальных входящих, если трансфер не состоялся и звонил незалогиненный оператор на залогиненного
	unless($transfer_done==2 || defined $operator) {
	    sys_request('operator_events', $operator_to, 32, $phone_from, join("`",(time()-$time_begin, 0, 0, 0, 0, $time_begin)));
	}
    }

    sys_db_disconnect();
}


=head sys_get_free_operators
 Выдаем список операторов, готовых ответить на вызов сервиса $service, отсортированный согласно стратегии $strategy
 Полезен для удаленного сервера
=cut
sub sys_get_free_operators {
    my ( $service, $strategy, @exclude ) = @_;
    my @operators = sys_request('operators_free_online', $strategy, $service);
    return @operators;
}

=head sys_get_free_operator
 Из списка операторов берем первого
=cut
sub sys_get_free_operator {
    my ( $service, $strategy, @exclude ) = @_;
    my @operators = sys_get_free_operators($service, $strategy);
    return $operators[0][0];
}

=head incoming_call
 Получаем звонок, заводим в буфер, получаем id в буфере
 Сохраняем всю информацию, которая будет востребована в последствии, в том числе и конфиги сохраняем в локальные переменные
 Отсутствующие параметры конфигурации заменяются параметрами из раздела default (см. файл-конфиг)
 Проверяем и удаляем из очереди, если превышен лимит в очереди
 Отправляем на контекст buffer, который будет опрашивать процедурой incoming_buffer на предмет доступности операторов очереди queue
 Пример:
    [incoming_calls]
    exten => s,1,Ringing()
    exten => s,2,agi(agi://127.0.0.1/incoming_call?queue=453-Kyiv&acdgroup=453)
    exten => s,n,GotoIf($[${BussyCall}=0]?100:10)
    exten => s,10,Wait(1)
    exten => s,n,Goto(2)
    exten => s,100,Hangup()
=cut
sub incoming_call {

    sys_db_connect();

	my $self = shift;
	$log_uniqueid = $self->{server}->{agi}->{env}->{uniqueid};
	$self->agi->set_variable('BeginTime', time());
	
	my $queue = $self->param('queue');
	my $acdgroup = $self->param('acdgroup');
	my $caller_id = $self->{server}->{agi}->{env}->{callerid};
	$caller_id = 0 if($caller_id eq 'unknown' || $caller_id eq 'Unknown' || $caller_id eq '80anonymous');

	sys_callers_dump($caller_id, "поступил звонок - группа $acdgroup");
	$self->agi->set_variable('ClientCallerID', $caller_id);

	$self->agi->set_variable('OperatorHangup', 0);
	$self->agi->set_variable('Extension', $self->{server}->{agi}->{env}->{extension});
	$self->agi->set_variable('uniqueid', $self->{server}->{agi}->{env}->{uniqueid});
#	$self->agi->set_variable('Channel', $self->{server}->{agi}->{env}->{channel});
	
	my @srv_all = sys_request('get_service_by_service_name', $queue);
	my $client_id = sys_request('client_queue_add', $srv_all[0][2], $srv_all[0][0], $caller_id, $self->{server}->{agi}->{env}->{channel});

	$self->agi->set_variable('ClientID', $client_id);
	$self->agi->set_variable('ClientSrvID', $srv_all[0][2]);
	$self->agi->set_variable('ClientSrvWeight', $srv_all[0][0]);
	$self->agi->set_variable('ClientSrvAccessType', $srv_all[0][3]);
	$self->agi->set_variable('ClientSrv', $queue);
	$self->agi->set_variable('CallerIdName', $self->{server}->{agi}->{env}->{calleridname});
	$self->agi->set_variable('ACDGroup', $acdgroup);
	$self->agi->set_variable('ClientWhiteList', 1) if(sys_request('check_white_list', $caller_id, $queue));
	if(sys_request('check_black_list', $caller_id, $queue)==1) {
	    sys_addlog("Черный список: Входящий звонок от $caller_id группа $acdgroup");
	    sys_callers_dump($caller_id, "Номер в черном списке");
	    $self->agi->set_variable('BussyCall', 9);
	} else {
	    $self->agi->set_variable('BussyCall', 0);
	}
	$self->agi->set_variable('WaitQueue', 1);

	if(defined $config->{"operators.$queue.backvoice"}){ $self->agi->set_variable('ClientBackVoice', $config->{"operators.$queue.backvoice"}); } 
	else { $self->agi->set_variable('ClientBackVoice', $config->{"operators.default.backvoice"}); }
	
	if(defined $config->{"operators.$queue.strategy"}){ $self->agi->set_variable('ClientStrategy', $config->{"operators.$queue.strategy"}); } 
	else { $self->agi->set_variable('ClientStrategy', $config->{"operators.default.strategy"}); }
	
	if(defined $config->{"operators.$queue.timeout"}){ $self->agi->set_variable('ClientTimeout', $config->{"operators.$queue.timeout"}); } 
	else { $self->agi->set_variable('ClientTimeout', $config->{"operators.default.timeout"}); }
	
	if(defined $config->{"operators.$queue.background"}){ $self->agi->set_variable('ClientBackground', $config->{"operators.$queue.background"}); } 
	else { $self->agi->set_variable('ClientBackground', $config->{"operators.default.background"}); }

	if(defined $config->{"operators.$queue.queue-maximum"}){ $self->agi->set_variable('ClientQueue-Maximum', $config->{"operators.$queue.queue-maximum"}); } 
	else { $self->agi->set_variable('ClientQueue-Maximum', $config->{"operators.default.queue-maximum"}); }

	if(defined $config->{"operators.$queue.delay"}){ $self->agi->set_variable('ClientDelay', $config->{"operators.$queue.delay"}); } 
	else { $self->agi->set_variable('ClientDelay', $config->{"operators.default.delay"}); }

	if(defined $config->{"operators.$queue.duration"}){ $self->agi->set_variable('ClientDuration', $config->{"operators.$queue.duration"}); } 
	else { $self->agi->set_variable('ClientDuration', $config->{"operators.default.duration"}); }

	if(defined $config->{"operators.$queue.deadqueue"}){ $self->agi->set_variable('ClientDeadqueue', $config->{"operators.$queue.deadqueue"}); } 
	else { $self->agi->set_variable('ClientDeadqueue', $config->{"operators.default.deadqueue"}); }

	if(defined $config->{"operators.$queue.deadtime"}){ $self->agi->set_variable('ClientDeadtime', $config->{"operators.$queue.deadtime"}); } 
	else { $self->agi->set_variable('ClientDeadtime', $config->{"operators.default.deadtime"}); }

	if(defined $config->{"operators.$queue.nooperators"}){ $self->agi->set_variable('ClientNoOperators', $config->{"operators.$queue.nooperators"}); } 
	else { $self->agi->set_variable('ClientNoOperators', $config->{"operators.default.nooperators"}); }

	if(defined $config->{"operators.$queue.hangup"}){ $self->agi->set_variable('OperatorsMaxHangup', $config->{"operators.$queue.hangup"}); } 
	else { $self->agi->set_variable('OperatorsMaxHangup', $config->{"operators.default.hangup"}); }

	if($self->agi->get_variable('ClientBackVoice')!=0) {
	    $self->agi->set_variable('ClientBackVoiceTime', $self->agi->get_variable('ClientBackVoice')+time());
	}

	my $queue_place = sys_request('client_queue_place', $client_id, $srv_all[0][2]);

	if($queue_place>$self->agi->get_variable('ClientQueue-Maximum') && $self->agi->get_variable('ClientQueue-Maximum')!=0){
	    sys_request('client_queue_remove', $client_id);
	    sys_request('calls_log', join("`",($caller_id, '0', time(), '4', '0', '0', '0', $self->agi->get_variable('ClientQueue-Maximum'), $acdgroup, $self->{server}->{agi}->{env}->{context}, 0, 0, '')));
	    sys_callers_dump($caller_id, "звонок удален из очереди - превышен лимит ClientQueue-Maximum");
	    $self->agi->hangup();
	}

	sys_addlog("Входящий звонок от $caller_id группа $acdgroup");

	if($self->agi->get_variable('ClientBackground') ne 'no') {
	    my $bg_music = $self->agi->get_variable('ClientBackground');
	    $self->agi->set_music("on", $bg_music);
	    sys_addlog("Запустили фоновую музыку $bg_music");
	}

# Смотрим, стал ли в очередь звонок
	my @next_id_m = sys_request('client_queue_next', $srv_all[0][2]);
	my $que = 0;
	foreach my $id (@next_id_m)
	{
    	    $que = 1 if($id->[0]==$client_id);
	}
	if($que == 0) {
	    sys_callers_dump($caller_id, "встал в очередь с номером $client_id");
	}

	if($config->{"main.asterisk_version"} eq '1.6' || $config->{"main.asterisk_version"} eq '1.8') {
	    my $d = $self->agi->exec('Goto', 'buffer,'.$self->{server}->{agi}->{env}->{extension}.',1');
	} else {
	    my $d = $self->agi->exec('Goto', 'buffer|'.$self->{server}->{agi}->{env}->{extension}.'|1');
	}

    sys_db_disconnect();

}
=head incoming_buffer
 Звонок клиента в буфере, asterisk опрашивает, первый ли звонок в очереди (таблица queues, поле que_bussy=0, сортировка по que_id).
 Если так, то выбирает доступного оператора (функция sys_get_free_operator($service)), устанавливает переменную BussyCall и звонит на OperatorId канала OperatorChan
 Голос звучит, если в конфиге прописан интервал, отличный от 0 (см. файл-конфиг)
 
    [buffer]
    exten => s,1,agi(agi://127.0.0.1/incoming_buffer)
    exten => s,n,GotoIf($[${BussyCall}=1]?incoming_after,${OperatorId},${OperatorChan}:10)
    exten => s,10,Wait(1)
    exten => s,n,Goto(1)
    exten => h,1,DeadAGI(agi://127.0.0.1/incoming_after?answertime=${ANSWEREDTIME}&dialstatus=${DIALSTATUS})
    exten => h,n,Hangup()

    [incoming_after]
    exten => _X.,10(SIP),Dial(SIP/${EXTEN},${ClientDuration},gj)
    exten => _X.,n,Goto(1000)
    exten => _X.,111,Goto(1000)
    exten => _X.,1000,agi(agi://127.0.0.1/incoming_busy)
    exten => h,1,DeadAGI(agi://127.0.0.1/incoming_after?answertime=${ANSWEREDTIME}&dialstatus=${DIALSTATUS})
    exten => h,n,Hangup()

=cut
sub incoming_buffer {

	my $self = shift;
	$log_uniqueid = $self->{server}->{agi}->{env}->{uniqueid};
	
	sys_db_connect();

#sys_addlog(dump $self);
#sys_addlog(dump $self->agi->channel_status($self->{server}->{agi}->{env}->{channel}));

	my $client_id = $self->agi->get_variable('ClientID');
	my $service_id = $self->agi->get_variable('ClientSrvID');
	my $service_name = $self->agi->get_variable('ClientSrv');
	my $service_weight = $self->agi->get_variable('ClientSrvWeight');
	my $service_access_type = $self->agi->get_variable('ClientSrvAccessType');
	my $deadqueue = $self->agi->get_variable('ClientDeadqueue');
	my $caller_id = $self->agi->get_variable('ClientCallerID');
	my $operators_free_count = 0;

	if($self->agi->get_variable('ClientBackground') ne 'no') {
	    my $bg_music = $self->agi->get_variable('ClientBackground');
	    $self->agi->set_music("on", $bg_music);
	}

	my $queue_place = sys_request('client_queue_place', $client_id, $service_id);
	sys_request('client_queue_carry', $client_id, $deadqueue);
	$self->agi->set_variable('QueueMaximum', $queue_place) if($self->agi->get_variable('QueueMaximum')<$queue_place);

	#Засекаем время очереди (если будет)
	if($self->agi->get_variable('TimeQueue') eq '') { 
	    $self->agi->set_variable('TimeQueue', 0);
	    $self->agi->set_variable('TimeQueueBegin', 0);
	}
	if($self->agi->get_variable('TimeQueueBegin')==0) { 
	    $self->agi->set_variable('TimeQueueBegin', time());
	}

	my $acdgroup = $self->agi->get_variable('ACDGroup');

	#Выбираем из очереди, кто следующий и оператора для него
	my $next_id;
	my @next_id_m = sys_request('client_queue_next', $service_id);
	foreach my $id (@next_id_m)
	{
    	    $next_id = $client_id if($id->[0]==$client_id);
	}
	my $all_bussy = 1;

### noch a v podvorotne kak polojeno temno
	$operators_free_count = sys_request('operators_online', $service_name, 'free');

### pop the poo убираем неприоритетных
	if(time()-$self->agi->get_variable('TimeQueueBegin')>3) {
	    my @service_id = sys_request('get_service_by_service_name', $service_name);
	    if ($service_id[0][2]>=100 && $operators_free_count==0) {
		my $channel = sys_request('pop_the_poo', $service_name);
		$self->agi->hangup($channel) if ($channel);
	    }
	}

	my $operators_server = '';
	##Если просмотр серверов == [2,3] - сначала поиск на серверах
	if($service_access_type == 2 || $service_access_type == 3 || $operators_free_count==0) {
	    $operators_server = sys_get_foreign_server($service_name);
	}
	##Узнаем, сколько свободных операторов по службе
	if($operators_server eq ''){
	    $operators_free_count = sys_request('operators_online', $service_name, 'free');
	} else {
	    sys_db_connect($operators_server);
	    $operators_free_count = sys_request('operators_online', $service_name, 'free', $operators_server);
	}
	#если ваш id - это первый id в очереди... и поиск на локальном разрешен
	if(($next_id==$client_id || $operators_server ne '') && $service_access_type != 3) {
	    my $operator = 0;
	    ##Если вес очереди != 0, либо на серверах нет операторов, смотрим локально
	    if($operators_server eq ''){
		$operator = sys_get_free_operator($service_id, $self->agi->get_variable('ClientStrategy'));
	    }
	    #найден оператор по id вашей службы
	    if($operator != 0) {
	    
		$all_bussy = 0;
		my $is_free = 0;
		if($self->agi->channel_status($self->{server}->{agi}->{env}->{channel})!=-1){
		    $is_free = sys_request('operator_status', $operator, 4, $caller_id, $service_id, $self->{server}->{agi}->{env}->{channel});
		}
		sys_addlog("ERROR: Оператор уже занят") if ($is_free != 1);
		if ($is_free != 0) {
			my $queue_time_session = time()-$self->agi->get_variable('TimeQueueBegin');
			$self->agi->set_variable('TimeQueue', $self->agi->get_variable('TimeQueue')+$queue_time_session);
			$self->agi->set_variable('TimeQueueBegin', 0);
			
			$self->agi->set_variable('Operator', $operator);
			my $channel = sys_request('channel_by_operator_id', $operator);
			my @extension = split('/',$channel);

			$self->agi->set_variable('OperatorId', $extension[1]);
			$self->agi->set_variable('OperatorChan', $extension[0]);
			$self->agi->set_variable('OperatorBeginTime', time());
			$self->agi->set_variable('CallIsRemote', 0);
			$self->agi->set_variable('CallIsRemoteServer', '');
			$self->agi->set_variable('BussyCall', 1);
			$self->agi->set_variable('WaitQueue', 1);
			
			sys_request('client_queue_bussy', $client_id, $operator);

			my $operator_password = sys_request('operator_password_by_id', $operator);
			$self->agi->set_variable('OperatorPassword', $operator_password);

			my $message_ip = sys_request('ip_by_sip', $channel);
			my $callfilename = $self->agi->get_variable('CALLFILENAME');
			my $callExtension = $self->agi->get_variable('Extension');
			my $calluniqueid = $self->agi->get_variable('uniqueid');
			sys_prepare_send_message ($self, 'message', 'before', $self->{server}->{agi}->{env}->{calleridname}, $service_id, $operator, $message_ip, $caller_id, 0, $callfilename, $callExtension, $calluniqueid );

			sys_addlog("Нашли оператора $operator_password (".$extension[0]."/".$extension[1].") для клиента $client_id");
			sys_callers_dump($caller_id, "звонок передан оператору $operator_password (".$extension[0]."/".$extension[1].")");

		}
	    #Если не найден оператор, необходимо искать на удаленных серверах если разрешено	
	    } elsif($service_access_type != 1) {
		my $queue_time = -1;
		if($operators_server eq ''){
		    my $operators_count = sys_request('operators_online', $service_name);
		    my $queue_total = sys_request('client_queue_total', $service_id);
		    if($operators_count!=0) {
			$queue_time = $queue_total*$config->{"server.middletime"}/$operators_count;
			$queue_time = -1 if($queue_time >= $config->{"server.queuetime"});
		    }
		}
		#Если время в очереди слишком большое
		if($queue_time==-1){
		    my $operators_server = sys_get_foreign_server($service_name);
		    sys_db_connect($operators_server);
		    #Нашли сервер $operators_server с максимальным кол-вом операторов для службы $acdgroup
		    if($operators_server ne ''){
			#Резервируем оператора
			my $channel = '';
			my $is_free = 0;
			my $operator_password = '';
			    my @service_id = sys_request('get_service_by_service_name', $service_name, $operators_server);
			    my @operators = sys_request('operators_free_online', $self->agi->get_variable('ClientStrategy'), $service_id[0][2], $operators_server);
			    $operator = $operators[0][0];
			    if($self->agi->channel_status($self->{server}->{agi}->{env}->{channel})!=-1){
				$is_free = sys_request('operator_status', $operator, 4, $caller_id, $service_id[0][2], "external", $operators_server);
			    }
			    $channel = sys_request('channel_by_operator_id', $operator, $operators_server);
			    $operator_password = sys_request('operator_password_by_id', $operator, $operators_server);
		      
		      sys_addlog("ERROR: Оператор уже занят") if ($is_free != 1);

		      if($operator_password ne '' && $is_free!=0){
			#Тут подготовка и отправка на звонок
			$all_bussy = 0;
			my $queue_time_session = time()-$self->agi->get_variable('TimeQueueBegin');
			$self->agi->set_variable('TimeQueue', $self->agi->get_variable('TimeQueue')+$queue_time_session);
			$self->agi->set_variable('TimeQueueBegin', 0);
			
			$self->agi->set_variable('Operator', $operator_password);
			my @extension = split('/',$channel);

			$self->agi->set_variable('OperatorId', $extension[1]);
			$self->agi->set_variable('OperatorChan', $config->{"servers.$operators_server.prefix"});
			$self->agi->set_variable('OperatorBeginTime', time());
			$self->agi->set_variable('CallIsRemote', 1);
			$self->agi->set_variable('CallIsRemoteServer', $operators_server);
			$self->agi->set_variable('BussyCall', 1);
			$self->agi->set_variable('WaitQueue', 1);
			
			
			$self->agi->set_variable('OperatorPassword', $operator_password);

			my $callfilename = $self->agi->get_variable('CALLFILENAME');
			$callfilename = '-' if($callfilename eq '');
			my $callExtension = $self->agi->get_variable('Extension');
			my $calluniqueid = $self->agi->get_variable('uniqueid');

			sys_send_command("op send message before $operator_password ".$self->{server}->{agi}->{env}->{calleridname}." $service_name $channel $caller_id $callfilename $callExtension $calluniqueid", $config->{"servers.$operators_server.ip"}, $config->{"servers.$operators_server.port"});

			sys_addlog("Нашли удаленного оператора $operator_password (".$extension[0]."/".$extension[1].") с сервера $operators_server для клиента $client_id");
			sys_callers_dump($caller_id, "звонок передан удаленному оператору $operator_password (".$extension[0]."/".$extension[1].") с сервера $operators_server");

			sys_db_connect();
			sys_request('client_queue_bussy', $client_id, $operator_password);
		      }
		    }
		}
	    
	    } 
	} 

	#Иначе, если в очереди и нет оператора
	if($all_bussy == 1) {
#		$self->agi->set_variable('WaitQueue', 0) if($operators_free_count>1);
		#Голос через определенное время
		if($self->agi->get_variable('ClientBackVoice')!=0) {
		    my $client_backvoice = $self->agi->get_variable('ClientBackVoiceTime');
		    if( $client_backvoice<time() ){
##сообщаем, сколько времени осталось в очереди - в секундах или минутах
=delete old voice message
			my $operators_count = sys_request('operators_online', $service_name);
			my $queue_time = $self->agi->get_variable('ClientDeadtime');
			if($operators_count!=0) {
			    $queue_time = int($queue_place*$config->{"server.middletime"}/$operators_count);
			} else {
			    $self->agi->exec('Answer');
			    $self->agi->stream_file($self->agi->get_variable('ClientNoOperators'));
			    $self->agi->stream_file('ru/pls-try-call-later');
			    $self->agi->exec('Hangup');
			}
			
			if($queue_time>=0){
			    my $add_operator = 'ov';
			    my $add_second = '';
			    my @digit_s;

			    $operators_count =~ /(\d)$/;
			    if($operators_count<11 || $operators_count>19) {
			        $add_operator = '' if ($1 == 1);
			        $add_operator = 'a' if (grep (/[234]/,$1) );
			    }

			    $queue_time =~ /(\d)$/;
			    if($queue_time<11 || $queue_time>19) {
			        $add_second = 'u' if ($1 == 1);
			        $add_second = 'i' if (grep (/[234]/,$1) );
			    }
			    @digit_s[1] = 'u' if ($1 == 1);
			    @digit_s[2] = 'e' if ($1 == 2);

			    $self->agi->exec('Answer');
			    sys_stream_file($self, 'wait-voice/00_Start');
			    sys_say_number ($self, $operators_count,'wait-voice/digits/');
			    sys_stream_file($self, "wait-voice/operator".$add_operator);
			    sys_stream_file($self, 'wait-voice/01_Propose');
			    sys_say_number ($self, $queue_time,'wait-voice/digits/',@digit_s);
			    sys_stream_file($self, "wait-voice/sekund".$add_second);
			    sys_stream_file($self, 'wait-voice/02_Recall');
			    $self->agi->exec('Ringing');
			}
=cut
			my $operators_count = sys_request('operators_online', $service_name);
			my $queue_time = $self->agi->get_variable('ClientDeadtime');
			if($operators_count!=0) {
			    $queue_time = int($queue_place*$config->{"server.middletime"}/$operators_count);
			}
			if($queue_time>=20){
			    $self->agi->exec('Answer');
			    sys_stream_file($self, '453/queue_sound');
			    $self->agi->exec('Ringing');
			    $self->agi->set_variable('ClientBackVoiceTime', $self->agi->get_variable('ClientBackVoice')+time());
			    sys_callers_dump($caller_id, "голосовое сообщение в очереди");
			}
		    }
		}
	    }
    sys_db_disconnect();
}

=head incoming_busy
 Если линия занята (оператор поднял трубку просто так) соединение не разрывается
 Штраф оператора - поднята труба просто так (operator_events,51)
 Штраф оператора - непринятый звонок за отведенное время (operator_events,52)
 Штраф оператора - непринятый звонок (operator_events,53)
 Штраф оператора - не занят и не ответил (operator_events,59)
 Переводим звонок на другого оператора.
=cut
sub incoming_busy {
    my $self = shift;
    $log_uniqueid = $self->{server}->{agi}->{env}->{uniqueid};
    sys_db_connect();

    if($self->agi->get_variable('DIALSTATUS') ne "ANSWER") {
	my $CallIsRemote = $self->agi->get_variable('CallIsRemote');
	my $operator = $self->agi->get_variable('Operator');
	my $operator_password = $self->agi->get_variable('OperatorPassword');
	my $extension = $self->agi->get_variable('Extension');
	my $time_begin = $self->agi->get_variable('BeginTime');
	my $caller_id = $self->agi->get_variable('ClientCallerID');

	
	if($CallIsRemote==1) {
		my $operators_server = $self->agi->get_variable('CallIsRemoteServer');
		sys_db_connect($operators_server);
		my $operator_id = sys_request('operator_id_by_password', $operator, $operators_server);
		sys_request('operator_status', $operator_id, 1, '', 0, '', $operators_server);
		$self->agi->set_variable('Operator', 0);
		$self->agi->set_variable('OperatorPassword', 0);
		sys_callers_dump($caller_id, "Удаленный оператор $operator_password сервера $operators_server не ответил на звонок");
	} else {
		sys_request('operator_login_addtime', $operator, $self->agi->get_variable('ClientDelay'));
		if($self->agi->get_variable('DIALSTATUS') eq "BUSY") {
		    sys_request('operator_events', $operator, 51, $caller_id);
		    sys_addlog("Оператор $operator_password получает штраф за поднятую трубу");
		    sys_callers_dump($caller_id, "у оператора $operator поднята трубка");
		} elsif ($self->agi->get_variable('DIALSTATUS') eq "NOANSWER") {
		    sys_request('operator_events', $operator, 52, $caller_id, join("`",(0,$self->agi->get_variable('ACDGroup') ,$self->agi->get_variable('Extension') ,$self->agi->get_variable('ClientDuration'), 0, $time_begin)));
		    sys_request('operator_login_add_timecall', $operator, 0);
		    sys_request('operator_login_addtime', $operator, 2);
		    $self->agi->set_variable('Operator', 0);
		    $self->agi->set_variable('OperatorPassword', 0);
		    sys_addlog("Оператор $operator_password получает штраф за неотвеченный вовремя звонок");
		    sys_callers_dump($caller_id, "оператор $operator_password не ответил на звонок");

		    my $channel = sys_request('channel_by_operator_id', $operator);
		    my $message_ip = sys_request('ip_by_sip', sys_request('channel_by_operator_id', $operator));
		    sys_prepare_send_message ($self, 'message', 'lost', undef, undef, undef, $message_ip );

		} else {
		    sys_request('operator_events', $operator, 59, $caller_id);
		}
		sys_request('operator_status', $operator, 1);
	}
	$self->agi->set_variable('BussyCall', 0);
	$self->agi->set_variable('WaitQueue', 1);
	sys_db_connect() if($CallIsRemote==1);
	sys_request('client_queue_bussy', $self->agi->get_variable('ClientID'), 0);
	if($config->{"main.asterisk_version"} eq '1.6' || $config->{"main.asterisk_version"} eq '1.8') {
	    $self->agi->exec('Goto', 'buffer,'.$extension.',1');
	} else {
	    $self->agi->exec('Goto', 'buffer|'.$extension.'|1');
	}
    }

    if($self->agi->get_variable('DIALSTATUS') eq "ANSWER") {
	if($self->agi->get_variable('ANSWEREDTIME')>$self->agi->get_variable('OperatorsMaxHangup')){
	    $self->agi->set_variable('OperatorHangup', 10);
	}
    }

    sys_db_disconnect();

}

=head incoming_after
 После звонка. Удаляем клиента из очереди. Записываем информацию в статистику.
=cut
sub incoming_after {
	my $self = shift;
	$log_uniqueid = $self->{server}->{agi}->{env}->{uniqueid};

	sys_db_connect();
	
	my $CallIsRemote = $self->agi->get_variable('CallIsRemote');
	my $operators_server = $self->agi->get_variable('CallIsRemoteServer');
	my $operator_password = $self->agi->get_variable('OperatorPassword');
	my $operator_hangup = $self->agi->get_variable('OperatorHangup');

	if($self->agi->get_variable('TimeQueueBegin')!=0) { 
	    my $queue_time_session = time()-$self->agi->get_variable('TimeQueueBegin');
	    $self->agi->set_variable('TimeQueue', $self->agi->get_variable('TimeQueue')+$queue_time_session);
	    $self->agi->set_variable('TimeQueueBegin', 0);
	}
	my $time_begin = $self->agi->get_variable('BeginTime');
	my $time_total = time()-$time_begin;
	
	my $dialstatus = $self->agi->get_variable('DIALSTATUS');
	my $sound_before_dial = $self->agi->get_variable('presound');
	my $callfilename = $self->agi->get_variable('CALLFILENAME');

	sys_request('client_queue_remove', $self->agi->get_variable('ClientID'));
	
	my $time_total_queue = $self->agi->get_variable('TimeQueue');
	
	my $params = $self->{server}->{agi}->{env};
	my $caller_id = $self->agi->get_variable('ClientCallerID');
	my $operator = $self->agi->get_variable('Operator');
	
	my $answeredtime = 0;
	if($self->agi->database_get('transfer', $caller_id.'.'.$operator_password)==1) {
	    $answeredtime = $self->agi->database_get('transfer_begin_time', $caller_id.'.'.$operator_password) - $time_begin;
	} else {
	    $answeredtime = $self->agi->get_variable('ANSWEREDTIME');
	    $answeredtime = 0 if(!defined $answeredtime);
	}

	my $acdgroup = $self->agi->get_variable('ACDGroup');
	my $queue_maximum = 0;
	$queue_maximum = $self->agi->get_variable('QueueMaximum') if($time_total_queue!=0);
	my $extension = $self->agi->get_variable('Extension');

	my $status = 0;
	if($dialstatus eq 'CANCEL' || $dialstatus eq 'NOANSWER') {
	    $status = 3;
	} elsif ($dialstatus eq '') {
	    $status = 2;
	}
	
	my $operator_password = '';

	if($CallIsRemote==1) {
		my $operators_server = $self->agi->get_variable('CallIsRemoteServer');
		sys_db_connect($operators_server);
		    $operator_password = $operator;
		    my $operator_id = sys_request('operator_id_by_password', $operator, $operators_server);
		    $operator_id=0 if ($operator eq '');
		    if($dialstatus eq "ANSWER") {
			sys_request('operator_login_addtime', $operator_id, $self->agi->get_variable('ClientTimeout'), $operators_server);
			sys_request('operator_login_add_timecall', $operator_id, $answeredtime, $operators_server);
			sys_request('operator_events', $operator_id, 10, $caller_id, join("`",($answeredtime, $acdgroup, $extension, time()-$self->agi->get_variable('OperatorBeginTime')-$answeredtime, $operator_hangup, $time_begin, $callfilename)), $operators_server);
#			sys_send_command("op send message endcall $operator_id - - $operator - - - -", $config->{"servers.$operators_server.ip"}, $config->{"servers.$operators_server.port"});
		    } else {
			sys_request('operator_events', $operator_id, 53, $caller_id, join("`",($answeredtime, $acdgroup, $extension, time()-$self->agi->get_variable('OperatorBeginTime')-$answeredtime, $operator_hangup, $time_begin)), $operators_server);
		    }
		    my $is_free = sys_request('operator_status', $operator_id, 1, '', 0, '', $operators_server);
		    sys_request('operator_status', $operator_id, 3, '', 0, '', $operators_server) if ($is_free==0);
	} else {
		if($dialstatus eq "ANSWER") {
		    sys_request('operator_login_addtime', $operator, $self->agi->get_variable('ClientTimeout'));
		    sys_request('operator_login_add_timecall', $operator, $answeredtime);
	sys_addlog(join("`",($answeredtime, $acdgroup, $extension, time()-$self->agi->get_variable('OperatorBeginTime')-$answeredtime, $operator_hangup, $time_begin)));
		    sys_request('operator_events', $operator, 10, $caller_id, join("`",($answeredtime, $acdgroup, $extension, time()-$self->agi->get_variable('OperatorBeginTime')-$answeredtime, $operator_hangup, $time_begin, $callfilename)));
		    my $is_free = sys_request('operator_status', $operator, 1);
		    sys_request('operator_status', $operator, 3) if ($is_free==0);

		    my $channel = sys_request('channel_by_operator_id', $operator); 
		    my $message_ip = sys_request('ip_by_sip', $channel); 
		    sys_prepare_send_message ($self, 'message', 'endcall', undef, undef, $operator, $message_ip, undef); 
		} else {
		    if(defined($operator) && $operator!=0 && $operator ne ''){
			sys_request('operator_events', $operator, 53, $caller_id, join("`",($answeredtime, $acdgroup, $extension, time()-$self->agi->get_variable('OperatorBeginTime')-$answeredtime, $operator_hangup, $time_begin)));
			my $is_free = sys_request('operator_status', $operator, 1);
			sys_request('operator_status', $operator, 3) if ($is_free==0);
		    } else {
			sys_request('operator_events', 0, 53, $caller_id, join("`",($answeredtime, $acdgroup, $extension, time()-$time_begin, $operator_hangup, $time_begin)));
		    }
		}

		$operator_password = sys_request('operator_password_by_id', $operator) if ($operator ne '');
		$operator_password = 0 if($operator_password=='');
	}

#Префикс звонившего отвечает за поле operator в calls (сейчас идет проверка на начальные символы KMBL)
	my $caller_prefix = '';
	$caller_prefix = $1 if( $self->agi->get_variable('CallerIdName') =~ /^([KMBL])/ );

#Если трансферный звонок - засекаем время начала разговора второго абонента
	if($self->agi->database_get('transfer', $caller_id.'.'.$operator_password)==1){
	    $self->agi->database_put('transfer', $caller_id.'.'.$operator_password, 2);
	    $self->agi->database_put('transfer_begin_time', $caller_id.'.'.$operator_password, time());
	    $self->agi->database_put('acdgroup', $caller_id.'.'.$operator_password, $acdgroup);
	    $self->agi->database_put('extension', $caller_id.'.'.$operator_password, $extension);
	    $self->agi->database_put('prefix', $caller_id.'.'.$operator_password, $caller_prefix);
	}

	$answeredtime = $time_total-$time_total_queue if ($sound_before_dial eq 'yes');

	sys_request('calls_log', join("`",($caller_id, $operator_password, $time_begin, $status, $time_total, $answeredtime, $time_total_queue, $queue_maximum, $acdgroup, $extension, 0, 0, $caller_prefix)));
	sys_addlog('Incoming call. Caller '.$caller_id.' calls to '.$operator_password.'. Answered time: '.$answeredtime.'. Total time: '.$time_total.' (Queue: '.$time_total_queue.')');
#	sys_callers_dump("1.txt",($time_begin+$time_total_queue).", ".($time_begin+$time_total).", ".$time_begin.", ".($time_begin+$time_total_queue).",");
	sys_callers_dump($caller_id, "конец вызова. время ответа $answeredtime. общее время: $time_total (очередь: $time_total_queue)");	

	if($CallIsRemote!=1) {
	    my @list_channels = sys_request('client_queue_down_check');
	    foreach $b (@list_channels)
	    {
    		my $channel_status = $self->agi->channel_status($b->[1]);
    		sys_addlog("WARNING: Проверка залипшего оператора ".$b->[0]." : $channel_status");
		sys_request('operator_status', $b->[0], 1) if($channel_status==-1);
	    }
	}
    sys_db_disconnect();
}

sub incoming_after_hangover {
    sys_db_connect();
    my $self = shift;
    my $service_id = $self->agi->get_variable('ClientSrvID');
    my $operator = $self->agi->get_variable('Operator');
    my $calleridname = $self->agi->get_variable('varcalleridname');
    my $callerid = $self->agi->get_variable('varcallerid');
    my $callfilename = $self->agi->get_variable('CALLFILENAME');
    my $callExtension = $self->agi->get_variable('varExtension');
    my $calluniqueid = $self->agi->get_variable('varuniqueid');
    my $callisremoteserver = $self->agi->get_variable('CallIsRemoteServer');
    sys_callers_dump($callerid, "оператор поднял трубку");
    if($callisremoteserver eq ''){
	my $channel = sys_request('channel_by_operator_id', $operator);
	my $message_ip = sys_request('ip_by_sip', $channel);
	sys_prepare_send_message ($self, 'message', 'after', $calleridname, $service_id, $operator, $message_ip, $callerid, 1, $callfilename, $callExtension, $calluniqueid );
    } else {
	my $service_name = sys_request('service_by_service_id', $service_id);
	sys_send_command("op send message after $operator $calleridname $service_name $operator $callerid $callfilename $callExtension $calluniqueid", $config->{"servers.$callisremoteserver.ip"}, $config->{"servers.$callisremoteserver.port"});
    }
    sys_db_disconnect();
}

1;
