
sub MAIN(Str $input_file, Str $output_file)
{

    my Str $txt = slurp $input_file;

    my Str $out;
    my Bool $starting = True;

    my $lastbpm;
    my $lcount = 0;
    my $oldTimeSig = 0;       # Remember previous time signature
    LINE:
    for $txt.lines -> $l {
        $lcount++;
        my $l1 = $l;
        $l1 ~~ s/'#' .* $//;      # Remove comment
        my $l2 = $l1.trim;
        next LINE if $l2 ~~ "";        # Ignore empty lines
        given $l2 {

            when / 'tempo' \s+ (\d) \s+ (\d+) \s+ (\d+) $/ {
                #           nb_beats    BPM       repet.
                my $beats = $0;
                my $bpm = $1;
                my $repeats = $2;
                if $beats != $oldTimeSig {
                    $out ~= "T $beats\n";
                    $oldTimeSig = $beats;
                }
                if $starting {
                    $starting = False;
                    $out ~= "B 1 X $bpm\n";
                }
                for 1..$repeats {
                    for 1..$beats -> $b {
                        $out ~= "B {$b % $beats + 1} $b $bpm\n";
                    }
                }
                $lastbpm = $bpm;
            }

            when / 'rampe' \s+ (\d) \s+ (\d+) \s+ (\d+) $/ {
                #           nb_beats   BPM_final    repet.
                my $beats = $0;
                my $newbpm = $1;
                my $repeats = $2;
                my $deltabpm = ($newbpm - $lastbpm) / $beats / $repeats;
                my $bpm = $lastbpm;
                if $beats != $oldTimeSig {
                    $out ~= "T $beats\n";
                    $oldTimeSig = $beats;
                }
                if $starting {
                    $starting = False;
                    $out ~= "B 1 X $bpm\n";
                }
                for 1..$repeats {
                    for 1..$beats -> $b {
                        $out ~= "B {$b % $beats + 1} $b $bpm\n";
                        $bpm  += $deltabpm;
                    }
                }
            }

            when / 'bar' \s+ ('-'? \d+) $/ {
                $out ~= "N $0\n";
            }

            when / 'message' \s+ (\S .+) $/ {
                $out ~= "M $0\n";
            }

            when / 'message' $/ {
                $out ~= "M\n";
            }

            when / 'stop' $/ {
                # Provisoire, pour bien finir
                $out ~= "B 0 X 120\n";
                $out ~= "S\n";
            }

            default {
                die "Bad syntax at line $lcount";
            }
        }
    }


    spurt $output_file, $out;
}
