// Multigravity Frost / Neon particle engine.
//
// Cursor trail faithfully ports the timing and micro-petal behavior from the
// author's aura-companion-plus/src/components/CursorTrail.tsx:
// 32 ms throttle, 6-12 px, hue 320-350 pink petals, +/-15 px horizontal
// drift, 10-30 px fall, 180 degree rotation, 700 ms ease-out fade/scale.
// WPF adaptation adds a click-only sakura bloom and low-opacity radial flare.
// All particles are pointer-transparent, bounded and removed on completion.
using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Shapes;

namespace Multigravity {
    public sealed class FrostEffects {
        private readonly Window window;
        private readonly Canvas sky;
        private readonly Canvas sparks;
        private readonly Random random = new Random();
        private readonly LinkedList<UIElement> alive = new LinkedList<UIElement>();
        private DateTime lastTrail = DateTime.MinValue;
        private Point previous = new Point(-100, -100);
        private bool detached;
        private const int MaxTransient = 60;
        private const double TrailThrottleMs = 32;
        private static readonly IEasingFunction Ease = new CubicEase { EasingMode = EasingMode.EaseOut };
        private static readonly Geometry PetalGeometry = CreatePetalGeometry();
        private static readonly Effect PetalGlow = CreatePetalGlow();

        private FrostEffects(Window w, Canvas background, Canvas overlay) {
            window = w; sky = background; sparks = overlay;
        }
        public static FrostEffects Attach(Window window, Canvas background, Canvas overlay) {
            if (window == null || background == null || overlay == null)
                throw new ArgumentNullException("window and two canvases are required.");
            var fx = new FrostEffects(window, background, overlay);
            fx.Initialize();
            return fx;
        }
        private static Color Col(byte a, byte r, byte g, byte b) {
            return Color.FromArgb(a, r, g, b);
        }
        private static Geometry CreatePetalGeometry() {
            // Rounded diagonal leaf: visual match for CSS border-radius: 150% 0 150% 0
            // from aura-companion-plus, rather than the old round-dot cursor.
            var g = Geometry.Parse("M 1,0 C 8,0 12,4 12,9 C 10,12 5,12 1,12 C 0,7 0,3 1,0 Z");
            g.Freeze();
            return g;
        }
        private static Effect CreatePetalGlow() {
            var shadow = new DropShadowEffect {
                BlurRadius = 8, ShadowDepth = 0, Opacity = 0.55,
                Color = Col(255, 239, 72, 158)
            };
            shadow.Freeze();
            return shadow;
        }
        private static RadialGradientBrush Halo(Color center) {
            var b = new RadialGradientBrush();
            b.Center = new Point(.5, .5);
            b.GradientOrigin = new Point(.5, .5);
            b.RadiusX = .5; b.RadiusY = .5;
            b.GradientStops.Add(new GradientStop(center, 0.0));
            b.GradientStops.Add(new GradientStop(Col(0,center.R,center.G,center.B),1));
            b.Freeze(); return b;
        }
        private void Initialize() {
            AddGlow(440, 310, 100, -110, Col(84, 207, 44, 123), 18);
            AddGlow(355, 305, -100, 260, Col(55, 106, 54, 151), 23);
            for (int i = 0; i < 23; i++) AddSnowflake();
            window.PreviewMouseMove += MouseMoved;
            window.PreviewMouseLeftButtonDown += MouseClicked;
            window.MouseLeave += MouseLeft;
            window.Closed += Closed;
        }
        private void AddGlow(double width, double height, double x, double y, Color color, double seconds) {
            var glow = new Ellipse {
                Width = width, Height = height,
                Fill = Halo(color), IsHitTestVisible = false
            };
            Canvas.SetTop(glow,y); Canvas.SetLeft(glow,x);
            sky.Children.Add(glow);
            glow.BeginAnimation(Canvas.LeftProperty, new DoubleAnimation {
                From = x - 24, To = x + 35,
                Duration = new Duration(TimeSpan.FromSeconds(seconds)),
                AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever
            });
        }
        private void AddSnowflake() {
            double size = 1.1 + random.NextDouble() * 2.4;
            var flake = new Ellipse {
                Width = size, Height = size,
                Fill = new SolidColorBrush(random.Next(4) == 0
                    ? Col(210,255,176,224) : Col(190,232,231,240)),
                Opacity = .12 + random.NextDouble() * .26,
                IsHitTestVisible = false
            };
            Canvas.SetLeft(flake,random.NextDouble()*1200);
            sky.Children.Add(flake);
            flake.BeginAnimation(Canvas.TopProperty,new DoubleAnimation {
                From = -50 - random.NextDouble()*830, To = 1100,
                Duration = new Duration(TimeSpan.FromSeconds(19 + random.NextDouble()*17)),
                RepeatBehavior = RepeatBehavior.Forever
            });
        }
        private static bool Inside(Point p, Canvas c) {
            return p.X >= 0 && p.Y >= 0 && p.X <= c.ActualWidth && p.Y <= c.ActualHeight;
        }
        private void MouseMoved(object sender, MouseEventArgs e) {
            if (detached || window.WindowState == WindowState.Minimized) return;
            Point p = e.GetPosition(sparks);
            if (!Inside(p,sparks)) return;
            DateTime now = DateTime.UtcNow;
            if ((now - lastTrail).TotalMilliseconds < TrailThrottleMs) return;
            double dx = p.X - previous.X, dy = p.Y - previous.Y;
            if (dx*dx + dy*dy < 25) return;
            previous = p; lastTrail = now;
            // Same drifting/shrinking sakura petal as the author's React site.
            SpawnPetal(p.X,p.Y,6+random.NextDouble()*6,
                random.NextDouble()*30-15,10+random.NextDouble()*20,
                0.7,180,false);
        }
        private void MouseClicked(object sender, MouseButtonEventArgs e) {
            if (detached || window.WindowState == WindowState.Minimized) return;
            Point p = e.GetPosition(sparks);
            if (!Inside(p,sparks)) return;
            SpawnFlash(p.X,p.Y);
            for(int i=0;i<10;i++){
                double angle = i * Math.PI * 2.0 / 10.0 + random.NextDouble()*.3;
                double radius = 18 + random.NextDouble()*34;
                SpawnPetal(p.X,p.Y,5+random.NextDouble()*7,
                    Math.Cos(angle)*radius,Math.Sin(angle)*radius+8,
                    .55+random.NextDouble()*.2,180+random.NextDouble()*120,true);
            }
        }
        private void MouseLeft(object sender, MouseEventArgs e) {
            previous = new Point(-100,-100);
        }
        private void AddTransient(FrameworkElement element) {
            while (alive.Count >= MaxTransient) {
                var oldest = alive.First;
                alive.RemoveFirst();
                sparks.Children.Remove(oldest.Value);
            }
            element.IsHitTestVisible = false;
            sparks.Children.Add(element);
            alive.AddLast(element);
        }
        private void FadeRemove(FrameworkElement element, double seconds, double from) {
            var fade = new DoubleAnimation {
                From=from, To=0,
                Duration=new Duration(TimeSpan.FromSeconds(seconds)),
                FillBehavior=FillBehavior.HoldEnd,
                EasingFunction=Ease
            };
            fade.Completed += delegate(object sender, EventArgs args) {
                alive.Remove(element);
                sparks.Children.Remove(element);
            };
            element.BeginAnimation(UIElement.OpacityProperty, fade);
        }
        private void SpawnPetal(double x,double y,double size,double dx,double dy,
                                double seconds,double rotation,bool burst) {
            if(detached) return;
            byte hueR = 246;
            byte hueG = (byte)(137 + random.Next(42));
            byte hueB = (byte)(207 + random.Next(35));
            var b = new RadialGradientBrush();
            b.Center = new Point(.3,.3); b.GradientOrigin = new Point(.3,.3);
            b.RadiusX=.96; b.RadiusY=.96;
            b.GradientStops.Add(new GradientStop(Col(255,255,220,239),0));
            b.GradientStops.Add(new GradientStop(Col(255,hueR,hueG,hueB),.6));
            b.GradientStops.Add(new GradientStop(Col(230,185,77,153),1));
            b.Freeze();
            var leaf = new Path {
                Width=size, Height=size, Stretch=Stretch.Fill, Data=PetalGeometry,
                Fill=b, Effect=PetalGlow, IsHitTestVisible=false,
                Opacity=burst?.98:.9,
                RenderTransformOrigin=new Point(.5,.5)
            };
            var transforms = new TransformGroup();
            var rotate = new RotateTransform();
            var scale = new ScaleTransform(1,1);
            transforms.Children.Add(rotate);
            transforms.Children.Add(scale);
            leaf.RenderTransform = transforms;
            Canvas.SetLeft(leaf,x-size/2);
            Canvas.SetTop(leaf,y-size/2);
            AddTransient(leaf);
            var duration = new Duration(TimeSpan.FromSeconds(seconds));
            var driftX = new DoubleAnimation { From=x-size/2,To=x+dx-size/2,
                Duration=duration,EasingFunction=Ease };
            var driftY = new DoubleAnimation { From=y-size/2,To=y+dy-size/2,
                Duration=duration,EasingFunction=Ease };
            leaf.BeginAnimation(Canvas.LeftProperty,driftX);
            leaf.BeginAnimation(Canvas.TopProperty,driftY);
            rotate.BeginAnimation(RotateTransform.AngleProperty,new DoubleAnimation {
                From=0,To=rotation,Duration=duration,EasingFunction=Ease
            });
            var shrink = new DoubleAnimation { From=1,To=.4,Duration=duration,EasingFunction=Ease };
            scale.BeginAnimation(ScaleTransform.ScaleXProperty,shrink);
            scale.BeginAnimation(ScaleTransform.ScaleYProperty,shrink);
            FadeRemove(leaf,seconds,burst?.98:.9);
        }
        private void SpawnFlash(double x,double y) {
            var circle = new Ellipse {
                Width=64, Height=64, Fill=Halo(Col(138,255,71,160)),
                IsHitTestVisible=false, Opacity=.55,
                RenderTransformOrigin=new Point(.5,.5)
            };
            var scale=new ScaleTransform(.55,.55);
            circle.RenderTransform=scale;
            Canvas.SetLeft(circle,x-32);Canvas.SetTop(circle,y-32);
            AddTransient(circle);
            var duration=new Duration(TimeSpan.FromSeconds(.48));
            var growth=new DoubleAnimation { From=.55,To=1.5,Duration=duration,EasingFunction=Ease };
            scale.BeginAnimation(ScaleTransform.ScaleXProperty,growth);
            scale.BeginAnimation(ScaleTransform.ScaleYProperty,growth);
            FadeRemove(circle,.48,.55);
        }
        private void Closed(object sender,EventArgs e){
            detached=true;
            window.PreviewMouseMove-=MouseMoved;
            window.PreviewMouseLeftButtonDown-=MouseClicked;
            window.MouseLeave-=MouseLeft;
            window.Closed-=Closed;
            sky.Children.Clear(); sparks.Children.Clear(); alive.Clear();
        }
    }
}
