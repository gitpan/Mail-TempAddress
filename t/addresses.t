#!/usr/bin/perl -w

BEGIN
{
    chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;

use File::Spec;
use File::Path;

use Test::More tests => 24;
use Test::MockObject;

mkdir 'addresses' unless -d 'addresses';

END
{
	rmtree 'addresses' unless @ARGV;
}

my $mock_addy = Test::MockObject->new();
$mock_addy->fake_module( 'Mail::TempAddress::Address',
	new => sub { shift; $mock_addy->my_new( @_ ) } );

my $module = 'Mail::TempAddress::Addresses';
use_ok( $module ) or exit;

can_ok( $module, 'new' );
my $addys = $module->new( 'addresses' );
isa_ok( $addys, $module );

can_ok( $module, 'address_dir' );
is( $addys->address_dir(), 'addresses',
	'address_dir() should return value set in constructor' );

can_ok( $module, 'address_file' );
my $exists = File::Spec->catfile( 'addresses', 'exists.mta' );
my $result = $addys->address_file( 'exists' );
is( $result, $exists,
	'address_file() should add path and extension to filename' );

can_ok( $module, 'exists' );
{
	local *OUT;
	open( OUT, '>' . $exists )
		or diag "exists() tests will fail; cannot create file: $!"; 
	print OUT "file";
	close OUT;
}
$result = $addys->exists( 'exists' );
ok( $result,   'exists() should return true if file exists' );

$result = $addys->exists( 'doesnotexist' );
ok( ! $result, '... and false if it does not' );

can_ok( $module, 'generate_address' );
$result = $addys->generate_address();
ok( $result, 'generate_address() should return a new address given no arg' );
is( $result =~ tr/a-f0-9//c, 0, '... with only alphanumerics' );

$result = $addys->generate_address( 'a new id' );
is( $result, 'a new id', '... using given address' );

$result = $addys->generate_address( 'exists' );
isnt( $result, 'exists', '... unless it already exists' );

can_ok( $module, 'create' );
$mock_addy->set_always( my_new => $mock_addy );
$result = $addys->create( 'me@home' );
my ($method, $args) = $mock_addy->next_call();
is( $method,      'my_new',   'create() should create new Address object' );

shift @$args;
my %args = @$args;

is( $args{owner}, 'me@home',  '... passing from address' );
is( $result,      $mock_addy, '... returning result' );

can_ok( $module, 'save' );

$addys->save( { Foo => 'bar', name => 'foo' }, 'foo' );
ok( $addys->exists( 'foo' ), 'save() should save file given name' );

can_ok( $module, 'fetch' );

$mock_addy->mock( my_new => sub
{
	my ($class, %args) = @_;
	bless \%args, 'Mail::TempAddress::Addresses';
});
	
$result = $addys->fetch( 'foo' );
ok( $result,                 'fetch() should fetch file, given name' );
is_deeply( $result, { name => 'foo', Foo => 'bar', },
                             '... restoring all keys plus name' );
