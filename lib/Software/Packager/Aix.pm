=head1 NAME

 Software::Packager::Aix

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('aix');

=head1 DESCRIPTION

 This module is used to create software packages in a format suitable for
 installation with installp.
 The procedure is baised heaverly on the lppbuild version 2.1 scripts.
 It creates AIX 4.1 and higher packages only.

=head1 FUNCTIONS

=cut

package		Software::Packager::Aix;

####################
# Standard Modules
use strict;
use File::Path;
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

	return undef unless $self->setup();
	return undef unless $self->cleanup();
	return 1;
}

################################################################################
# Function:	setup()

=head2 B<setup()>

 This method sets up the temporary build structure.

=cut
sub setup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	mkpath($tmp_dir, 1, 0750) or
		warn "Error: problems were encountered creating directory \"$tmp_dir\": $!\n";

	return 1;
}

################################################################################
# Function:	cleanup()

=head2 B<cleanup()>

 This method cleans up after us.

=cut
sub cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# there has to be a better way to to this!
	return undef unless system("chmod -R 0777 $tmp_dir") eq 0;

	rmtree($tmp_dir, 1, 1);

	return 1;
}

################################################################################
# Function:	_check_version()

=head2 B<_check_version()>

 This method is used to check the format of the version and returns true, if
 there are any problems then it returns undef;
 This method overrides Software::Packager::_check_version
 Test that the format is digits and periods anything else is a no good.
 The first and second numbers must have 1 or 2 digits
 The rest can have 1 to 4 digits.

=cut
sub _check_version
{
	my $self = shift;
	my $value = shift;
	return undef if $value =~ /\D!\./;
	return $self->{'PACKAGE_VERSION'};
}

1;
__END__

=head1 SEE ALSO

 Software::Packager

=head1 AUTHOR

 Bernard Davison <bernard@gondwana.com.au>

=head1 HOMEPAGE

 http://bernard.gondwana.com.au

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut
