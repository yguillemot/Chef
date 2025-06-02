
# A QGraphics objects example

use Qt::QtWidgets;
use Qt::QtWidgets::QApplication;
use Qt::QtWidgets::QBrush;
use Qt::QtWidgets::QColor;
use Qt::QtWidgets::QFont;
use Qt::QtWidgets::QGraphicsEllipseItem;
use Qt::QtWidgets::QGraphicsItem;
use Qt::QtWidgets::QGraphicsScene;
use Qt::QtWidgets::QGraphicsSimpleTextItem;
use Qt::QtWidgets::QGraphicsView;
use Qt::QtWidgets::QHBoxLayout;
use Qt::QtWidgets::QPen;
use Qt::QtWidgets::QPushButton;
use Qt::QtWidgets::QRectF;
use Qt::QtWidgets::QTimer;
use Qt::QtWidgets::QWidget;
use Qt::QtWidgets::Qt;




# Size of the scene
constant W = 800;
constant H = 750;

# Margin (Don't start too close to the edges)
constant M = 150;

# Size of the objects
constant D = 50;

# Horizontal and vertical speed range (px/ms)
constant Vmin = 0.02;
constant Vmax = 0.20;

# Tempo (beat/mn)
constant $tempo = 170;

# Timer period (ms)
constant T = 10;

# Number of points in a trajectory
constant N = 500;
# constant N = (10 * 60 / ($tempo / T)).Int;

constant ND = 7;    # Nombre de disques pour simuler le déplacement de la baguette
                    # (avec 1 seul disque, allure "sautillante" et "hachée")




# $idx = indice du point dans la table des positions
# $b = numero du temps
# $it = compteur des tops du chronomètre (pêriode T)
# $nbm = nombre dec battements par mesure (ex. : 3 si mesure à 3/4)

# $idx = ((N * $it * T / $tempo) / N).Int % N;
# $b = (($nbm * $it * T / $tempo) / $nbm).Int % $nbm;


class Action
{
    has Str $.type;
    has Str $.geste;
    has Str $.affichage;
    has Int $.duree;
    has Str $.message;
    has Duration $.startTime;  # Time related to tne end of the last Pause
    has Duration $.endTime;    # Time related to the end of the last Pause

    method say
    {
        print $.type;
        print " $.geste" with $!geste;
        print " '$.affichage'" with $!affichage;
        print " $.duree" with $!duree;
        print " \"$.message\"" with $!message;
        print "   sT = $.startTime" with $!startTime;
        print "   eT = $.endTime" with $!endTime;
        say "";
    }
}

class Program
{
    has Action @.actions;

    method input(Str $file)
    {
        my Str $data = slurp $file;

        # Suppression des commentaires
        $data ~~ s:g /'#'\N*\n/\n/;

        # Suppression des lignes blanches
        $data ~~ s:g /^^\s*\n//;

        # say "=======";
        # say $data;
        # say "=======";

        my Duration $time .= new: 0;
        for $data.lines>>.trim -> $l {
            given $l {
                when /^ 'I'/ {
                    # say "I $l";
                    @!actions.push(Action.new: type => 'I');
                    $time .= new: 0;
                }
                when /^ 'P'/ {
                    # say "P $l";
                    @!actions.push(Action.new: type => 'P');
                    $time .= new: 0;
                }
                when /^ 'B' \s+ (.) \s+ (.) \s+ (\d+) / {
                    # say "B $0 $1 : $l";
                    my $previousTime = $time;
                    $time += 60 / $2.Int;
                    my $aff = $1.Str ~~ 'X' ?? "" !! $1.Str;
                    @!actions.push(Action.new: type => 'B',
                                               geste => $0.Str,
                                               affichage => $aff,
                                               duree => $2.Int,
                                               startTime => $previousTime,
                                               endTime => $time);
                }
                when /^ 'S'/ {
                    # say "S $l";
                    @!actions.push(Action.new: type => 'S');
                    $time .= new: 0;
                }
                when /^ 'M' \s+ (\S.*)/ {
                    @!actions.push(Action.new: type => 'M',
                                               message => $0.Str.trim);
                }
                when /^ 'M' / {
                     @!actions.push(Action.new: type => 'M',
                                               message => "");
                }
            }
        }

        # say "+" x 7;
        # @!actions>>.say;
        # say "+" x 7;
        # exit;
    }
}





class Scene { ... }

# A graphical moving object
class Baguette is QtObject
{
    has Scene $.scene is rw;    # The scene where the item is displayed
    has QGraphicsItem $.gitem;  # The graphical item itself
    has Real ($.w, $.h);        # The size of the Item

    # Adjunct graphical texts showing speed and coords of the main object
#     has QGraphicsSimpleTextItem $.speed;
#     has QGraphicsSimpleTextItem $.coords;

    has QPen $.pen;             # Used to draw the main object if defined
    has QBrush $.brush;         # Used to draw the main object if defined
    has QFont $.font is rw;     # Used to draw the main object text if defined
    has Int $.pointSize;        # Used to draw the main object text if defined

    submethod TWEAK
    {
        # Set up pen and brush if needed
        self.gitem.setPen: $!pen with $!pen;
        self.gitem.setBrush: $!brush with $!brush;

        # Set up font if needed
        with $!pointSize {
            $!font = self.gitem.font without $!font;
            $!font.setPointSize: $!pointSize ;
            self.gitem.setFont: $!font;
        }

        # Get object size
        $!w = $!gitem.boundingRect.width;
        $!h = $!gitem.boundingRect.height;

#         # Create a child text showing the object speed
#         $!speed = QGraphicsSimpleTextItem.new:
#                             "{(1000 * sqrt($!vx**2 + $!vy**2)).Int} px/s";
#         my $sh = $!speed.boundingRect.height;
#         $!speed.setParentItem: $!gitem;
#         $!speed.setPos: $!gitem.x, $!gitem.y + $!h;
#
#         # Create a child text object showing the object coordinates
#         $!coords = QGraphicsSimpleTextItem.new;
#         $!coords.setParentItem: $!gitem;
#         $!coords.setPos: $!gitem.x, $!gitem.y + $!h + $sh;

        # Add the object to the scene
        $!scene.addItem: $!gitem;

        # Move the baguette to the starting on the scene
        $!gitem.setPos: W / 2 - D / 2, H - D;
    }

    method move($x, $y) is QtSlot        # Move current object after a timer period
    {
        # Set new position
        # say "before move";
        # say "x: ", $x;
        # say "y: ", $y;
        $!gitem.setPos: $x, $y;
    }
}


# A QGraphicsScene with a red rectangle showing its useful area
class Scene is QGraphicsScene
{
    has Int ($.x1, $.x2, $.y1, $.y2);   # Limits of the useful part of the scene
    has QGraphicsSimpleTextItem $.display;
    has QGraphicsSimpleTextItem $.texte;

    submethod TWEAK
    {
        self.QGraphicsScene::subClass: $!x1, $!y1, $!x2, $!y2;

        # Draw a red line around the useful part of the scene
        my QColor $fgc = QColor.new: Qt::red;
        my QPen $pen = QPen.new: $fgc;
        $pen.setWidth: 2;
        my QRectF $r = self.sceneRect;
        self.addLine: $r.left, $r.top, $r.right, $r.top, $pen;
        self.addLine: $r.left, $r.bottom, $r.right, $r.bottom, $pen;
        self.addLine: $r.left, $r.top, $r.left, $r.bottom, $pen;
        self.addLine: $r.right, $r.top, $r.right, $r.bottom, $pen;

        $!display .= new: "Mon texte";
        my $font = $!display.font;
        $font.setPointSize: 50;
        $!display.setFont: $font;
        self.addItem: $!display;                # Add the object to the scene
        $!display.setPos: W / 2, 100;

        $!texte .= new: "Des infos";
        $font.setPointSize: 80;
        $!texte.setFont: $font;
        self.addItem: $!texte;                # Add the object to the scene
        $!texte.setPos: 50, H / 2;
    }

    method montrer(Str $txt)
    {
        $.display.setText: $txt;
    }

    method message(Str $txt)
    {
        # say "txt : '", $txt, "'";
        $.texte.setText: $txt;
    }

}

# Compute a linear trajectory
#    ($ax, $ay) : starting point
#    ($bx, $by) : ending point
#    $s : distance between two consecutive points
#    $i : starting index in tables
#    (@x, @y) : tables of points
#    Returns the next unused index
sub computePoints(Real $ax, Real $ay,
                  Real $bx, Real $by,
                  Real $ds, Int $idx, @x, @y --> Int)
{
    # say "ds=$ds";
    my Int $n = (sqrt(($ax - $bx)**2 + ($ay - $by)**2) / $ds).Int;
    my Real $dx = ($bx - $ax) / $n;
    my Real $dy = ($by - $ay) / $n;
    my ($x, $y) = ($ax, $ay);
    # say "n=$n";
    for 1..$n {
        @x.push: $x;
        @y.push: $y;
        $x += $dx;
        $y += $dy;
    }
    return $idx + $n;
}

class Trajectory
{
    has Str $.type;
    has Real ($.ax, $.ay);    # Starting point
    has Real ($.bx, $.by);    # First step
    has Real ($.cx, $.cy);    # Summit

    has Real (@.x, @.y);      # List of all the points

    submethod TWEAK
    {

        if $!type ~~ "TRIANGLE" {
            # say "A : ($!ax, $!ay)   B : ($!bx, $!by)   C : $!cx, $!cy)";
            # say ($!ax - $!bx)**2;

            # Compute perimeter
            my $p = sqrt(($!ax - $!bx)**2 + ($!ay - $!by)**2)
                    + sqrt(($!bx - $!cx)**2 + ($!by - $!cy)**2)
                    + sqrt(($!cx - $!ax)**2 + ($!cy - $!ay)**2);

            my $ds = $p / N;
            # say "P = $p   ds = $ds";

            # Compute all the points
            my $nexti = computePoints($!ax, $!ay, $!bx, $!by, $ds, 0, @!x, @!y);
            $nexti = computePoints($!bx, $!by, $!cx, $!cy, $ds, $nexti, @!x, @!y);
            $nexti = computePoints($!cx, $!cy, $!ax, $!ay, $ds, $nexti, @!x, @!y);

            # Sometimes, there are less than N points in @.x and @.y
            while $nexti < N {
                my Int $i = $nexti - 1;
                (@!x[$nexti], @!y[$nexti]) = (@!x[$i], @!y[$i]);
                $nexti++;
            }
        } elsif $!type ~~ "POINT" {
            for (0...^N) -> $i {
                @!x.push: $!ax;
                @!y.push: $!ay;
            }
        } else {
            die "Unknown trajectory type : $!type";
        }
    }
}


class Sequencer is QtObject
{
    has QGraphicsScene $.scene;
    has Baguette @.baguette;
    has Trajectory @.beat[5];
    has $.program;

    has $!actions;

    has $.x is rw = W / 2 - D / 2;
    has $.y is rw = H - D;

    has Bool $!newBeat;
    has Int $!b;
    has Int $!i;

#     has $!now;

    has Real $!Tb = 60 / $tempo;    # Durée d'un temps
    has Real $!Ts = $!Tb / N;       # Durée d'un échantillon de déplacement
    has Real $!t0;
    has Bool $!running = False;

    has Int $!count;
    has Int $ai;           # Actions index
    has Int $aimax = 0;    # Max actions index


    submethod TWEAK
    {
        @!beat[0] .= new:   type => "POINT",
                            ax => W / 2,      ay => H / 2;

        @!beat[1] .= new:   type => "TRIANGLE",
                            ax => W / 2,      ay => H - D,
                            bx => W - D,      by => H / 2 - D / 2,
                            cx => W / 2,      cy => 0;

        @!beat[2] .= new:   type => "TRIANGLE",
                            ax => W / 2,      ay => H - D,
                            bx => D,          by => 3 * H / 4 - D / 2,
                            cx => W / 2,      cy => H / 2 - D / 2;

        @!beat[3] .= new:   type => "TRIANGLE",
                            ax => W / 2,      ay => H - D,
                            bx => W - D,      by => 3 * H / 4 - D / 2,
                            cx => W / 2,      cy => H / 2 - D / 2;

        @!beat[4] = @!beat[2];

#         $!now = DateTime.now.Instant;

        $!actions = $!program.actions;
    }

    method work is QtSlot {

        # say "work ai=$!ai aimax=$!aimax  running=$!running";

        $!running = False if $!ai >= $!aimax;
        return if !$!running;

        given $!actions[$ai].type {
            when 'B' {

                if $!newBeat {
                    $!newBeat = False;
                    # $!Tb = 60 / @!actions[$ai].duree;   # Durée d'un temps

                    # Durée d'un échantillon de déplacement
                    $!Ts = 60 / $!actions[$ai].duree / N;
                }

                my $t = now - $!t0;

                if $t > $!actions[$!ai].endTime {
                    $!ai++;
                    $!newBeat = True;
                    # say "NEWBEAT";
                    return;  # Solution de facilité, mais on perd un tic du timer
                }

                # say "AI = $!ai";
                $!b = $!actions[$!ai].geste.Int;
                # say "b = ", $!b;
                $!i = (($t -  $!actions[$!ai].startTime) / $!Ts).Int;
                # say "i = ", $!i;

                $!count++;
                @.baguette[$!count % @!baguette.elems].move:
                                            @.beat[$!b].x[$!i], @.beat[$!b].y[$!i];

                $.scene.montrer: $!actions[$ai].affichage;
            }
            when 'M' {
                # say "M msg ='", $!actions[$ai].message, "'";
                $.scene.message: $!actions[$ai].message;
                $!ai++;
            }
            when 'P' {
                # say "Action P",
                $!ai++;           }
            when 'S' {
                # say "Action S",
                $!ai++;           }
            when 'I' {
                # say "Action I",
                $!ai++;           }
            default {
                die "Unknown action type {$!actions[$ai].type} !!!";
            }
        }

    }

    method init()
    {
        $!ai = 0;
        $!aimax = $!actions.elems;
        $!b = 1;
        $!i = 0;
        for @.baguette -> $bag {
            $bag.move: @.beat[$!b].x[$!i], @.beat[$!b].y[$!i];
        }
        $!count = 0;
    }

    method start() is QtSlot
    {
        # say "started";
        $!ai = 0;
        $!newBeat = True;
        $!running = True;
        $!t0 = now;
    }

}


####################################################################

my $program = Program.new;
$program.input: "data.txt";

# Create QApplication before creating any other Qt object
my $qApp = QApplication.new("Moving objects example", @*ARGS);

# Create the scene (a QGraphicsScene)
my $scene = Scene.new: x1 => 0, y1 => 0, x2 => W, y2 => H;

# Create the pen and brush needed to draw the graphical objects
my QColor $fgc = QColor.new: Qt::blue;
my QPen $pen = QPen.new: $fgc;
$pen.setWidth: 1;
my QColor $bgc = QColor.new: Qt::red;
my QBrush $brush = QBrush.new: $bgc, Qt::SolidPattern;

# Create some objects moving on the scene
my @mobjs;    # Moving objects list

# Show the scene (needs a QGraphicsView)
my QGraphicsView $view = QGraphicsView.new: $scene;
$view.setMinimumSize: W + 30, H + 30;   # Used scene always visible

#=================
my $window = QWidget.new;    # main window

my $startButton = QPushButton.new('Start');

# Layout

my $layout = QHBoxLayout.new;
$layout.addWidget($view);
$layout.addWidget($startButton);

$window.setLayout($layout);
$window.show;
#=================

# $view.show;

my Sequencer $sequencer .= new: scene => $scene, program => $program;

# Create ND disks to simulate the moving baguette
for 1..ND {
    my $baguette = Baguette.new:
                   scene => $scene,
                   gitem => QGraphicsEllipseItem.new(0, 0, D, D),
                   pen => $pen,
                   brush => $brush;
    $sequencer.baguette.push: $baguette;
}

$sequencer.init;

# Create a timer, set its period and connect it to each moving object
my $timer = QTimer.new;
$timer.setInterval: T;
connect $timer, "timeout", $sequencer, "work";
connect $startButton, "pressed", $sequencer, "start";

# Start the timer
$timer.start;

# Start the sequencer
# $sequencer.start;

# Run the graphical application
$qApp.exec;

