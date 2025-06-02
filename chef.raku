
# A QGraphics objects example

use Qt::QtWidgets;
use Qt::QtWidgets::QApplication;
use Qt::QtWidgets::QBrush;
use Qt::QtWidgets::QColor;
use Qt::QtWidgets::QFont;
use Qt::QtWidgets::QGraphicsEllipseItem;
use Qt::QtWidgets::QGraphicsItem;
use Qt::QtWidgets::QGraphicsRectItem;
use Qt::QtWidgets::QGraphicsScene;
use Qt::QtWidgets::QGraphicsSimpleTextItem;
use Qt::QtWidgets::QGraphicsView;
use Qt::QtWidgets::QPen;
use Qt::QtWidgets::QRectF;
use Qt::QtWidgets::QTimer;
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

# Tempo (beat/mn
constant $tempo = 120;

# Timer period (ms)
constant T = 10;

# Number of points in a trajectory
constant N = (10 * 60 / ($tempo / T)).Int;






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
        # Compute and set new position
        $!gitem.setPos: $x, $y;

        # Show the current coordinates of the object
#         $.coords.setText: "(" ~ $x.Int ~ ", " ~ $y.Int ~ ")";

        # If borders of the scene have been reached, simulate a bounce
        # by modifying the speed vector
#         $!vx = -$.vx unless $.scene.x1 < $x < $.scene.x2 - $.w;
#         $!vy = -$.vy unless $.scene.y1 < $y < $.scene.y2 - $.h;
    }
}


# A QGraphicsScene with a red rectangle showing its useful area
class Scene is QGraphicsScene
{
    has Int ($.x1, $.x2, $.y1, $.y2);   # Limits of the useful part of the scene
    has QGraphicsSimpleTextItem $.display;

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
    }

    method montrer(Str $txt)
    {
        $.display.setText: $txt;
    }
}

# Compute a linear trajectory
#    ($ax, $ay) : starting point
#    ($bx, $by) : ending point
#    $s : distance between two consecutive points
#    $i : starting index in tables
#    (@x, @y) : tables of points
#    Returns the next unused index
sub computePoints(Real $ax, Real $ay, Real $bx, Real $by, Real $ds, Int $idx, @x, @y --> Int)
{
say "ds=$ds";
    my Int $n = (sqrt(($ax - $bx)**2 + ($ay - $by)**2) / $ds).Int;
    my Real $dx = ($bx - $ax) / $n;
    my Real $dy = ($by - $ay) / $n;
    my ($x, $y) = ($ax, $ay);
    say "n=$n";
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
    has Real ($.ax, $.ay);    # Starting point
    has Real ($.bx, $.by);    # First step
    has Real ($.cx, $.cy);    # Summit

    has Real (@.x, @.y);      # List of all the points

    submethod TWEAK
    {

    say "A : ($!ax, $!ay)   B : ($!bx, $!by)   C : $!cx, $!cy)";
    say ($!ax - $!bx)**2;
        # Compute perimeter
        my $p = sqrt(($!ax - $!bx)**2 + ($!ay - $!by)**2)
                + sqrt(($!bx - $!cx)**2 + ($!by - $!cy)**2)
                + sqrt(($!cx - $!ax)**2 + ($!cy - $!ay)**2);

        my $ds = $p / N;
        say "P = $p   ds = $ds";

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
    }

}

class Sequencer is QtObject
{
    has QGraphicsScene $.scene;
    has Baguette $.baguette;
    has Trajectory @.beat[4];

    has $.x is rw = W / 2 - D / 2;
    has $.y is rw = H - D;

    has Int $!b;
    has Int $!i;

    has $!now;


    submethod TWEAK
    {
        @!beat[0] .= new:   ax => W / 2,      ay => H - D,
                            bx => W - D,      by => H / 2 - D / 2,
                            cx => W / 2,      cy => 0;

        @!beat[1] .= new:   ax => W / 2,      ay => H - D,
                            bx => D,          by => 3 * H / 4 - D / 2,
                            cx => W / 2,      cy => H / 2 - D / 2;

        @!beat[2] .= new:   ax => W / 2,      ay => H - D,
                            bx => W - D,      by => 3 * H / 4 - D / 2,
                            cx => W / 2,      cy => H / 2 - D / 2;

        @!beat[3] = @!beat[1];

        $!now = DateTime.now.Instant;
    }

    method work is QtSlot {
        $.baguette.move: @.beat[$!b].x[$!i], @.beat[$!b].y[$!i];
        $!i++;
        if $!i >= N {
            $!i = 0;
            $!b++;
            if $!b > 3 {
                $!b = 0;
                my $n = DateTime.now.Instant;
                say $n - $!now;
                $!now = $n;
            }
        }
        $.scene.montrer: "{(4,1,2,3)[$!b]}";
    }

    method init()
    {
        $!b = 0;
        $!i = 0;
        $.baguette.move: @.beat[$!b].x[$!i], @.beat[$!b].y[$!i];
    }

}


####################################################################



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

my $baguette = Baguette.new:
                    scene => $scene,
                    gitem => QGraphicsEllipseItem.new(0, 0, D, D),
                    pen => $pen,
                    brush => $brush;


# Show the scene (needs a QGraphicsView)
my QGraphicsView $view = QGraphicsView.new: $scene;
$view.setMinimumSize: W + 30, H + 30;   # Used scene always visible
$view.show;

my Sequencer $sequencer .= new: scene => $scene, baguette => $baguette;
$sequencer.init;

# Create a timer, set its period and connect it to each moving object
my $timer = QTimer.new;
$timer.setInterval: T;
connect $timer, "timeout", $sequencer, "work";

# Start the timer
$timer.start;

# Run the graphical application
$qApp.exec;

