################################################################################
# Name:		Software::Packager::Darwin.pm
# Description:	This module is used to package software into MacOSX bundles
# Author:	Bernard Davison
# Contact:	bernard@gondwana.com.au
#

package		Software::Packager::Darwin;

####################
# Standard Modules
use strict;
use File::Copy;
use File::Path;
use File::Basename;
use FileHandle 2.0;
use Data::Dumper;
# Custom modules
use Software::Packager;

####################
# Variables
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
@ISA = qw( Software::Packager );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.01;

####################
# Functions

################################################################################
# Function:	new()
# Description:	This function creates and returns a new Packager object.
# Arguments:	none.
# Return:	new Packager object.
#
sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	package()
# Description:	This function finalises the creation of the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub package
{
	my $self = shift;

	# setup the tmp structure
	return undef unless $self->setup_in_tmp();

	# create the pax file
	return undef unless $self->create_package();

	# remove tmp structure
	return undef unless $self->remove_tmp();

	return 1;
}

################################################################################
# Function:	setup_in_tmp()
# Description:	This function sets up the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub setup_in_tmp
{
	my $self = shift;
	my $verbose = $self->verbose();

	print "Creating temporary package structure\n" if $verbose;

	# process directories
	return undef unless $self->process_directories();

	# process files
	return undef unless $self->process_files();

	# process links
	return undef unless $self->process_links();

	# set permissions
	return undef unless $self->set_permissions();

	return 1;
}

################################################################################
# Function:	remove_tmp()
# Description:	This function removes the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub remove_tmp
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Removing temporary package structure\n" if $verbose;
	return undef unless system("chmod -R 0700 $tmp_dir") eq 0;
	rmtree($tmp_dir, $verbose, 1);
	return 1;
}

################################################################################
# Function:	create_package()
# Description:	This function creates the pax file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub create_package
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();
	my $icon = $self->icon();
	my $verbose = $self->verbose();

	print "Creating package.\n" if $verbose;

	# Create the package.info file
	return undef unless $self->create_package_info();

	# Create the package
	return undef unless system("package $tmp_dir $output_dir/$name.info $icon -d $output_dir") eq 0;

	# copy the pre and post scripts into the package
	copy($self->pre_install_script(), "$output_dir/$name.pkg/$name.pre_install") if $self->pre_install_script();
	copy($self->post_install_script(), "$output_dir/$name.pkg/$name.post_install") if $self->post_install_script();
	copy($self->pre_uninstall_script(), "$output_dir/$name.pkg/$name.pre_uninstall") if $self->pre_uninstall_script();
	copy($self->post_uninstall_script(), "$output_dir/$name.pkg/$name.post_uninstall") if $self->post_uninstall_script();
	copy($self->pre_upgrade_script(), "$output_dir/$name.pkg/$name.pre_upgrade") if $self->pre_upgrade_script();
	copy($self->post_upgrade_script(), "$output_dir/$name.pkg/$name.post_upgrade") if $self->post_upgrade_script();

	# fix the permissions on the scripts
	chmod 0544, "$output_dir/$name.pkg/$name.pre_install";
	chmod 0544, "$output_dir/$name.pkg/$name.post_install";
	chmod 0544, "$output_dir/$name.pkg/$name.pre_uninstall";
	chmod 0544, "$output_dir/$name.pkg/$name.post_uninstall";
	chmod 0544, "$output_dir/$name.pkg/$name.pre_upgrade";
	chmod 0544, "$output_dir/$name.pkg/$name.post_upgrade";

	# Copy the license file into the package.
	copy($self->license_file(), "$output_dir/$name.pkg/License.rtf") if $self->license_file();
	chmod 0444, "$output_dir/$name.pkg/License.rtf";
		
	print "Package creation complete.\n" if $verbose;
	return 1;
}

################################################################################
# Function:	create_package_info()
# Description:	This function creates the package.info file for the package.
# Arguments:	none.
# Return:	true if ok else undef.
# TODO:		This function needs to be finished. (more functions need to be 
#		added to Packager.pm
#
sub create_package_info
{
	my $self = shift;
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();
	my $verbose = $self->verbose();

	# open a file handle on the file
	my $fh = new FileHandle();
	$fh->open(">$output_dir/$name.info");
	$fh->autoflush();

	$fh->print("#\n#These fields are displayed in the Info View\n#\n");
	$fh->print("Title ".$self->program_name()."\n");
	$fh->print("Version ".$self->version()."\n");
	$fh->print("Description ".$self->description()."\n");

	$fh->print("#\n#These fields are used for the installer media locations\n#\n");
	$fh->print("DefaultLocation ".$self->install_dir()."\n");
	$fh->print("Relocatable YES\n");
	$fh->print("Diskname $name\n");

	$fh->print("#\n#Other files that have varing importance\n#\n");
	$fh->print("NeedsAuthorization YES\n");
	$fh->print("DeleteWarning NO\n");
	$fh->print("DisableStop NO\n");
	$fh->print("UseUserMask NO\n");
	$fh->print("Application NO\n");
	$fh->print("Required NO\n");
	$fh->print("InstallOnly NO\n");
	$fh->print("RequiresReboot NO\n");
	$fh->print("InstallFat NO\n");

	$fh->close();
}

################################################################################
# Function:	process_directories()
# Description:	This function processes all of the directories.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub process_directories
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();

	print "Processing Directories\n" if $verbose;

	# create the tmp processing directory
	return undef unless mkpath($tmp_dir, $verbose, 0777);

	foreach my $object ($self->get_directory_objects())
	{
	    my $destination = $object->destination();
	    return undef unless mkpath("$tmp_dir/$destination", $verbose, 0777);
	}

	# Create the output directory for the package
	return undef unless mkpath("$output_dir/$name.pkg", $verbose, 0777);

	print "Finished Processing Directories\n\n" if $verbose;

	return 1;
}

################################################################################
# Function:	process_files()
# Description:	This function processes all of the files.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub process_files
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Processing Files\n" if $verbose;

	foreach my $object ($self->get_file_objects())
	{
	    my $destination = $object->destination();
	    my $source = $object->source();

	    # check that the directory for this file exists if not create it
	    my $directory = dirname("$tmp_dir/$destination");
	    unless (-d $directory)
	    {
		return undef unless mkpath($directory, $verbose, 0777);
	    }

	    print "Coping $source to $tmp_dir/$destination\n" if $verbose;
	    return undef unless copy($source, "$tmp_dir/$destination");
	}

	print "Finished Processing Files\n\n" if $verbose;

	return 1;
}

################################################################################
# Function:	process_links()
# Description:	This function process all of the links.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub process_links
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Processing Links\n" if $verbose;

	foreach my $object ($self->get_link_objects())
	{
	    my $source = $object->source();
	    my $destination = $object->destination();
	    my $type = $object->type();

	    if ($type eq 'softlink')
	    {
		print "Creating soft link from $source to $tmp_dir/$destination\n" if $verbose;
		unless (symlink $source, "$tmp_dir/$destination")
		{
		    print "Error: Could not create soft link from $source to $tmp_dir/$destination:\n$!\n" if $verbose;
		    return undef;
		}
	    }
	    elsif ($type eq 'hardlink')
	    {
		print "Creating hard link from $source to $tmp_dir/$destination\n" if $verbose;
		unless (link $source, "$tmp_dir/$destination")
		{
		    print "Error: Could not create hard link from $source to $tmp_dir/$destination:\n$!\n" if $verbose;
		    return undef;
		}
	    }
	    else
	    {
	    }
	}

	print "Finished Processing Links\n\n" if $verbose;

	return 1;
}

################################################################################
# Function:	set_permissions()
# Description:	This function sets the permissions for all objects.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub set_permissions
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Setting Permissions\n" if $verbose;

	foreach my $object ($self->get_directory_objects(), $self->get_file_objects())
	{
	    my $destination = $object->destination();
	    my $mode = $object->mode();
	    my $user = $object->user();
	    my $group = $object->group();
	    my $user_num = $user =~ /\d+/ ? $user : getpwnam($user);
	    my $group_num = $group =~ /\d+/ ? $group : getgrnam($group);

	    print "Changing user and group to $user_num:$group_num on $tmp_dir/$destination\n" if $verbose;
	    unless (chown($user_num, $group_num, "$tmp_dir/$destination"))
	    {
		print "Error: Could not change owner or group:\n$!\n" if $verbose;
		return undef;
	    }

	    print "Changing mode to $mode on $tmp_dir/$destination\n" if $verbose;
	    unless (chmod $object->mode(), "$tmp_dir/$destination")
	    {
		print "Error: Could not change owner or group:\n$!\n" if $verbose;
		return undef;
	    }
	}

	print "Finished setting Permissions\n\n" if $verbose;

	return 1;
}

1;
__END__