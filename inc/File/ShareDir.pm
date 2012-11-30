#line 1
package File::ShareDir;

#line 106

use 5.005;
use strict;
use Carp             ();
use Config           ();
use Exporter         ();
use File::Spec       ();
use Class::Inspector ();

use vars qw{ $VERSION @ISA @EXPORT_OK %EXPORT_TAGS };
BEGIN {
	$VERSION     = '1.03';
	@ISA         = qw{ Exporter };
	@EXPORT_OK   = qw{
		dist_dir
		dist_file
		module_dir
		module_file
		class_dir
		class_file
	};
	%EXPORT_TAGS = (
		ALL => [ @EXPORT_OK ],
	);
}

use constant IS_MACOS => !! ($^O eq 'MacOS');





#####################################################################
# Interface Functions

#line 156

sub dist_dir {
	my $dist = _DIST(shift);
	my $dir;

	# Try the new version
	$dir = _dist_dir_new( $dist );
	return $dir if defined $dir;

	# Fall back to the legacy version
	$dir = _dist_dir_old( $dist );
	return $dir if defined $dir;

	# Ran out of options
	Carp::croak("Failed to find share dir for dist '$dist'");
}

sub _dist_dir_new {
	my $dist = shift;

	# Create the subpath
	my $path = File::Spec->catdir(
		'auto', 'share', 'dist', $dist,
	);

	# Find the full dir withing @INC
	foreach my $inc ( @INC ) {
		next unless defined $inc and ! ref $inc;
		my $dir = File::Spec->catdir( $inc, $path );
		next unless -d $dir;
		unless ( -r $dir ) {
			Carp::croak("Found directory '$dir', but no read permissions");
		}
		return $dir;
	}

	return undef;
}

sub _dist_dir_old {
	my $dist = shift;

	# Create the subpath
	my $path = File::Spec->catdir(
		'auto', split( /-/, $dist ),
	);

	# Find the full dir within @INC
	foreach my $inc ( @INC ) {
		next unless defined $inc and ! ref $inc;
		my $dir = File::Spec->catdir( $inc, $path );
		next unless -d $dir;
		unless ( -r $dir ) {
			Carp::croak("Found directory '$dir', but no read permissions");
		}
		return $dir;
	}

	return undef;
}

#line 235

sub module_dir {
	my $module = _MODULE(shift);
	my $dir;

	# Try the new version
	$dir = _module_dir_new( $module );
	return $dir if defined $dir;

	# Fall back to the legacy version
	return _module_dir_old( $module );
}

sub _module_dir_new {
	my $module = shift;

	# Create the subpath
	my $path = File::Spec->catdir(
		'auto', 'share', 'module',
		_module_subdir( $module ),
	);

	# Find the full dir withing @INC
	foreach my $inc ( @INC ) {
		next unless defined $inc and ! ref $inc;
		my $dir = File::Spec->catdir( $inc, $path );
		next unless -d $dir;
		unless ( -r $dir ) {
			Carp::croak("Found directory '$dir', but no read permissions");
		}
		return $dir;
	}

	return undef;
}
	
sub _module_dir_old {
	my $module = shift;
	my $short  = Class::Inspector->filename($module);
	my $long   = Class::Inspector->loaded_filename($module);
	$short =~ tr{/}{:} if IS_MACOS;
	substr( $short, -3, 3, '' );
	$long  =~ m/^(.*)\Q$short\E\.pm\z/s or die("Failed to find base dir");
	my $dir = File::Spec->catdir( "$1", 'auto', $short );
	unless ( -d $dir ) {
		Carp::croak("Directory '$dir', does not exist");
	}
	unless ( -r $dir ) {
		Carp::croak("Directory '$dir', no read permissions");
	}
	return $dir;
}

#line 307

sub dist_file {
	my $dist = _DIST(shift);
	my $file = _FILE(shift);

	# Try the new version first
	my $path = _dist_file_new( $dist, $file );
	return $path if defined $path;

	# Hand off to the legacy version
	return _dist_file_old( $dist, $file );;
}

sub _dist_file_new {
	my $dist = shift;
	my $file = shift;

	# If it exists, what should the path be
	my $dir  = _dist_dir_new( $dist );
	my $path = File::Spec->catfile( $dir, $file );

	# Does the file exist
	return undef unless -e $path;
	unless ( -f $path ) {
		Carp::croak("Found dist_file '$path', but not a file");
	}
	unless ( -r $path ) {
		Carp::croak("File '$path', no read permissions");
	}

	return $path;
}

sub _dist_file_old {
	my $dist = shift;
	my $file = shift;

	# Create the subpath
	my $path = File::Spec->catfile(
		'auto', split( /-/, $dist ), $file,
	);

	# Find the full dir withing @INC
	foreach my $inc ( @INC ) {
		next unless defined $inc and ! ref $inc;
		my $full = File::Spec->catdir( $inc, $path );
		next unless -e $full;
		unless ( -r $full ) {
			Carp::croak("Directory '$full', no read permissions");
		}
		return $full;
	}

	# Couldn't find it
	Carp::croak("Failed to find shared file '$file' for dist '$dist'");
}

#line 386

sub module_file {
	my $module = _MODULE(shift);
	my $file   = _FILE(shift);
	my $dir    = module_dir($module);
	my $path   = File::Spec->catfile($dir, $file);
	unless ( -e $path ) {
		Carp::croak("File '$file' does not exist in module dir");
	}
	unless ( -r $path ) {
		Carp::croak("File '$file' cannot be read, no read permissions");
	}
	$path;
}

#line 429

sub class_file {
	my $module = _MODULE(shift);
	my $file   = _FILE(shift);

	# Get the super path ( not including UNIVERSAL )
	# Rather than using Class::ISA, we'll use an inlined version
	# that implements the same basic algorithm.
	my @path  = ();
	my @queue = ( $module );
	my %seen  = ( $module => 1 );
	while ( my $cl = shift @queue ) {
		push @path, $cl;
		no strict 'refs';
		unshift @queue, grep { ! $seen{$_}++ }
			map { s/^::/main::/; s/\'/::/g; $_ }
			( @{"${cl}::ISA"} );
	}

	# Search up the path
	foreach my $class ( @path ) {
		local $@;
		my $dir = eval {
		 	module_dir($class);
		};
		next if $@;
		my $path = File::Spec->catfile($dir, $file);
		unless ( -e $path ) {
			next;
		}
		unless ( -r $path ) {
			Carp::croak("File '$file' cannot be read, no read permissions");
		}
		return $path;
	}
	Carp::croak("File '$file' does not exist in class or parent shared files");
}




#####################################################################
# Support Functions

sub _module_subdir {
	my $module = shift;
	$module =~ s/::/-/g;
	return $module;
}

sub _dist_packfile {
	my $module = shift;
	my @dirs   = grep { -e } ( $Config::Config{archlibexp}, $Config::Config{sitearchexp} );
	my $file   = File::Spec->catfile(
		'auto', split( /::/, $module), '.packlist',
	);

	foreach my $dir ( @dirs ) {
		my $path = File::Spec->catfile( $dir, $file );
		next unless -f $path;

		# Load the file
		my $packlist = ExtUtils::Packlist->new($path);
		unless ( $packlist ) {
			die "Failed to load .packlist file for $module";
		}

		die "CODE INCOMPLETE";
	}

	die "CODE INCOMPLETE";
}

# Inlined from Params::Util pure perl version
sub _CLASS {
    (defined $_[0] and ! ref $_[0] and $_[0] =~ m/^[^\W\d]\w*(?:::\w+)*\z/s) ? $_[0] : undef;
}


# Maintainer note: The following private functions are used by
#                  File::ShareDir::PAR. (It has to or else it would have to copy&fork)
#                  So if you significantly change or even remove them, please
#                  notify the File::ShareDir::PAR maintainer(s). Thank you!    

# Matches a valid distribution name
### This is a total guess at this point
sub _DIST {
	if ( defined $_[0] and ! ref $_[0] and $_[0] =~ /^[a-z0-9+_-]+$/is ) {
		return shift;
	}
	Carp::croak("Not a valid distribution name");
}

# A valid and loaded module name
sub _MODULE {
	my $module = _CLASS(shift) or Carp::croak("Not a valid module name");
	if ( Class::Inspector->loaded($module) ) {
		return $module;
	}
	Carp::croak("Module '$module' is not loaded");
}

# A valid file name
sub _FILE {
	my $file = shift;
	unless ( defined $file and ! ref $file and length $file ) {
		Carp::croak("Did not pass a file name");
	}
	if ( File::Spec->file_name_is_absolute($file) ) {
		Carp::croak("Cannot use absolute file name '$file'");
	}
	$file;
}

1;

#line 575
