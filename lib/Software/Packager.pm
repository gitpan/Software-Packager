=head1 NAME

 Software::Packager

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager();

=head1 DESCRIPTION

 The Software Packager module is designed to provide a common interface for
 packaging software on any platform. This module does not do the packaging of 
 the software but is merely a wraper around the various software packaging tools
 already provided with various operating systems.

 This module provides the base API and sets default values common to the various
 software packaging methods.

=cut

package		Software::Packager;

####################
# Standard Modules
use strict;
use Config;
use Data::Dumper;
# Custom modules
use Software::Packager::Object;

####################
# Variables
our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.05;

####################
# Functions

=head1 FUNCTIONS

=cut
################################################################################
# Function:	new()

=head2 B<new()>

 my $packager = new Software::Packager();
 or
 my $packager = new Software::Packager(tar);

 This function creates and returns a new Packager object appropriate for the 
 current platform. Optionally the packager type can be passed and the
 appropriate software packager will be returned.

=cut
sub new
{
	my $class = shift;
	my $type = shift;

	# find which platform we are on and return the correct packager.
	# there has to be a better way to do this.
	my $packager = undef;
	if (scalar $type)
	{
            $type = ucfirst lc $type;
	}
        else
        {
		if ($Config{'osname'} eq 'linux')
		{
			# need to find distrubution for linux
			if ($Config{'myuname'} =~ /redhat|caldera/i)
			{
                                $type = ucfirst lc 'rpm';
			}
                        elsif ($Config{'something'} =~ /debian/)
                        {
                                $type = ucfirst lc 'dpkg';
                        }
		}
                else
                {
                        $type = ucfirst lc $Config{'osname'};
                }
        }
        
        my $load_module = "require Software::Packager::$type;\n";
        $load_module .= '$packager' . " = new Software::Packager::$type();\n";
        eval $load_module;
        die $@ if $@;

	# do some initalisation
	$packager->{'PACKAGE_VERSION'} = 0.0.0.0.0.0;
	$packager->{'DESCRIPTION'} = "This software installation package has been created with Software::Packager version $VERSION\n";
	$packager->{'OUTPUT_DIR'} = ".";

	return $packager;
}

################################################################################
# Function:	version()

=head2 B<version()>

 $packager->version(1.2.3.4.5.6);
 my $version = $packager->version();

 This function sets the version for the package to the passed value. If no value
 is passed then the packager version is returned.
 The version passed must be a number seperated by periods "." and contain at
 least three parts "1.2.3". since some software packaging products require or
 can handle longer version numbers the default is for a six part version number
 "1.2.3.4.5.6".
 The version will be set to the value you pass, however not all software 
 packaging products need this many fields or can handle them, so the version 
 applied to the actual software package will be set to the appropriate lengthed
 value.
 Having said this, as a software package creator, you need to know what version
 is being applied to the package you are creating, right... so after you set the
 version check what the version will be set to by calling the version method
 without any arguments to see what is returned.

 Example: If we are on AIX, which has a four part version we would get...

 $packager->version(10.2.1);
 my $version = $packager->version();
 print "VERSION: $version\n";
 ...
 VERSION: 10.2.1.0

 or

 $packager->version(1);
 my $version = $packager->version();
 print "VERSION: $version\n";
 ...
 VERSION: 1.1.0.0

 Since AIX requires the first two values to be set the second is set to be 1.

 For full details on version string requirements refer to the operating system
 documentation or the documentation for the desired packaging system.

=cut
sub version
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'PACKAGE_VERSION'} = $value if $self->_check_version($value);
	}
	else
	{
		return $self->_version();
	}
}

################################################################################
# Function:	package_name()

=head2 B<package_name()>

 $packager->package_name("Somename");
 my $name = $packager->package_name();
 
 This method sets the package name to the passed value. If no arguments are
 passed the package name is returned.
 Note that some software packaging methods place various limitations on the
 package name. For example on Solaris the package name is limited to 9 Charaters
 while the RedHat Package Manager is very strict about the format of the names
 of the packages it creates.

=cut
sub package_name
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'PACKAGE_NAME'} = $value;
	}
	else
	{
		return $self->_package_name();
	}
}

################################################################################
# Function:	program_name()

=head2 B<program_name()>

 $packager->program_name('Software Packager');
 my $program_name = $packager->program_name();

 This method is used to set the name of the program that the package is
 installing. This may in some cases be the same as the package name but that is 
 not required.

=cut
sub program_name
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'PROGRAM_NAME'} = $value;
	}
	else
	{
		return $self->_program_name();
	}
}

################################################################################
# Function:	description()

=head2 B<description()>

 $packager->description("This is the description.");
 my $description = $packager->description();
 
 The description method sets the package description to the passed value. If no
 arguments are passed the package description is returned.
 It is important to note that some installation package methods limit the length
 of the description. Therefore it is advisable to check what the description
 will be set to by calling the method without any arguments.

 Example: 
 $packager->description("This is a short message.");
 my $description = $packager->descriotion();
 print "DESCRIPTION: $description\n";
 ...
 DESCRIPTION: This is a short message.

=cut
sub description
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'DESCRIPTION'} = $value;
	}
	else
	{
		return $self->_description();
	}
}

################################################################################
# Function:	output_dir()

=head2 B<output_dir()>

 $packager->output_dir("/home/software/packages");
 my $output_directory = $packager->output_dir();

 The output_dir method sets the directory where the final installation package
 will be placed.
 The output directory can be set by passing the desired directory to the method.
 the current outout directory can be checked by calling the method without any
 arguments.

=cut
sub output_dir
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'OUTPUT_DIR'} = $value;
	}
	else
	{
		return $self->{'OUTPUT_DIR'};
	}
}

################################################################################
# Function:	category()

=head2 B<category()>

 $packager->category("Applications");
 my $category = $packager->category();
 
 This method returns or sets the category for the package.
 Not all packaging systems support categories and so this will only be set where
 possible.
 This functionality is fairly common and is here to provide a standard API.

=cut
sub category
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'CATEGORY'} = $value;
	}
	else
	{
	return $self->_category();
	}
}

################################################################################
# Function:	architecture()

=head2 B<architecture()>

 $packager->architecture("sparc");
 my $arch = $packager->architecture();

 This method sets the architecture for the package to the passed value. If no
 argument is passed then the current architecture is returned.
 The default value is the name given the current architecture by the current
 packaging system.
 Not all packaging systems care about architectures and so this will only be
 used where it is required.
 This functionality is fairly common and is here to provide a standard API.

=cut
sub architecture
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
            $self->{'ARCHITECTURE'} = $value;
	}
	else
	{
            return $self->_architecture();
	}
}

################################################################################
# Function:	add_item()

=head2 B<add_item()>

 my %object_data = (
    'SOURCE' => '/source/file1',
    'TYPE' => 'file',
    'DESTINATION' => '/usr/local/file1',
    'USER' => 'joe',
    'GROUP' => 'staff',
    'mode' => '0750',
    );
 $packager->add_item(%object_data);

 The add_item method is used to add objects to the software package.  By default
 each object added to the software package must have a unique installation 
 destination, though some packaging systems allow many objects to have the same 
 installation location; with the decision of which object to install happening
 at install time. This ability is not common to all software packaging systems
 and thus is only available for systems that support this ability.

 The add_item method has some mandatory arguments which are described in the 
 module Software::Packager::Object. The documentation for this module should be
 consulted if a more detailed explanation of these arguments is required.
 
 Required arguments:
 TYPE		The type can be File, Softlink, Hardlink or Directory.
 		If the type is set to File then the SOURCE value must be a real
		file.
		If the type is a link then both the SOURCE and DESTINATION must
		be present.
 SOURCE		This is the source file to add to the package.
 DESTINATION	The installation destination. This must always be present.

 Optional arguments:
 MODE		The installation permissions. 
 USER		The installation user. Defaults to the current user.
 GROUP		The installation group. Default is the current users primary
		group.

=cut
sub add_item
{
	my $self = shift;
	my %data = @_;
	my $object = new Software::Packager::Object(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	$self->{'OBJECTS'}->{$object->destination()} = $object;
}

################################################################################
# Function:	prerequisites()

=head2 B<prerequisites()>

 $packager->prerequisites('/usr/bin/perl');
 $icon = $packager->prerequisites();
 
 This function returns or sets the prerequisites for this package. since 
 prerequisites can be handled in so many ways  it is best to see the 
 documentation in the various packaging system modules.
 Not all packaging systems can or do use prerequisites and so they will only
 be used where they are supported.
 This functionality is fairly common and is here to provide a standard API.

=cut
sub prerequisites
{
	my $self = shift;
	my $value = shift;

        if ($value)
        {
            $self->{'PREREQUISITES'} = $value;
        }
        else
        {
	    return $self->_prerequisites();
        }
}

################################################################################
# Function:	icon()

=head2 B<icon()>

 $packager->icon('/source/icon.png');
 $icon = $packager->icon();
 
 This function returns or sets the icon file name for the package.
 Not all packaging systems use icons and so this will only be used where the use 
 of icons are supported.
 This functionality is fairly common and is here to provide a standard API.

=cut
sub icon
{
	my $self = shift;
	my $value = shift;

        if ($value)
        {
            $self->{'ICON'} = $value;
        }
        else
        {
	    return $self->{'ICON'};
        }
}

################################################################################
# Function:	verdor()

=head2 B<vendor()>

 $packager->vendor('Gondwanatech');
 my $vendor = $packager->vendor();

 This method is used to specify the vendor of the software package.
 This is the name of the company or organisation that is creating the software
 package.

=cut
sub vendor
{
	my $self = shift;
	my $value = shift;

        if ($value)
        {
            $self->{'VENDOR'} = $value;
        }
        else
        {
            return $self->{'VENDOR'};
        }
}

################################################################################
# Function:	email_contact()

=head2 B<email_contact()>

 $packager->email_contact('rbdavison@cpan.org');
 my $email = $packager->email_contact();
 
 This function sets or returns the email address for the package contact.
 Typicaly this will be the person / mail list where help with the software can 
 be sort.
 If you want to grab some glory this is where you can do it!

=cut
sub email_contact
{
	my $self = shift;
	my $value = shift;

        if ($value)
        {
            $self->{'EMAIL_CONTACT'} = $value;
        }
        else
        {
            return $self->{'EMAIL_CONTACT'};
        }
}

################################################################################
# Function:	creator()

=head2 B<creator()>

 $packager->creator('R Bernard Davison');
 my $creator = $packager->creator();
 
 This set the name of the person who created the software package.

=cut
sub creator
{
	my $self = shift;
	my $value = shift;

        if ($value)
        {
            $self->{'PACKAGE_CREATOR'} = $value;
        }
        else
        {
            return $self->{'PACKAGE_CREATOR'};
        }
}

################################################################################
# Function:	install_dir()

=head2 B<install_dir()>

 $packager->install_dir('/usr/local');
 my $base_dir = $packager->install_dir();
 
 This method sets the base directory for the software to be installed.
 
=cut
sub install_dir
{
	my $self = shift;
	my $value = shift;

	return $self->{'BASEDIR'} unless $value;
	$self->{'BASEDIR'} = $value;
	return 1;
}

################################################################################
# Function:	tmp_dir()

=head2 B<tmp_dir()>

 $packager->tmp_dir('/tmp');
 my $tmp_dir = $packager->tmp_dir();

 This method returns or sets the temporary build directory to be used for
 package creation. This directory is used for any preparation that is needed to 
 make the package. This directory should be on a partition with sufficient disk
 space to hold all temporary objects for the package creation process.

=cut
sub tmp_dir
{
	my $self = shift;
	my $value = shift;

        if ($value)
        {
            $self->{'TMP_BUILD_DIR'} = $value if $self->_check_tmp_dir($value);
        }
        else
        {
            return $self->_tmp_dir();
        }
}

################################################################################
# Function:	pre_install_script()
# Description:	This function returns or sets the pre install script for the 
#		package.
# Arguments:	file name
# Return:	file name if nothing passed
#
sub pre_install_script
{
	my $self = shift;
	my $value = shift;

	return $self->{'PRE_INSTALL_SCRIPT'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'PRE_INSTALL_SCRIPT'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	post_install_script()
# Description:	This function returns or sets the post install script for the 
#		package.
# Arguments:	file name
# Return:	file name if nothing passed
#
sub post_install_script
{
	my $self = shift;
	my $value = shift;

	return $self->{'POST_INSTALL_SCRIPT'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'POST_INSTALL_SCRIPT'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	pre_uninstall_script()
# Description:	This function returns or sets the pre uninstall script for the 
#		package.
# Arguments:	file name
# Return:	file name if nothing passed
#
sub pre_uninstall_script
{
	my $self = shift;
	my $value = shift;

	return $self->{'PRE_UNINSTALL_SCRIPT'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'PRE_UNINSTALL_SCRIPT'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	post_uninstall_script()
# Description:	This function returns or sets the post uninstall script for the 
#		package.
# Arguments:	file name
# Return:	file name if nothing passed
#
sub post_uninstall_script
{
	my $self = shift;
	my $value = shift;

	return $self->{'POST_UNINSTALL_SCRIPT'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'POST_UNINSTALL_SCRIPT'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	pre_upgrade_script()
# Description:	This function returns or sets the pre upgrade script for the 
#		package.
# Arguments:	file name
# Return:	file name if nothing passed
#
sub pre_upgrade_script
{
	my $self = shift;
	my $value = shift;

	return $self->{'PRE_UPGRADE_SCRIPT'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'PRE_UPGRADE_SCRIPT'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	post_upgrade_script()
# Description:	This function returns or sets the post upgrade script for the 
#		package.
# Arguments:	file name
# Return:	file name if nothing passed
#
sub post_upgrade_script
{
	my $self = shift;
	my $value = shift;

	return $self->{'POST_UPGRADE_SCRIPT'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'POST_UPGRADE_SCRIPT'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	license_file()
# Description:	This function returns or sets the license file for the package
# Arguments:	file name
# Return:	file name if nothing passed
#
sub license_file
{
	my $self = shift;
	my $value = shift;

	return $self->{'LICENSE_FILE'} unless $value;
	if ($self->_test_file($value))
	{
	    $self->{'LICENSE_FILE'} = $value;
	    return 1;
	}
	else
	{
	    return undef;
	}
}

################################################################################
# Function:	get_object_list()
# Description:	This function returns the list of objects to be packaged.
# Arguments:	none.
# Return:	an array of objects.
#
sub get_object_list
{
	my $self = shift;

	my @destinations = keys %{$self->{'OBJECTS'}};
	@destinations = sort @destinations;

	my @sorted_objects;
	foreach my $destination (@destinations)
	{
	    foreach my $key (keys %{$self->{'OBJECTS'}})
	    {
		my $object = $self->{'OBJECTS'}->{$key};
		push @sorted_objects, $object if $object->destination() eq $destination;
		last if $object->destination() eq $destination;
	    }
	}

	return @sorted_objects;
}

################################################################################
# Function:	get_objects_matching()
# Description:	This function returns a list of objects that matched the query.
# Arguments:	$query_field, $query_value
# Return:	an array of objects.
#
sub get_objects_matching
{
	my $self = shift;
	my $query = shift;
	my $value = shift;

	my @objects;
	foreach my $object ($self->get_object_list())
	{
	    push @objects, $object if $object->get_value($query) eq $value;
	}

	return @objects;
}

################################################################################
# Function:	get_directory_objects()
# Description:	This function returns the list of objects that are directories.
# Arguments:	none.
# Return:	an array of objects.
#
sub get_directory_objects
{
	my $self = shift;

	my @objects;
	foreach my $object ($self->get_object_list())
	{
		push @objects, $object if $object->type() eq 'directory';
	}

	return @objects;
}

################################################################################
# Function:	get_file_objects()
# Description:	This function returns the list of objects that are files.
# Arguments:	none.
# Return:	an array of objects.
#
sub get_file_objects
{
	my $self = shift;

	my @objects;
	foreach my $object ($self->get_object_list())
	{
		push @objects, $object if $object->type() eq 'file';
	}

	return @objects;
}

################################################################################
# Function:	get_link_objects()
# Description:	This function returns the list of objects that are links.
# Arguments:	none.
# Return:	an array of objects.
#
sub get_link_objects
{
	my $self = shift;

	my @objects;
	foreach my $object ($self->get_object_list())
	{
		push @objects, $object if $object->type() =~ /link/;
	}

	return @objects;
}

################################################################################
# Function:	_test_file()
# Description:	This function returns true if the passed file exists, if it 
#		doesn't then it prints an error message and returns undef.
# Arguments:	$file.
# Return:	true or undef.
#
sub _test_file
{
	my $self = shift;
	my $file = shift;

	return 1 if -f $file;
	print "Error: File \"$file\" does not exist\n";
	return undef;
}

=head1 EXTENDING Software::Packager

 To extend the Software::Packager suite all that is required is to create a
 module that the wraps the desired software packaging system.
 
 It may be necessary to override the following methods.

=cut

################################################################################
# Function:     package()
 
=head2 B<package()>

 This method forms part of the base API it should be overriden by sub classes
 of Software::Packager

=cut
sub package    
{       
        my $self = shift;
	print "The base API for this module has not been implemented.\n";
}       

################################################################################
# Function:	_version()

=head2 B<_version()>

 This method is used to format the version and return it in the desired format 
 for the current packaging system.

=cut
sub _version
{
	my $self = shift;
	return $self->{'PACKAGE_VERSION'};
}

################################################################################
# Function:	_check_version()

=head2 B<_check_version()>

 This method is used to check the format of the version and returns true, if
 there are any problems then it returns undef;
 Test that the format is digits and periods anything else is a no good.

=cut
sub _check_version
{
	my $self = shift;
	my $value = shift;
	return undef if $value =~ /\D!\./;
	return 1;
}

################################################################################
# Function:	_category()

=head2 B<_category()>

 This method returns the package category in the format required by the current
 packaging system.

=cut
sub _category
{
	my $self = shift;
	return $self->{'CATEGORY'};
}

################################################################################
# Function:	_architecture()

=head2 B<_architecture()>

 This method returns the architecture in the format required for the current
 packaging system.

=cut
sub _architecture
{
	my $self = shift;
	return $self->{'ARCHITECTURE'};
}

################################################################################
# Function:	_package_name()

=head2 B<_package_name()>

 This method is used to format the package name and return it in the format for 
 the current packaging system.

=cut
sub _package_name
{
	my $self = shift;
	return $self->{'PACKAGE_NAME'};
}

################################################################################
# Function:	_description()

=head2 B<_description()>

 This method is used to format the description and return it in the required
 format for the current packaging system.
 i.e. The description may need to be truncated or prefixed.

=cut
sub _description
{
	my $self = shift;
	return $self->{'DESCRIPTION'};
}

################################################################################
# Function:	_prerequisites()

=head2 B<_prerequisites()>

 This method is used to format the prerequisites and return it in the required
 format for the current packaging system.
 i.e. The prerequisites may need to be returned as a comma seperated list or as a
 perl hash or some unknown number or other formats.

=cut
sub _prerequisites
{
	my $self = shift;
	return $self->{'PREREQUISITES'};
}

################################################################################
# Function:	_tmp_dir()

=head2 B<_tmp_dir()>

 This method is used to format the temporary build directory and return it.

=cut
sub _tmp_dir
{
	my $self = shift;
	return $self->{'TMP_BUILD_DIR'};
}

################################################################################
# Function:	_program_name()

=head2 B<_program_name()>

 This method is used to format the program name and return it.

=cut
sub _program_name
{
	my $self = shift;
	return $self->{'PROGRAM_NAME'};
}

################################################################################
# Function:	_check_tmp_dir()

=head2 B<_check_tmp_dir()>

 This method is used to check the temporary build directory. 
 there are any problems then it returns undef;
 Test if the temporary build directory exist's if so return undef;

=cut
sub _check_tmp_dir
{
	my $self = shift;
	my $value = shift;
	if (-e $value)
	{
		warn "Error: The temporary build directory \"$value\" exists. It is not possible to continue. Please remove this directory and try again.\n";
		return undef;
	}
	return 1;
}

1;
__END__

=head1 SEE ALSO

 Software::Packager::Object

=head1 AUTHOR

 Bernard Davison <rbdavison@cpan.org>

=head1 HOMEPAGE

 http://bernard.gondwana.com.au

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut
