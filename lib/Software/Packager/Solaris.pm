################################################################################
# Name:		Software::Packager::Solaris.pm
# Description:	This module is used to package software into SUN software
#		packages
# Author:	Bernard Davison
# Contact:	bernard@gondwana.com.au
#

package		Software::Packager::Solaris;

####################
# Standard Modules
use strict;
use File::Copy;
use File::Path;
use File::Basename;
use FileHandle 2.0;
#use Cwd;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Solaris;

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
# Function:	add_item()
# Description:	This function over rides the add_item function in the
#		Software::Packager module. this function adds a new object the
#		package
# Arguments:	hash of object data.
# Return:	true if okay else undef
#
sub add_item
{
	my $self = shift;
	my %data = @_;
	my $object = new Software::Packager::Object::Solaris(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	return 1 if $self->{'OBJECTS'}->{$object->destination()} = $object;
	return undef;
}

################################################################################
# Function:	package_name()
# Description:	This function sets the package name and overrides the
#		package_name function in Software::Packager.pm
# Arguments:	name.
# Return:	package name if nothing passed.
#
sub package_name
{
	my $self = shift;
	my $value = shift;

	return $self->{'PACKAGE_NAME'} unless $value;
	if (length $value gt 9)
	{
		print "Error: Package name is to long.\n";
	}
	$self->{'PACKAGE_NAME'} = $value;
	return 1;
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

	# Create the package
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
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Creating temporary package structure\n" if $verbose;

	# process directories
	return undef unless mkpath($tmp_dir, $verbose, 0777);

	# process files
	if ($self->license_file())
	{
		return undef unless copy($self->license_file(), "$tmp_dir/copyright");
	}

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
	my $verbose = $self->verbose();

	print "Starting Package creation\n" if $verbose;

	# create the prototype file
	return undef unless $self->create_prototype();

	# create the pkginfo file
	return undef unless $self->create_pkginfo();

	# make the package
	return undef unless $self->create_pkgmk();

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
	return undef unless system("chmod -R 0777 $tmp_dir") eq 0;
	rmtree($tmp_dir, $verbose, 1);
	return 1;
}

################################################################################
# Function:	create_prototype()
# Description:	This function create the prototype file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub create_prototype
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Creating prototype file\n" if $verbose;
	my $protofile = new FileHandle() or return undef;
	return undef unless $protofile->open(">$tmp_dir/prototype");

	$protofile->print("i pkginfo\n");
	$protofile->print("i copyright\n") if $self->license_file();

	# add the directories then files then links
	foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
	{
		$protofile->print($object->part(), " ");
		$protofile->print($object->prototype(), " ");
		$protofile->print($object->class(), " ");
		if ($object->prototype() =~ /[dx]/)
		{
			$protofile->print($object->destination(), " ");
		}
		else
		{
			$protofile->print($object->destination(), "=");
			$protofile->print($object->source(), " ");
		}
		$protofile->print($object->mode(), " ");
		$protofile->print($object->user(), " ");
		$protofile->print($object->group(), "\n");
	}

	return undef unless $protofile->close();
	print "Finished creating prototype file\n" if $verbose;

	return 1;
}

################################################################################
# Function:	create_pkginfo()
# Description:	This function creates the pkginfo file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub create_pkginfo
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $verbose = $self->verbose();

	print "Creating pkginfo file\n" if $verbose;
	my $protofile = new FileHandle() or return undef;
	return undef unless $protofile->open(">$tmp_dir/pkginfo");
	return undef unless $protofile->print("PKG=\"", $self->package_name(), "\"\n");
	return undef unless $protofile->print("NAME=\"", $self->program_name(), "\"\n");
	return undef unless $protofile->print("ARCH=\"", $self->architecture(), "\"\n");
	return undef unless $protofile->print("VERSION=\"", $self->version(), "\"\n");
	return undef unless $protofile->print("CATEGORY=\"", $self->category(), "\"\n");
	return undef unless $protofile->print("VENDOR=\"", $self->vendor(), "\"\n");
	return undef unless $protofile->print("EMAIL=\"", $self->email_contact(), "\"\n");
	return undef unless $protofile->print("PSTAMP=\"", $self->creator(), "\"\n");
	return undef unless $protofile->print("BASEDIR=\"", $self->install_dir(), "\"\n");
	return undef unless $protofile->print("CLASSES=\"none\"\n");
	return undef unless $protofile->close();
	print "Finished creating pkginfo file\n" if $verbose;

	return 1;
}

################################################################################
# Function:	create_package()
# Description:	This function creates the package and puts it in the output
#		directory
# Arguments:	none.
# Return:	true if ok else undef.
#
sub create_pkgmk
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $verbose = $self->verbose();
	my $name = $self->package_name();

	print "Creating package\n" if $verbose;
	mkpath($output_dir, $verbose, 0777);

	return undef unless system("pkgmk -r / -f $tmp_dir/prototype ") eq 0;
	return undef unless system("pkgtrans -s /var/spool/pkg $output_dir/$name $name") eq 0;

	# clean up our neat mess.
	return undef unless system("chmod -R 0700 /var/spool/pkg/$name") eq 0;
	rmtree("/var/spool/pkg/$name", $verbose, 1);

	print "Finished creating package\n" if $verbose;

	return 1;
}

1;
__END__
