=head1 NAME

 Software::Packager::Object

=head1 SYNOPSIS

 use Software::Packager::Object;

=head1 DESCRIPTION

 This module is used by Software::Packager for holding data for a each item
 added to the a software package. It provides an easy way of accessing the data
 for each object to be installed.
 This module is designed to be easly sub classed and / or extended.

=head1 SUB-CLASSING

 To extend or sub-class this module create a new module along the lines of
 ===========================================================================
 package Foo;

 use Software::Packager::Object;
 our @ISA = qw( Software::Packager::Object );

 ########################
 # _check_data we don't care about anything other that DESTINATION and FOO_DATA;
 sub _check_data
 {
 	my $self = shift;
	return undef unless $self->{'DESTINATION'};
	return undef unless $self->{'FOO_DATA'};
 }

 ########################
 # foo_data returns the foo value fo this object.
 sub foo_data
 {
 	my $self = shift;
	return $self->get_value('FOO_DATA');
 }
 1;
 __END__
 ===========================================================================

 of course I would have created the module under Software::Packager::Object::Foo
 but that's you choice.

=head1 FUNCTIONS

=cut

package		Software::Packager::Object;

####################
# Standard Modules
use strict;
# Custom modules

####################
# Variables
our @ISA = qw();
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.01;

####################
# Functions

################################################################################
# Function:	new()

=head2 B<new()>

 my $object = new Software::Packager::Object(%object_data);

 This function creates and returns a new Software::Packager::Object object which
 is used to access the data in the passed hash. This passed data is checked for
 problems by the _check_data() method.

 The hash of data passed should contain at least the following
 %hash = (
	'TYPE' => 'file type',
	'SOURCE' => 'source file location',
	'DESTINATION' => 'destination location',
	'USER' => 'user to install as',
	'GROUP' => 'group to install as',
	'MODE' => 'permissions to install the file with',
 	);

=cut
sub new
{
	my $class = shift;
	my %data = @_;

	my $self = bless \%data, $class;
	return undef unless $self->_check_data();

	return $self;
}

################################################################################
# Function:	_check_data()

=head2 B<_check_data()>

 $self->_check_data();

 This function checks that the data for this object is okay and returns true if
 there are problems with the data then undef is returned.

 TYPE		If the type is a file then the value of SOURCE must be a real
 		file. If the type is a soft/hard link then the source and
		destination must both be present.
 SOURCE		nothing special to check, see TYPE
 DESTINATION	nothing special to check, see TYPE
 MODE		Defaults to 0755 for directories and 0644 for files.
 USER		Defaults to the current user
 GROUP		Defaults to the current users primary group

=cut
sub _check_data
{
	my $self = shift;

	$self->{'TYPE'} = lc $self->{'TYPE'};
	if ($self->{'TYPE'} eq 'file')
	{
	    return undef unless -f $self->{'SOURCE'};
	}
	elsif ($self->{'TYPE'} =~ /link/)
	{
	    return undef unless $self->{'SOURCE'} and $self->{'DESTINATION'};
	}

	unless ($self->{'MODE'})
	{
	    if ($self->{'TYPE'} eq 'directory')
	    {
		$self->{'MODE'} = 0755;
	    }
	    else
	    {
		$self->{'MODE'} = 0644;
	    }
	}

	unless ($self->{'USER'})
	{
	    $self->{'USER'} = $<;
	}

	unless ($self->{'GROUP'})
	{
	    my $groups = $(;
	    my ($group, @rest) = split / /, $groups;
	    $self->{'GROUP'} = $group;
	}

	return 1;
}

################################################################################
# Function:	get_value()

=head2 B<get_value()>

 This method returns the value for the passed argument.

=cut
sub get_value
{
	my $self = shift;
	my $query = shift;
	return $self->{$query};
}

################################################################################
# Function:	type()

=head2 B<type()>

 This method returns the type of this object.

=cut 
sub type
{
	my $self = shift;
	return $self->get_value('TYPE');
}

################################################################################
# Function:	source()

=head2 B<source()>

 This method returns the source location for this object.

=cut 
sub source
{
	my $self = shift;
	return $self->get_value('SOURCE');
}

################################################################################
# Function:	destination()

=head2 B<destination()>

 This method returns the destination location for this object.

=cut 
sub destination
{
	my $self = shift;
	return $self->get_value('DESTINATION');
}

################################################################################
# Function:	mode()

=head2 B<mode()>

 This method returns the installation mode for this object.

 NOTE: The mode is stored in octal but that doesn't mean that you are using it
 in octal if you are trying to use the return value in a chmod command then do
 something like.

 $mode = oct($object->mode());
 chmod($mode, $object->destination());

 Do lots of tests!

=cut 
sub mode
{
	my $self = shift;
	return $self->get_value('MODE');
}

################################################################################
# Function:	user()

=head2 B<user()>

 This method returns the user name that this object should be installed as.

=cut 
sub user
{
	my $self = shift;
	return $self->get_value('USER');
}

################################################################################
# Function:	group()

=head2 B<group()>

 This method returns the installation group that this object should be installed
 as.

=cut 
sub group
{
	my $self = shift;
	return $self->get_value('GROUP');
}

1;
__END__

=head1 SEE ALSO

 Software::Packager

=head1 AUTHOR

 R Bernard Davison <bernard@gondwana.com.au>
 If you extend this module I'd really like to see what you do with it. 

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut
