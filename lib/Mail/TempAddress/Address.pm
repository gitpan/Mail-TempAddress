package Mail::TempAddress::Address;

use strict;

sub new
{
	my $class = shift;
	bless { 
		expires     => 0,
		@_,
	}, $class;
}

sub name
{
	my $self      = shift;
	$self->{name} = shift if @_;
	$self->{name};
}

sub owner
{
	my $self = shift;
	return $self->{owner};
}

sub expires
{
	my $self         = shift;
	$self->{expires} = $self->process_time( shift ) + time() if @_;
	$self->{expires};
}

sub description
{
	my $self             = shift;
	$self->{description} = shift if @_;
	return '' unless exists $self->{description};
	$self->{description};
}

sub attributes
{
	{ expires => 1, description => 1 }
}

sub process_time
{
	my ($self, $time) = @_;
	return $time unless $time =~ tr/0-9//c;

	my %times = (
		m =>                60,
		h =>           60 * 60,
		d =>      24 * 60 * 60,
		w =>  7 * 24 * 60 * 60,
		M => 30 * 24 * 60 * 60,
	);

	my $units    = join('', keys %times);
	my $seconds; 

	while ( $time =~ s/(\d+)([$units])// )
	{
		$seconds += $1 * $times{ $2 };
	}

	return $seconds;
}

sub add_sender
{
	my ($self, $sender) = @_;

	my $key                  = $self->get_key( $sender ); 
	$self->{senders}{ $key } = $sender;

	return $key;
}

sub get_key
{
	my ($self, $sender) = @_;
	return $self->{keys}{ $sender } if exists $self->{keys}{ $sender };

	my $key  = sprintf '%x', reverse scalar time();

	do
	{
		$key = sprintf '%x', reverse( time() + rand( $$ ) );
	} while ( exists $self->{keys}{ $key } );

	return $self->{keys}{ $sender } = $key;
}

sub get_sender
{
	my ($self, $key) = @_;

	return unless exists $self->{senders}{ $key };
	return $self->{senders}{ $key };
}

1;

__END__

=head1 NAME

Mail::TempAddress::Address - object representing a temporary mailing address

=head1 SYNOPSIS

	use Mail::TempAddress::Address;
	my $address     =  Mail::TempAddress::Address->new(
		description => 'not my real address',
	);

=head1 DESCRIPTION

A Mail::TempAddress::Address object represents a temporary mailing address
within Mail::TempAddress.  It contains all of the attributes of the address and
provides methods to query and to set them.  The current attributes are
C<expires> and C<description>.

=head1 METHODS

=over 4

=item * new( %options )

C<new()> creates a new Mail::TempAddress::Address object.  Pass in a hash of
attribute options to set them.  By default, C<expires> is false and
C<description> is empty.

=item * attributes()

Returns a reference to a hash of valid attributes for Address objects.  This
allows you to see which attributes you should actually care about.

=item * owner()

Returns the e-mail address of the owner of this Address.

=item * add_sender( $sender )

Given C<$sender>, the e-mail address of someone who sent a message to this
Address, generates and returns a key for that sender.  The key can be used to
retrieve the sender's address later.

=item * get_sender( $key )

Given C<$key>, returns an e-mail address which has previously sent e-mail to
this Address.  This method will return a false value if there is no sender
associated with the key.

=item * name( [ $new_name   ] )

Given C<$new_name>, updates the associated name of the Address and returns the
new value.  If the argument is not provided, returns the current value.  You
probably don't want to change an existing Address' name.

=item * expires( [ $new_expires   ] )

Given C<$new_expires>, updates the C<expires> attribute of the Address and
returns the new value.  If the argument is not provided, returns the current
value.

=item * description( [ $new_description ] )

Given C<$new_description>, updates the C<description> attribute of the Address
and returns the new value.  If the argument is not provided, returns the
current value.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself.  How nice.
