=head1 NAME

 Software::Packager::Tar

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('tar');

=head1 DESCRIPTION

 This module is used to create tar files with the required structure 
 as specified by the list of object added to the packager.

=head1 FUNCTIONS

=cut

package		Software::Packager::Tar;

####################
# Standard Modules
use strict;
use Archive::Tar;
use File::Path;
use File::Copy;
use File::Find;
use File::Basename;
use Cwd;
use Data::Dumper;
# Custom modules
use Software::Packager;

####################
# Variables
our @ISA = qw( Software::Packager );
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.01;

my $m_tar;
my $m_tmp_dir;
my $m_package_build_dir;

####################
# Functions

################################################################################
# Function:	new()

=head2 B<new()>

 This method creates and returns a new class object.

=cut
sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	package()

=head2 B<package()>

 This method overrides the base API and implements the required functionality 
 to create Tar software packages.
 It calls teh following method in order setup, create_package and cleanup.

=cut
sub package
{
	my $self = shift;
	$m_tmp_dir = $self->tmp_dir();
	$m_package_build_dir .= "$m_tmp_dir/" . $self->package_name();

	return undef unless $self->setup();
	return undef unless $self->create_package();
	return undef unless $self->cleanup();

	return 1;
}

################################################################################
# Function:	setup()

=head2 B<setup()>

 This function sets up the temporary structure for the package.

=cut
sub setup
{
	my $self = shift;
	my $cwd = getcwd();

	# process directories
	unless (-d $m_package_build_dir)
	{
		mkpath($m_package_build_dir, 1, 0755) or
			warn "Error: Problems were encountered creating directory \"$m_package_build_dir\": $!\n";
	}
	chdir $m_package_build_dir;

	# process directories
	my @directories = $self->get_directory_objects();
	foreach my $object (@directories)
	{
		my $destination = $object->destination();
		my $user = $object->user();
		my $group = $object->group();
		my $mode = $object->mode();
		unless (-d $destination)
		{
			mkpath($destination, 1, $mode) or
				warn "Error: Problems were encountered creating directory \"$destination\": $!\n";
		}
	}

	# process files
	my @files = $self->get_file_objects();
	foreach my $object (@files)
	{
		my $source = $object->source();
		my $destination = $object->destination();
		my $dir = dirname($destination);
		unless (-d $dir)
		{
			mkpath($dir, 1, 0755) or
				warn "Error: Problems were encountered creating directory \"$dir\": $!\n";
		}
		copy($source, $destination) or
			warn "Error: Problems were encountered coping \"$source\" to \"$destination\": $!\n";

		my $user_id = $object->user();
		my $group_id = $object->group();
		$user_id = getpwnam($object->user()) unless $user_id =~ /\d/;
		$group_id = getgrnam($object->group()) unless $group_id =~ /\d/;
		chown($user_id, $group_id, $destination) or 
			warn "Error: Problems were encountered changing ownership: $!\n";

		my $mode = oct($object->mode());
		chmod($mode, $destination) or
			warn "Error: Problems were encountered changing permissions: $!\n";
	}

	# process links
	my @links = $self->get_link_objects();
	foreach my $object (@links)
	{
		my $source = $object->source();
		my $destination = $object->destination();
		my $type = $object->type();

		if ($type =~ /hard/i)
		{
			eval link "$source", "$destination";
			warn "Warning: Hard links not supported on this operatiing system: $@\n" if $@;
		}
		elsif ($type =~ /soft/i)
		{
			eval symlink "$source", "$destination";
			warn "Warning: Soft links not supported on this operatiing system: $@\n" if $@;
		}
		else
		{
			warn "Error: Not sure what type of link to create soft or hard.";
		}
	}

	chdir $cwd;
	return 1;
}

################################################################################
# Function:	create_package()
# Description:	This function creates the package
# Arguments:	none.
# Return:	true if ok else undef.
#
sub create_package
{
	my $self = shift;
	my $tar_file = $self->output_dir();
	$tar_file .= "/" . $self->package_name();
	$tar_file .= ".tar";

	# create the object
	my $cwd = getcwd();
	chdir $m_tmp_dir;
	$m_tar = new Archive::Tar();

	# Add everything to the archive.
	my @files;
	find  sub {push @files, $File::Find::name;}, $self->package_name();
	$m_tar->add_files(@files) or 
		warn "Error: Problems were encountered creating the archive: $!\n", $m_tar->error(), "\n";

	# write the sucker.
	$m_tar->write($tar_file);
	chdir $cwd;

	return 1;
}

################################################################################
# Function:	cleanup()
# Description:	This function removes the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub cleanup
{
	my $self = shift;

	# there has to be a better way to to this!
	return undef unless system("chmod -R 0777 $m_tmp_dir") eq 0;
	rmtree($m_tmp_dir, 1, 1);
	return 1;
}

################################################################################
# Function:	_package_name()

=head2 B<_package_name()>

 This method is used to format the package name and return it in the format
 required for tar packages.
 This method overrides the _package_name method of Software::Packager.

=cut
sub _package_name
{
	my $self = shift;
	my $package_name = $self->{'PACKAGE_NAME'};
	$package_name .= "-" . $self->version();

	return $package_name;
}

1;
__END__
