#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('SFC::Room') }

my $r= SFC::Room->new('./share/sfc-rooms.json');

{
    my $room= $r->parse('i11');
    is($room->name,  'Iota', 'parser can parse all roman classroom');
    is($room->room,  '11',   'parser can parse all roman classroom');
    is($room->floor, '1',    'parser can parse all roman classroom');
}

{
    my $room= $r->parse('ι411');
    is($room->name,   'Iota',      'can parse greek classroom');
    is($room->room,   '411',       'can parse greek classroom');
    is($room->floor,  '4',         'can parse greek classroom');
    is($room->string, 'イオタ411', 'can parse greek classroom');
}

{
    my $room= $r->parse('ラムダ19');
    is($room->name,   'Lambda',   'can parse japanese classroom');
    is($room->room,   '19',       'can parse japanese classroom');
    is($room->floor,  '1',        'can parse japanese classroom');
    is($room->string, 'ラムダ19', 'can parse japanese classroom');
}

{
    my $room= $r->parse('ΔS113');
    is($room->name,   'Delta',      'can parse delta classroom');
    is($room->room,   'S113',       'can parse delta classroom');
    is($room->floor,  's1',         'can parse delta classroom');
    is($room->string, 'デルタS113', 'can parse delta classroom');
}

{
    my $room= $r->parse('タウ館2階ロフト');
    is($room->name,   'Tau',    'can parse tau classroom');
    is($room->room,   '20',     'can parse tau classroom');
    is($room->floor,  '2',      'can parse tau classroom');
    is($room->string, 'タウ20', 'can parse tau classroom');
}

{
    my $room= $r->parse('IIJハウス');
    is($room->name,   'Nu',        'can parse nu classroom');
    is($room->floor,  '1',         'can parse nu classroom');
    is($room->string, 'IIJハウス', 'can parse nu classroom');
}

done_testing();
