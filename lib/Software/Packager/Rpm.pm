################################################################################
# Name:		Software::Packager::RPM.pm
# Description:	This module is used to package software into Redhat's RPM
#		Package Format.
# Author:	Bernard Davison
# Contact:	bernard@gondwana.com.au
#

package		Software::Packager::RPM;

####################
# Standard Modules
use strict;
# Custom modules
use Software::Packager;

####################
# Variables
our @ISA = qw( Software::Packager );
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.01;

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
	return 1;
}

1;
__END__