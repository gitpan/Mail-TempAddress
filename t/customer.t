#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib', 'lib';
}

use strict;

use FakeIn;
use FakeMail;
use File::Path 'rmtree';

use Test::More tests => 20;

use Test::MockObject;
use Test::Exception;

use Mail::TempAddress::Addresses;

mkdir 'addresses';

END
{
	rmtree 'addresses' unless @ARGV;
}

my @mails;
Test::MockObject->fake_module( 'Mail::Mailer', new => sub {
	push @mails, FakeMail->new();
	$mails[-1];
});

diag( 'Create a new alias and subscribe another user' );

my $fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home
To: alias@there
Subject: *new*

END_HERE

use_ok( 'Mail::TempAddress' ) or exit;

my $ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

my $count = @mails;
my $mail  = shift @mails;
is( $mail->To(),   'me@home',       '*new* list should reply to sender' );
is( $mail->From(), 'alias@there',   '... from the alias' );
like( $mail->Subject(),
	qr/Temporary address created/,  '... with a good subject' );

like( $mail->body(),
	qr/A new temporary address has been created for me\@home/,
	                                '... and a creation message' );

my $find_address = qr/([a-f0-9]+)\@there/;
my ($address) = $mail->body() =~ $find_address;
isnt( $address, undef,              '... providing the temporary address' );

diag( 'Sending a message to a temp address' );
$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: someone\@somewhere
To: $address\@there
Some-Header: foo
Subject: Hi there

Here is
my message!!

END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail = shift @mails;
is( $mail->To(), 'me@home',
	'message sent to temp addy should be resent to creator' );
is( $mail->Subject(), 'Hi there', '... with subject preserved' );
my $replyto = 'Reply-To';
my $alias   = $mail->$replyto();
like( $alias, qr/$address\+(\w+)\@there/,
	'... setting reply-to to keyed alias' );
like( $mail->body(), qr/Here is.+my message!!/s,
	'... preserving message body' );

my $sh = 'Some-Header';
is( $mail->$sh(), 'foo', '... preserving other headers' );

diag( 'Replying to a keyed alias' );

$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: me\@home
To: $alias
Another-Header: bar
Subject: Well hello!

I am responding
to
you
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail = shift @mails;
is( $mail->To(), 'someone@somewhere',
	'replying to resent message should respond to its sender' );
is( $mail->From(), "$address\@there", '... from temporary address' );
like( $mail->body(), qr/I am responding.+to.+you/s,
	'... with body' );
my $ah = 'Another-Header';
is( $mail->$ah(), 'bar', '... preserving other headers' );

diag( 'Expiration dates should work' );
$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home
To: alias@there
Subject: *new*

Expires: 7d
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail         = shift @mails;
($address)    = $mail->body() =~ $find_address;
my $addresses = Mail::TempAddress::Addresses->new( 'addresses' );
$alias        = $addresses->fetch( $address );
ok( $alias->expires(),
	'sending expiration directive should set expires flag to true' );

$alias->{expires} = time() - 100;
$addresses->save( $alias, $address );

@mails = ();

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home
To: $address\@there
Subject:  probably too late

this message will not reach you in time
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
throws_ok { $ml->process() } qr/Invalid address/,
	             'mta should throw exception on expired address';
is( $! + 0, 100, '... setting $! to 100' ) or diag( "$address" );
is( @mails, 0,   '... sending no messages' );

diag( 'Descriptions should work' );
$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home
To: alias@there
Subject: *new*

Description: my temporary address
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail         = shift @mails;
($address)    = $mail->body() =~ $find_address;

$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: you\@elsewhere
To: $address\@there
Subject: hello

Description: my temporary address
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail         = shift @mails;
my $desc_head = 'X-MTA-Description';
my $desc      = $mail->$desc_head();

is( $desc, 'my temporary address',
	'description header should be present in responses' );
