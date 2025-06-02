
constant d = 10;
my $n = 100;   # Nombre de points pour chaque courbe

my Real @t;
my Real @x;
my Real @y;


sub f1x(Real $t --> Real)  { 2 * d * cos($t) }
sub f1y(Real $t --> Real)  { 2 * d * (1 + sin($t)) }

sub f2x(Real $t --> Real)  { d * (1 + cos($t)) }
sub f2y(Real $t --> Real)  { d * (2 + sin($t)) }


# Part 1
@t = (-$n .. 0) >>*>> (pi/2/$n);
@x = @t>>.&f1x;
@y = @t>>.&f1y;

# Part 2
@t = (0 .. $n) >>*>> (pi/$n);
@x.append: @t>>.&f2x;
@y.append: @t>>.&f2y;

# Part 3
@x.append: (0, 0);
@y.append: (2*d, 0);


my Str $out;
for @x Z @y -> ($x, $y) { $out ~= "$x $y\n" }
spurt "curve2.txt", $out;


