use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Software::Packager',
	'VERSION_FROM'	=> 'lib/Software/Packager.pm',
	'AUTHOR'	=> 'R Bernard Davison (rbdavison@cpan.org)',
	'ABSTRACT'	=> 'A generic interface for creating software installation packages in platform specific formats',
	'PREREQ_PM'	=> {
		'Archive::Tar'	=>	'0.22',
		},
);
