package SFC::Room::Data;

use 5.006;
use strict;
use warnings FATAL => 'all';

# make accessor
use base qw{Class::Accessor::Fast};

my @accessors= qw{
	name
	japanese
	roman
	greek
	room
	SFSNumber
    };

__PACKAGE__->mk_accessors(@accessors);

sub new {
    my ($class, $params)= @_;
    return bless {%{$params}}, $class;
}

sub floor {
    my $self= shift;

    if (!$self->{floor} || ref $self->{floor} eq 'HASH') {
	return '';
    } else {
	return $self->{floor};
    }
}

sub room {
    my $self= shift;

    if (!$self->{room}) {
	return '';
    } else {
	return $self->{room};
    }
}

sub string {
    my $self= shift;

    my $japanese= $self->japanese;
    my $room=     $self->room;

    return $japanese.$room;
}

sub _get_accessor {
    return (@accessors, 'Aliases');
}

sub _add_floor_and_room {
    my $self= shift;
    my $word= shift;

    if ($word =~ /iij|不純/i) {
	$self->{floor}= $self->{floor}->{IIJHouse};
    } elsif ($word =~ /docomo|ドコモ/i) {
	$self->{floor}= $self->{floor}->{DocomoHouse};
    } elsif ($word =~ /dnp/i) {
	$self->{floor}= $self->{floor}->{DNAHouse};
    } elsif ($word =~ /館内/) {
	$self->{floor}= $self->{floor}->{TateuchiHouse};
    } elsif ($word =~ /森/) {
	$self->{floor}= $self->{floor}->{MoriAtelier};
    } elsif ($self->name eq 'Delta') {
	if ($word =~ /([ns])(\d+)/i) {
	    $self->{room}=  uc($1).$2;
	    $self->{floor}= lc($1).substr($2, 0, 1);
	}
    } elsif ($self->name eq 'Tau' && $word =~ /([23][f階])?(ロフト|loft)/) {
	if ($1) {
	    my $r= substr($1, 0, 1);
	    $self->{room}=  $r.'0';
	    $self->{floor}= $r;
	} else {
	    $self->{room}=  20;
	    $self->{floor}= 2;
	}
    } elsif ($word =~ /(\d+)/) {
	my $room=  $1;
	my $floor= substr $room, 0, 1;

	$self->{room}= $room;
	$self->{floor}= $floor;
    }

    return $self;
}

1;

__END__

=head1 NAME

SFC::Room::Data -


=head1 SYNOPSIS

use SFC::Room::Data;


=head1 DESCRIPTION


=head1 AUTHOR

cory, C<< <cory at sfc.keio.ac.jp> >>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# End of SFC::Room::Data
