use Module::Build;

my $build = Module::Build->new(
	module_name => 'Mail::TempAddress',
	license     => 'perl',
	requires    => {
		Class::Roles     => '0.30',
		Mail::Action     => '0.30',
		Mail::Address    => '1.53',
		Mail::Internet   => '1.53',
		Test::Exception  => '',
		Test::MockObject => '0.11',
		Test::Simple     => '0.47',
		YAML             => '0.35',
	},
	dist_version_from => 'lib/Mail/TempAddress.pm',
);

$build->create_build_script;
