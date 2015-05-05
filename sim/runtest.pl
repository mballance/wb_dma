#!/usr/bin/perl
#*****************************************************************************
#*                             runtest
#*
#* Run a test or tests
#*****************************************************************************

use Cwd;
use Cwd 'abs_path';
use POSIX ":sys_wait_h";
use File::Basename;

# Parameters
$SCRIPT=abs_path($0);
$SCRIPT_DIR=dirname($SCRIPT);

$SIM_DIR=getcwd();
$ENV{SIM_DIR}=$SIM_DIR;

$PROJECT_LOC=dirname($SIM_DIR);
$ENV{PROJECT_LOC} = $PROJECT_LOC;


$test="";
@testlist;
$count=1;
$start=1;
$max_par=2;
$clean=0;
$build=1;
$cmd="";
$quiet="";
$interactive=0;
$debug="false";
$builddir="";
$sim="qs";
$plusargs="";

# Global PID list
@pid_list;

if ($ENV{RUNDIR} eq "") {
  $run_root=getcwd();
  $run_root .= "/rundir";
} else {
  $run_root=$ENV{RUNDIR};
}

# Figure out maxpar first
if (-f "/proc/cpuinfo") {
	open (my $fh, "cat /proc/cpuinfo | grep processor | wc -l|");
	while (<$fh>) {
		chomp;
		$max_par=$_;
	}
} else {
	print "no cpuinfo\n";
}

for ($i=0; $i <= $#ARGV; $i++) {
  $arg=$ARGV[$i];
  if ($arg =~ /^-/) {
    if ($arg eq "-test") {
      $i++;
#      $test=$ARGV[$i];
      push(@testlist, $ARGV[$i]);
    } elsif ($arg eq "-testlist" or $arg eq "-tl") {
		$i++;
		process_testlist($ARGV[$i]);
#    	push(@testlists, $ARGV[$i]);
    } elsif ($arg eq "-count") {
      $i++;
      $count=$ARGV[$i];
    } elsif ($arg eq "-max_par" || $arg eq "-j") {
      $i++;
      $max_par=$ARGV[$i];
    } elsif ($arg eq "-rundir") {
       $i++;
       $run_root=$ARGV[$i];
    } elsif ($arg eq "-clean") {
       $clean=1;
    } elsif ($arg eq "-nobuild") {
       $build=0;
    } elsif ($arg eq "-builddir") {
       $i++;
       $builddir=$ARGV[$i];
    } elsif ($arg eq "-start") {
       $i++;
       $start=$ARGV[$i];
    } elsif ($arg eq "-i") {
       $interactive=1;
    } elsif ($arg eq "-d") {
    	$debug="true";
    } elsif ($arg eq "-quiet") {
       $quiet=1;
    } elsif ($arg eq "-sim") {
    	$i++;
    	$sim=$ARGV[$i];
    } else {
      print "[ERROR] Unknown option $arg\n";
      printhelp();
      exit 1;
    }
  } elsif ($arg =~ /^\+/) {
  	$plusargs = $plusargs . " " . $arg;
  } else {
    if ($arg eq "build") {
      $cmd="build";
    } elsif ($arg eq "clean") {
      $cmd="clean";
    } else {
      printhelp();
      exit 1;
    }
  }
}

# Setup link to rundir if it's different than local
#$local_rundir = getcwd() . "/rundir";
#unless ($run_root eq $local_rundir) {
#  if (-d $local_rundir) { 
#    print "rundir is directory\n";
#  } elsif (-l $local_rundir) {
#    print "rundir is link\n";
#  } else {
#    print "rundir doesn't exist\n";
#  }
#  print "ln -s $run_root rundir\n";
#  system("ln -s $run_root rundir");
#}

$project=basename(dirname($SIM_DIR));

$run_root="${run_root}/${project}";

print "run_root=${run_root}\n";
$ENV{RUN_ROOT}=$run_root;

if ($builddir eq "") {
  $builddir=$ENV{RUN_ROOT};
}

# TODO: platform too?
$builddir = $builddir . "/" . $sim;
$ENV{BUILD_DIR}=$builddir;

print "cmd=$cmd\n";

if ($cmd eq "build") {
  build();
  exit 0;
} elsif ($cmd eq "clean") {
  clean();
  exit 0;
}

if ($#testlist < 0) {
  print "[ERROR] no test specified\n";
  printhelp();
  exit 1
}

if ($interactive == 1 && $count > 1) {
  print "[ERROR] Cannot specify -i and -count > 1 together\n";
  exit 1
}

if ($build == 0 && $clean == 1) {
  print "[ERROR] Cannot specify -nobuild and -clean together\n";
  exit 1;
}


if ($quiet eq "") {
  if ($#testlist > 0) {
    $quiet=1;
  } else {
    $quiet=0;
  }
}

$SIG{'INT'} = 'cleanup';

run_test($clean,$run_root,$test,$count,$quiet,$max_par,$start);

exit 0;

sub printhelp {
  print "runtest [options]\n";
  print "    -test <testname>    -- Name of the test to run\n";
  print "    -count <count>      -- Number of simulations to run\n";
  print "    -max_par <n>        -- Number of runs to issue in parallel\n";
  print "    -rundir  <path>     -- Specifies the root of the run directory\n";
  print "    -builddir <path>   -- Specifies the root of the build directory\n";
  print "    -clean              -- Remove contents of the run directory\n";
  print "    -nobuild            -- Do not automatically build the bench\n";
  print "    -i                  -- Run simulation in GUI mode\n";
  print "    -quiet              -- Suppress console output from simulation\n";
  print "\n";
  print "Example:\n";
  print "    runtest -test foo_test.f\n";
}

$unget_ch_1 = -1;
$unget_ch_2 = -1;

sub process_testlist($) {
	my($testlist_f) = @_;
	my($ch,$ch2,$tok);
	my($cc1, $cc2);
	
	open(my $fh, "<", "$testlist_f") or die "Failed to open $testlist_f";
	$unget_ch_1 = -1;
	$unget_ch_2 = -1;

	while (($ch = get_ch($fh)) != -1) {
		if ($ch eq "/") {
			$ch2 = get_ch($fh);
			if ($ch2 eq "*") {
				$cc1 = -1;
				$cc2 = -1;
				
				while (($ch = get_ch($fh)) != -1) {
					$cc2 = $cc1;
					$cc1 = $ch;
					if ($cc1 eq "/" && $cc2 eq "*") {
						last;
					}
				}
				
				next;
			} elsif ($ch2 eq "/") {
				while (($ch = get_ch($fh)) != -1 && !($ch eq "\n")) {
					;
				}
				unget_ch($ch);
				next;
			} else {
				unget_ch($ch2);
			}
		} elsif ($ch =~/^\s*$/) {
			while (($ch = get_ch($fh)) != -1 && $ch =~/^\s*$/) { }
			unget_ch($ch);
			next;
		}
	
		$tok = "";
		
		while ($ch != -1 && !($ch =~/^\s*$/)) {
			$tok .= $ch;
			$ch = get_ch($fh);
		}
		unget_ch($ch);
	
		push(@testlist, $tok);
	}
	
	close($fh);
}

sub unget_ch($) {
	my($ch) = @_;

	$unget_ch_2 = $unget_ch_1;	
	$unget_ch_1 = $ch;
}

sub get_ch($) {
	my($fh) = @_;
	my($ch) = -1;
	my($count);
	
	if ($unget_ch_1 != -1) {
		$ch = $unget_ch_1;
		$unget_ch_1 = $unget_ch_2;
		$unget_ch_2 = -1;
	} else {
		$count = read($fh, $ch, 1);
		
		if ($count <= 0) {
			$ch = -1;
		}
	}
	
	return $ch;
}

#*********************************************************************
#* run_jobs
#*********************************************************************
sub run_test {
    my($clean,$run_root,$test,$count,$quiet,$max_par,$start) = @_;


    if ($build == 1) {
      build();
    }

    # Now, 
    run_jobs($run_root,$test,$count,$quiet,$max_par,$start);
}

sub build {
    my($ret);

    if ($clean == 1) {
      system("rm -rf ${builddir}") && die;
    }

    system("mkdir -p ${builddir}") && die;
    chdir("$builddir");

    # First, build the testbench
    unless ( -d "${SIM_DIR}/scripts" ) {
    	die "No 'scripts' directory present\n";
    }
    open(CP, "make -C ${builddir} -j ${max_par} -f ${SIM_DIR}/scripts/Makefile SIM=${sim} build |");
    open(LOG,"> ${builddir}/compile.log");
    while (<CP>) {
       print($_);
       print(LOG  $_);
    }
    close(LOG);
    close(CP);
    $ret = $? >> 8;
    if ($ret != 0) {
      die "Compilation Failed";
    }
}

sub clean {
    my($ret);

    system("rm -rf ${builddir}") && die;

    open(CP, "${SIM_DIR}/scripts/clean.sh |");
    while (<CP>) {
      print($_);
    }
    close(CP);
}

#*********************************************************************
#* run_jobs
#*********************************************************************
sub run_jobs {
    my($run_root,$test,$count,$quiet,$max_par,$start) = @_;
    my($run_dir,$i, $alive, $pid, $testname);
    my(@pid_list_tmp,@cmdline);
    my($launch_sims, $n_complete, $n_started, $wpid);
    my($seed,$report_interval,$seed_str,$testlist_idx, $testname);

    $report_interval=20;
    $testlist_idx=0;

    if ($start eq "") {
      $start=1;
    }
    $seed=$start;

    $launch_sims = 1;
    $n_started = 0;

    while ($launch_sims || $#pid_list >= 0) {

        if ($launch_sims) {
            # Start up as many clients as possible (1-N)
            while ($#pid_list+1 < $max_par && $testlist_idx <= $#testlist) {

                $seed_str = sprintf("%04d", $seed);
                $test=$testlist[$testlist_idx];

                $testname=basename($test);
                $testname =~ s/\.f//g;
                
                $run_dir="${run_root}/${testname}_${seed_str}";
                $testlist_idx++;

                $pid = fork();
                if ($pid == 0) {
                	my($result);
                    setpgrp;
                    system("rm -rf $run_dir");
                    system("mkdir ${run_dir}");
                    chdir("$run_dir");
                    
					open(my $fh, "> ${run_dir}/sim.f");
					
	                if (-f "${SIM_DIR}/${test}") {
	                	print $fh "-f \${SIM_DIR}/${test}\n";
	                } elsif (-f "${SIM_DIR}/tests/${test}") {
	                	print $fh "-f \${SIM_DIR}/tests/${test}\n";
	                } elsif (-f "${SIM_DIR}/tests/${testname}.f") {
	                	print $fh "-f \${SIM_DIR}/tests/${test}.f\n";
	                }
                
	                close($fh);
	                
					# Compute the test name from the test file
                	$testname = basename($test);
                	$testname =~ s/\.f//g;
                
                    system("make",
                    	"-f" ,
                    	"$SIM_DIR/scripts/Makefile",
                    	"SIM=${sim}",
                    	"SEED=${seed}",
#                    	"-quiet", "$quiet", 
                    	"TESTNAME=${testname}", 
                    	"INTERACTIVE=${interactive}",
                    	"DEBUG=${debug}",
                    	"PLUSARGS=${plusargs}",
                    	"run"
                    	);
                
                	
                	print "testname=$testname\n"; 
                    
                   
                    open(my $fh, "$SIM_DIR/scripts/status.sh $testname |") or die "Failed to launch check program";
                    
                    $result = <$fh>;
                    
                    print "$result";
                    
                    close($fh);
                    
                    exit 0;
                }

                push(@pid_list, $pid);
                $n_started++;
                $seed++;

                # Launched the number requested
                if ($testlist_idx >= $#testlist) {
                  $launch_sims = 0;
                }
            }
        }

        # Wait for a client to die
        $pid = waitpid(-1, WNOHANG);
        if ($pid == 0) {
            $pid = wait();
        }

        # If -1 is returned, there are no child processes
        if ($pid == -1) {
            last;
        }

        # Update the PID list
        do {
            $n_completed++;
#            if (($n_completed) % $report_interval == 0) {
#              print "$n_completed Complete\n";
#            }
            @pid_list_tmp = (); # empty pid list
            for ($i=0; $i<=$#pid_list; $i++) {
                if ($pid_list[$i] != $pid) {
                    push(@pid_list_tmp, $pid_list[$i]);
                }
            }
            @pid_list = @pid_list_tmp;
            $pid = waitpid(-1, WNOHANG);
        } while ($pid > 0);
    }
#    print "$n_completed Complete\n";
}

sub cleanup {
    print "CLEANUP\n";
    for ($i=0; $i<=$#pid_list; $i++) {
        printf("KILL %d\n", $pid_list[$i]);
        kill -9, $pid_list[$i];
    }
    exit(1);
}



