package SFC::Room;

use 5.006;
use strict;
use warnings FATAL => 'all';

use JSON;
use Encode;
use File::ShareDir qw/dist_file/;

use SFC::Room::Data;

=head1 NAME

SFC::Room - A converter for classrooms of Keio University Shonan Fujisawa Campus

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SFC::Room;

    my $rooms = SFC::Room->new();

    my $delta = $rooms->parse('ΔS113');
    print $delta->string; # デルタS113
    print $delta->floor;  # s1
    print $delta->room;   # S113

    my $e201 = $rooms->parse('イプシロン201');
    print $e201->roman; # e
    print $e201->greek; # ε

    my $i311 = $rooms->parse('i311');
    print $e201->japanese; # イオタ

    my $subway = $rooms->parse('サブウェイ');
    print $e201->name;  # Lounge

    my $iij = $rooms->parse('IIJハウス');
    print $iij->string;    # IIJハウス
    print $iij->SFSNumber; # 9

=head1 SUBROUTINES/METHODS

=head2 new

my $rooms = SFC::Room->new();

=cut

sub new {
    my ($class, $config)= @_;
    my $self= bless {config => $config}, $class;
    $self->_load();
    return $self;
}

sub _load {
    my ($self, $config)= @_;

    if (!$self->{config}) {
	$self->{config}= File::ShareDir::dist_file('SFC-Room', 'sfc-rooms.json');
    }

    open my $fh, '<', $self->{config} || die $!;
    my $json= do { local $/; <$fh>; };
    close $fh;

    my $obj= decode_json(encode('utf8', $json));
    for (@{$obj}) {
	my $room= SFC::Room::Data->new($_);
	$self->{rooms}->{$room->name}= $room;
    }
}


=head2 parse

my $room = $rooms->parse('YOUR FAVORITE ROOM NAME');
# such as i211, I211, ι211, 森アトリエ, iij, Alpha, etc...

# This object has below accessors (if available)

$room->string;    # pupular name
# ex; IIJハウス (IIJ)

$room->name;      # English name (building)
# ex; Iota (i301)

$room->japanese;  # Japanese name (building)
# ex; カッパ (K11)

$room->roman;     # roman character
# ex; o (オミクロン23)

$room->greek;     # greek character
# ex; λ(Lambda)

$room->room;      # room info
# ex; 411 (i411)

$room->floor;     # floor info
# ex; s1 (デルタS113)

$room->SFSNumber; # building number (for SFC-SFS)
# ex; 10 (Omega)

=cut

sub parse {
    my ($self, $word)= @_;

    my $all_rooms= $self->{rooms};
    my @all_names= keys(%{$all_rooms});

    # failed to get valid json data
    return '' if $#all_names == -1;

    my @accessors= $all_rooms->{$all_names[0]}->_get_accessor();

    my %name2room;
    for my $name (@all_names) {
	for my $accessor (@accessors) {
	    my $entry= $all_rooms->{$name}->{$accessor};
	    next unless $entry;

	    if (ref $entry eq 'ARRAY') {
		for (@{$entry}) {
		    $name2room{$_}= $name if $_;
		}
	    } else {
		if ($entry =~ /^\d+$/) {
		    # $name is number (=> $name is number for SFC-SFS)
		    next;
		} else {
		    $name2room{$entry}= $name;
		}
	    }
	}
    }

    # matching
    for my $dic (sort {length $name2room{$a} <=> length $name2room{$b}} keys %name2room) {
	if ($word =~ /$dic/i) {
	    my $room= SFC::Room::Data->new($all_rooms->{$name2room{$dic}});

	    if (my ($alias_name)= grep { $_ =~ /^$word$/i } @{$room->{Aliases}}) {
		$room->{japanese}= $alias_name;
	    }

	    return $room->_add_floor_and_room($word);
	}
    }

    return;
}


=head1 AUTHOR

cory, C<< <cory at sfc.keio.ac.jp> >>


=head1 BUGS

Please create new pull request if you find it.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SFC::Room


=head1 ACKNOWLEDGEMENTS

This module is inspired by Rubys sfc-room gem.

sfc-room : [ https://github.com/ymrl/sfc-room ]


=head1 LICENSE AND COPYRIGHT

Copyright 2012 cory.

=cut

1; # End of SFC::Room
