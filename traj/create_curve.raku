
my Real @t;
my $n = 100;   # Nombre de points
@t = ((-$n/2)..($n/2)) >>*>> (pi/$n);    # $n points de -pi/2 à +pi/2

sub fx(Real $t --> Real) { 0.3*sin(2*$t)*($t+(pi/2)/2)**2 }

sub fy(Real $t --> Real) { cos($t)*(1-$t/3) }

my Real @x = @t>>.&fx;
my Real @y = @t>>.&fy;

my Str $out;
for @x Z @y -> ($x, $y) { $out ~= "$x $y\n" }
spurt "curve.txt", $out;


