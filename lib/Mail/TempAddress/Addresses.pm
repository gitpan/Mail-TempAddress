package Mail::TempAddress::Addresses;

use strict;

use YAML;

use Carp 'croak';
use Fcntl ':flock';

use File::Spec;
use Mail::TempAddress::Address;

sub new
{
	my ($class, $directory) = @_;
	bless { address_dir => $directory }, $class;
}

sub address_dir
{
	my $self = shift;
	return $self->{address_dir};
}

sub address_file
{
	my ($self, $filename) = @_;
	return File::Spec->catfile( $self->address_dir(), $filename . '.mta' );
}

sub exists
{
	my ($self, $address) = @_;
	return -e $self->address_file( $address );
}

sub generate_address
{
	my ($self, $id) = @_;

	$id ||= sprintf '%x', reverse scalar time;

	while ($self->exists( $id ))
	{
		$id = sprintf '%x', ( reverse ( time() + rand($$) ));
	}

	return $id;
}

sub create
{
	my ($self, $from_address) = @_;
	Mail::TempAddress::Address->new( owner => $from_address );
}

sub save
{
    my ($self, $address, $address_name) = @_;
    my $file = $self->address_file( $address_name );
    delete $address->{name};

    local *OUT;

    if (-e $file)
    {
        open( OUT, '+< ' . $file ) or croak "Cannot save data for '$file': $!";
        flock    OUT, LOCK_EX;
        seek     OUT, 0, 0;
        truncate OUT, 0;
    }
    else
    {
        open( OUT, '> ' . $file ) or croak "Cannot save data for '$file': $!";
    }

    print OUT Dump { %$address };
}

sub fetch
{
    my ($self, $address) = @_;

    local *IN;
    open(  IN, $self->address_file( $address ) ) or return;
    flock( IN, LOCK_SH );
    my $data = do { local $/; <IN> };
    close IN;

    return Mail::TempAddress::Address->new(
		%{ Load( $data ) }, name => $address );
}

1;

__END__

=head1 NAME

Mail::TempAddress::Addresses - manages Mail::TempAddress::Address objects

=head1 SYNOPSIS

	use Mail::TempAddress::Addresses;
	my $addresses = Mail::TempAddress::Addresses->new( '.addresses' );

=head1 DESCRIPTION

Mail::TempAddress::Addresses manages the creation, loading, and saving of
Mail::TempAddress::Address objects.  If you'd like to change how these objects
are managed on your system, subclass or reimplement this module.

=head1 METHODS

=over 4

=item * new( [ $address_directory ] )

Creates a new Mail::TempAddress::Addresses object.  The single argument is
optional but highly recommended.  It should be the path to where Address data
files are stored.  Beware that in filter mode, relative paths can be terribly
ambiguous.

If no argument is provided, this will default to C<~/.addresses> for the
invoking user.

=item * address_dir()

Returns the directory where this object's Address data files are stored.

=item * exists( $address_id )

Returns true or false if an address with this id exists.

=item * generate_address([ $address_id ])

Generates and returns a new, unique address id.  If provided, C<$address_id>
will be used as a starting point for the id.  It may not be used, though, if an
address already exists with that id.

=item * create( $owner )

Creates and returns a new Mail::TempAddress::Address object, setting the owner.
Note that you will need to C<save()> the object yourself, if that's important
to you.

=item * save( $address, $address_name )

Saves a Mail::TempAddress::Address object provided as C<$address> with the
given name in C<$address_name>.

=item * fetch( $address_id )

Creates and returns a Mail::TempAddress::Address object representing this
address id.  This will return nothing if the address does not exist.

=back

=head1 AUTHOR

chromatic, C<chromatic@wgz.org>, with helpful suggestions from friends, family,
and peers.

=head1 BUGS

None known.

=head1 TODO

No plans.  It's pretty nice as it is.

=head1 COPYRIGHT

Copyright (c) 2003, chromatic.  All rights reserved.  This module is
distributed under the same terms as Perl itself.  Convenient for you!
