#!/usr/bin/env perl
#
# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
#


use Getopt::Long;
use strict;

my %Options = ();
my $num_options;
my $key = '';
my $cert = '';
my $passphrase = '';
my $pkgfile = '';
my $sisfile_ip = '';
my $sisfile_op = '';
my @languages = ();
my @package_components = ();
my @vendor = ();
my $commonName = '';
my $vendorName = '';
my $error_para;


# THE MAIN PROGRAM SECTION
##########################
{
  # process the command-line
  $num_options = @ARGV;

  unless (GetOptions(\%Options, 'key=s' => \$key, 'cert=s'=> \$cert, 
		     'pass=s' => \$passphrase, 'help|h|?')) {
    &Usage();
    exit 1;
  }
    
  if ($Options{help}) {
    &Usage();
  }
  
  $num_options = @ARGV;

  my $action=uc shift @ARGV;

  unless ($action=~/^(CREATE|SIGN|DUMP|STRIP)$/o) {
    print STDERR "Unknown createsis's action: $action\n\n";
    &Usage();
    exit 1;
  }
    
  if ($action eq 'CREATE') {
    &createFunc();
  }

  if ($action eq 'SIGN') {
    &signFunc();
  }

  if ($action eq 'DUMP') {
    &dumpFunc();
  }

  if ($action eq 'STRIP') {
    &stripFunc();
  }
    
  exit 0;
}


# The implemetation of 'createsis create ...'
sub createFunc() {
  #
  # Perform parameters check
  #
 my $has_key = ($key ne '');
 my $has_cert = ($cert ne '');

  if ($has_key && !$has_cert) {
    print STDERR "Missing \'-cert\' option.\n";
    exit 1;
  }

  if (!$has_key && $has_cert) {
    print STDERR "Missing \'-key\' option.\n";
    exit 1;
  }

  if (@ARGV == 0) {
    print STDERR "Package file not found.\n";
    exit 1;
  }

  $pkgfile = shift @ARGV;

  unless (@ARGV == 0) {
    $error_para = shift @ARGV;
    print STDERR "Unknown parameter \"$error_para\" in the command line\n";
    exit 1;
  }

  # subst .SIS for .pkg in the package file name
  $sisfile_ip = $pkgfile;
  $sisfile_ip =~ s/\.pkg$//i;
  
  (system "makesis \"$pkgfile\" \"$sisfile_ip-tmp.SIS\"") == 0 or
    die "ERROR! Failed at makesis \"$pkgfile\"\n";

  # if key/cert are not found in the command line, try to extract them from the pkgfile
  # else generate DN and makekeys.
  if (!$has_key && !$has_cert) {
	
    unless (&extractPackageInfo() == 0) {
      print STDERR "Failed on extracting info from package file\n";
      exit 1;
    }
	
    # Let's generate cert/key
    if (($key eq '') && ($cert eq '')) {

      my $key_index = 0;

      print "No key/cert found in $pkgfile.\n";

      unless (&generateDN() == 0) {
   	print STDERR "Failed to generate distinguished-name-string(DN)\n";
   	exit 1;
      }

      # Specified the generated key/cert filenames
      $key = "key-gen.key";
      $cert = "cert-gen.cer";

      # if $key file exist, we need to index the new files
      while (-e $key) {
	$key_index++;
	$key = "key-gen".$key_index.".key";
	$cert = "cert-gen".$key_index.".cer";
      }

      print "making $key, $cert ...\n";

      if ($passphrase eq '') {
	my $pwd_temp = '';
	
	print "\n Could not find passphrase in command-line or $pkgfile!\n";
	
	for (;;) {
	  print " Please enter ENTER passphrase (at least 4 letters): ";
	  
	  $pwd_temp = <STDIN>;
	  
	  if (length ($pwd_temp) > 4) {
	    last;
	  }
	}

	chomp $pwd_temp;

	$passphrase = $pwd_temp;
      }

      (system "makekeys \-cert \-password \"$passphrase\" \-dname \"CN=$commonName OR=$vendorName\" $key $cert") == 0 or
	die "ERROR! Failed at makekeys... \n";
    } else {
      print "Found $key $cert from $pkgfile.\n"
    }
  }

  # Construct the input sis filename and output sis filename
  $sisfile_op = "$sisfile_ip.SIS";
  $sisfile_ip = "$sisfile_ip-tmp.SIS";

  print "Signing $sisfile_ip with $cert and $key -> $sisfile_op\n";

  if (defined $passphrase) {
    system ("signsis \-s \"$sisfile_ip\" \"$sisfile_op\" \"$cert\" \"$key\" \"$passphrase\"") == 0 or
      die "ERROR! Failed at signsis \-s \"$sisfile_ip\" \"$sisfile_op\" \"$cert\" \"$key\" $passphrase\n";
  } else {
    system ("signsis \-s $sisfile_ip $sisfile_op \"$cert\" \"$key\"") == 0 or
      die "ERROR! Failed at signsis \-s \"$sisfile_ip\" \"$sisfile_op\" \"$cert\" \"$key\"\n";
  }
  
  # delete the temporary file
  unlink $sisfile_ip;
  
}


# The implemetation of 'createsis sign ...'
sub signFunc() {

  my $commandline;

  $sisfile_ip=shift @ARGV;

  unless (defined $sisfile_ip) {
    print STDERR "Input SIS file not found.\n";
    exit 1;
  }

  $sisfile_op=shift @ARGV;

  unless (defined $sisfile_op) {
    print STDERR "Output SIS file not found.\n";
    exit 1;
  }

  unless (@ARGV == 0) {
    $error_para = shift @ARGV;
    print STDERR "Unknown parameter \"$error_para\" in the command line\n";
    exit 1;
  }

  if ($cert eq '') {
    print STDERR "certificate not found.\n";
    exit 1;
  }

  if ($key eq '') {
    print STDERR "key not found.\n";
    exit 1;
  }

  $commandline = "signsis \-s \"$sisfile_ip\" \"$sisfile_op\" \"$cert\" \"$key\"";

  print "signing input file $sisfile_ip -> $sisfile_op ...\n";

  if ($passphrase ne '') {
    $commandline .= " \"$passphrase\"";
  }

  (system $commandline) == 0 or
    die "ERROR! Failed at signsis ... \n";

  unless (@ARGV == 0) {
    $error_para = shift @ARGV;
    print STDERR "Unknown parameter \"$error_para\" in the command line\n";
    exit 1;
  }
}


# The implemetation of 'createsis dump ...'
sub dumpFunc() {

  if ($key ne '') {
    print STDERR "\"-key $key\" not supported\n";
    exit 1;
  }

  if ($cert ne '') {
    print STDERR "\"-cert $cert\" not supported\n";
    exit 1;
  }

  if ($passphrase ne '') {
    print STDERR "\"-pass $passphrase\" not supported\n";
    exit 1;
  }

  $sisfile_ip=shift @ARGV;

  unless (defined $sisfile_ip) {
    print STDERR "Input SIS file not found.\n";
    exit 1;
  }

  unless (@ARGV == 0) {
    $error_para = shift @ARGV;
    print STDERR "Unknown parameter \"$error_para\" in the command line\n";
    exit 1;	
  }

  (system "signsis -o \"$sisfile_ip\"")  == 0 or
    die "ERROR! Failed at signsis ... \n";
}


# The implemetation of 'createsis strip ...'
sub stripFunc() {

  if ($key ne '') {
    print STDERR "\"-key $key\" not supported\n";
    exit 1;
  }

  if ($cert ne '') {
    print STDERR "\"-cert $cert\" not supported\n";
    exit 1;
  }

  if ($passphrase ne '') {
    print STDERR "\"-pass $passphrase\" not supported\n";
    exit 1;
  }

  $sisfile_ip=shift @ARGV;

  unless (defined $sisfile_ip) {
    print STDERR "Input SIS file not found.\n";
    exit 1;
  }

  $sisfile_op=shift @ARGV;

  unless (defined $sisfile_op) {
    print STDERR "Output SIS file not found.\n";
    exit 1;
  }

  unless (@ARGV == 0) {
    $error_para = shift @ARGV;
    print STDERR "Unknown parameter \"$error_para\" in the command line\n";
    exit 1;	
  }

  (system "signsis -u \"$sisfile_ip\" \"$sisfile_op\"") == 0 or
    die "ERROR! Failed at signsis ... \n";
}


# Extract info. from package file.
sub extractPackageInfo() {
  my @pkg_data;
  my $process_line = '';
  my $quote_open = 0;
  my $pkg_component_temp = '';
  my $vendor_temp = '';
  my $signature_temp = '';
  my @signature = ();

  print "Extracting info. from $pkgfile ...\n";

  open (PKGFILE, "$pkgfile") or 
    die "ERROR! Can't open $pkgfile\n";

  @pkg_data = <PKGFILE>;

  PKG_LINE: foreach my $pkg_line (@pkg_data) {

      # split the line into an array
      my @line_char = split (//,$pkg_line);

    CHAR: for (my $char_pos = 0; $char_pos < $#line_char; $char_pos++) {
	
	if ($line_char[$char_pos] eq '&' || $process_line eq 'lang') {

	  ############## languages ##############
	  $process_line = 'lang';
	  
	  if ($line_char[$char_pos] eq ';') {
	    # comment line
	    # ignore it
	    $process_line = '';
	    next PKG_LINE;

	  } elsif ($line_char[$char_pos] =~ /[a-z|A-Z]/) {
	    my $lang_temp = uc ($line_char[$char_pos++].$line_char[$char_pos]);
		$char_pos++;
			if($line_char[$char_pos] eq '(')
				{
				$char_pos++;
				my $lang_temp = uc ($lang_temp.$line_char[$char_pos]);
				$char_pos++;
				}
			else
				{
				$char_pos--;
				}
	    push (@languages, $lang_temp);
	    
	    if ($char_pos < $#line_char){
	      next CHAR;
	    }
	  } elsif ($line_char[$char_pos] eq ' ' ||
		   $line_char[$char_pos] eq '&' ||
		   $line_char[$char_pos] eq ',') {
	    next CHAR;
	  } else {
	    $process_line = '';
	    
	    # redo this last line, as there are unknown character in this languages line
	    redo PKG_LINE;
	  }
	} #if ($line_char[$char_pos] eq '&' || $process_line eq 'lang')


	if ($line_char[$char_pos] eq '*' || $process_line eq 'key_cert') {
	  ############### package-signature ##############
	
	  $process_line = 'key_cert';

	  if ($line_char[$char_pos] eq '"') {
	    if ($quote_open == 1) {
	      # set to false (0)
	      $quote_open = 0;

	      push (@signature, $signature_temp);
	      
	      # clear the content
	      $signature_temp = '';
	    } else {
	      # set to true (1)
	      $quote_open = 1;
	    }

	    next CHAR;

	  } elsif ($quote_open == 1) {
	    # append the signature
	    $signature_temp .= $line_char[$char_pos];
	    next CHAR;

	  } elsif ($line_char[$char_pos] eq ' ' ||
		   $line_char[$char_pos] eq '*' ||
		   $line_char[$char_pos] eq ',' ||
		   $line_char[$char_pos] eq '=' ||
		   uc ($line_char[$char_pos]) eq 'K' ||
		   uc ($line_char[$char_pos]) eq 'E' ||
		   uc ($line_char[$char_pos]) eq 'Y') {
	    next CHAR;
	    
	  } else {
	    # Exit extracting key/cert
	    
	    $key = $signature[0];
	    $cert = $signature[1];
	    
	    if ($#signature == 2 ) {
	      if ($passphrase eq '') {
		$passphrase = $signature[2];
	      }
	    }

	    $process_line = '';

	    # redo this last line, as there are unknown character in the signature line
	    redo PKG_LINE;
	  }

	  last;
	} # if ($line_char[$char_pos] eq '*' || $process_line eq 'key_cert')
	
	
	if ($line_char[$char_pos] eq '#' || $process_line eq 'pkg_hdr') {

	  ############## package-header ##############
	  $process_line = 'pkg_hdr';
	  
	  if ($line_char[$char_pos] eq '"') {
	    if ($quote_open == 1) {
	      # set to false (0)
	      $quote_open = 0;

	      push (@package_components, $pkg_component_temp);
	      
	      # clear the content
	      $pkg_component_temp = '';
	    } else {
	      # set to true (1)
	      $quote_open = 1;
	    }

	    next CHAR;

	  } elsif ($quote_open == 1) {
	    # append the package component
	    $pkg_component_temp .= $line_char[$char_pos];
	    next CHAR;

	  } elsif ($line_char[$char_pos] eq '}') {
	    # Exit package-hearder processes
	    $process_line = '';
	    next PKG_LINE;

	  } elsif ($line_char[$char_pos] eq ' ' ||
		   $line_char[$char_pos] eq '#' ||
		   $line_char[$char_pos] eq ',' ||
		   $line_char[$char_pos] eq '{') {
	    next CHAR;

	  }
	} # if ($line_char[$char_pos] eq '#' || $process_line eq 'pkg_hdr')
	
	
	if ($line_char[$char_pos] eq '%' || $process_line eq 'vendor') {
	  
	  ############### vendor ##############
	  $process_line = 'vendor';
	  
	  if ($line_char[$char_pos] eq '"') {
	    if ($quote_open == 1) {
	      # set to false (0)
	      $quote_open = 0;
	      
	      push (@vendor, $vendor_temp);
	      
	      # clear the content
	      $vendor_temp = '';
	    } else {
	      # set to true (1)
	      $quote_open = 1;
	    }

	    next CHAR;

	  } elsif ($quote_open == 1) {
	    # append the vendor
	    $vendor_temp .= $line_char[$char_pos];
	    next CHAR;

	  } elsif ($line_char[$char_pos] eq '}') {
	    # Exit the vendor processes
	    $process_line = '';
	    next PKG_LINE;

	  } elsif ($line_char[$char_pos] eq ' ' ||
		   $line_char[$char_pos] eq '%' ||
		   $line_char[$char_pos] eq ',' ||
		   $line_char[$char_pos] eq '{') {
	    next CHAR;
	  }

	  last;
	} # if ($line_char[$char_pos] eq '%') {

      if ($line_char[$char_pos] eq ';') {
	# comment line
	# ignore it
	last;
      }

      last;
    }
  }
    
  close(PKGFILE);
  return 0;
}

# Generate the distinguished-name-string for the self-signed public key certificate file.
sub generateDN() {
  my @pkg_data;
  my $en_pos = 0;
  my $lang_pos = 0;
  
  # Find out the position of English in the list (if present)
  for(; $lang_pos <= $#languages; $lang_pos++) {
    
    if ($languages[$lang_pos] eq 'EN') {
      $en_pos = $lang_pos;
      
      last;
    }
  }

  $commonName = $package_components[$en_pos];
  $vendorName = $vendor[$en_pos];
  
  # Patch the $commonName upto 64 byte of random hex
  for (my $count = length ($commonName); $count<65; $count++) {
    $commonName .= sprintf "%.2x", int rand(255);
  }
  
  return 0;
}


# Print the Usage descriptions
sub Usage () {
  print <<ENDUSAGESTRING;

createsis, version 1.0
Copyright (c) 2005 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.

Mandatory SIS file signing for SYMBIAN OS v9.1 onwards. It supports
creating new SIS files from package files, signs existing package files and
generates new key/certificate pairs for purposes of signing. If neither
certificate or key are specified as outlined in the usage scenarios below,
a self-signed certificate will be generated and used to sign the resulting
SIS file. In addition, createsis may be used to dump details of signatures
and certificate chains in a pre-existing SIS file.

Usage : createsis [-h | -?] <action>

 Options:
    -h Show this help page
    -? Show this help page

 action: 
    create
    Description : Create and sign the generated sisfile.
    Usage : createsis create [-key <key>] [-cert <cert>] [-pass <pass>] pkgfile
            -key        [optional]The certificate's private key file
            -cert       [optional]The certificate file used for signing
            -pass       [depend on how key/cert was generated OR 
                         can use this option to specify the passphase for the new key/cert]
                         The certificate's private key file's passphrase
            pkgfile     The input package file.

    sign
    Description : Sign the sisfile.
    Usage : createsis sign -key <key> -cert <cert> [-pass <pass>] sis_input sis_output
            -key        The certificate's private key file
            -cert       The certificate file used for signing
            -pass       [depend on how key/cert was generated]The certificate's private 
                         key file's passphrase
	    -sis_input  The SIS file to be signed
	    -sis_output The SIS file generated by signing

    dump
    Description : Display details of all valid signatures and the associated certificates
    in the sisfile.
    Usage : createsis dump sis_input
	    -sis_input  The investigated SIS file
 
    strip
    Description : Remove most recent signature from SIS file
    Usage : createsis strip sis_input sis_output
	    -sis_input  The SIS file whose recent signature will be removed
	    -sis_output The SIS file after signature removed

ENDUSAGESTRING

  exit 0;
}
