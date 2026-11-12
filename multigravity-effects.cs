// Lightweight WPF particle engine for Multigravity.
// No timers or network I/O. WPF clocks animate individual short-lived shapes.
using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
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
        private const int MaxTransient = 55;

        private FrostEffects(Window w, Canvas b, Canvas p) {
            window = w; sky = b; sparks = p;
        }

        public static FrostEffects Attach(Window window, Canvas sky, Canvas sparks) {
            if (window == null || sky == null || sparks == null)
                throw new ArgumentNullException("Window and both particle canvases are required.");
            var fx = new FrostEffects(window, sky, sparks);
            fx.Initialize();
            return fx;
        }

        private static Color RGBA(byte r, byte g, byte b, byte a) {
            return Color.FromArgb(a, r, g, b);
        }

        private static RadialGradientBrush Halo(Color color) {
            var brush = new RadialGradientBrush();
            brush.GradientStops.Add(new GradientStop(color, 0.0));
            brush.GradientStops.Add(new GradientStop(RGBA(color.R, color.G, color.B, 0), 1.0));
            brush.Freeze();
            return brush;
        }

        private void Initialize() {
            // Large GPU-friendly, animated radial-glow layers.
            AddGlow(480, 330, 100, -125, RGBA(213, 42, 142, 100), 14);
            AddGlow(370, 340, -130, 265, RGBA(113, 77, 172, 76), 19);
            // Slow airborne snow/dust, all behind clickable content.
            for (int i = 0; i < 23; i++) AddSnowflake();
            window.PreviewMouseMove += MouseMoved;
            window.PreviewMouseLeftButtonDown += MouseClicked;
            window.MouseLeave += MouseLeft;
            window.Closed += Closed;
        }

        private void AddGlow(double width, double height, double x, double y, Color color, double seconds) {
            var glow = new Ellipse();
            glow.Width = width; glow.Height = height;
            glow.Fill = Halo(color);
            glow.IsHitTestVisible = false;
            Canvas.SetLeft(glow, x); Canvas.SetTop(glow, y);
            sky.Children.Add(glow);
            var drift = new DoubleAnimation {
                From = x - 22, To = x + 36,
                Duration = TimeSpan.FromSeconds(seconds),
                AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever
            };
            glow.BeginAnimation(Canvas.LeftProperty, drift);
        }

        private void AddSnowflake() {
            double d = 1.25 + random.NextDouble() * 2.4;
            var flake = new Ellipse();
            flake.Width = d; flake.Height = d;
            flake.Fill = new SolidColorBrush(random.Next(4) == 0
                ? RGBA(255, 175, 222, 220) : RGBA(233, 232, 245, 205));
            flake.Opacity = .16 + random.NextDouble() * .32;
            flake.IsHitTestVisible = false;
            Canvas.SetLeft(flake, random.NextDouble() * 1150);
            sky.Children.Add(flake);
            var fall = new DoubleAnimation {
                From = -50 - random.NextDouble() * 830,
                To = 1110,
                Duration = TimeSpan.FromSeconds(17 + random.NextDouble() * 15),
                RepeatBehavior = RepeatBehavior.Forever
            };
            flake.BeginAnimation(Canvas.TopProperty, fall);
        }

        private static bool IsInside(Point p, Canvas target) {
            return p.X >= 0 && p.Y >= 0 &&
                p.X <= target.ActualWidth && p.Y <= target.ActualHeight;
        }

        private void MouseMoved(object sender, MouseEventArgs e) {
            if (detached || window.WindowState == WindowState.Minimized) return;
            Point p = e.GetPosition(sparks);
            if (!IsInside(p, sparks)) return;
            DateTime now = DateTime.UtcNow;
            if ((now - lastTrail).TotalMilliseconds < 34) return;
            double dx = p.X - previous.X, dy = p.Y - previous.Y;
            if (dx * dx + dy * dy < 144) return;
            lastTrail = now; previous = p;
            Spawn(p.X + random.NextDouble() * 5 - 2.5,
                  p.Y + random.NextDouble() * 5 - 2.5,
                  7 + random.NextDouble() * 6, .38, random.NextDouble() * 7 - 3.5,
                  random.NextDouble() * 7 - 3.5, false);
        }

        private void MouseClicked(object sender, MouseButtonEventArgs e) {
            if (detached || window.WindowState == WindowState.Minimized) return;
            Point p = e.GetPosition(sparks);
            if (!IsInside(p, sparks)) return;
            for (int i = 0; i < 12; i++) {
                double angle = (i * Math.PI * 2.0 / 12) + random.NextDouble() * .33;
                double radius = 15 + random.NextDouble() * 37;
                Spawn(p.X, p.Y, 5 + random.NextDouble() * 10,
                    .46 + random.NextDouble() * .18,
                    Math.Cos(angle) * radius, Math.Sin(angle) * radius, true);
            }
        }

        private void MouseLeft(object sender, MouseEventArgs e) {
            previous = new Point(-100, -100);
        }

        private void Spawn(double x, double y, double size, double seconds,
                           double dx, double dy, bool burst) {
            if (detached) return;
            while (alive.Count >= MaxTransient) {
                var oldest = alive.First;
                alive.RemoveFirst();
                sparks.Children.Remove(oldest.Value);
            }
            var dot = new Ellipse();
            dot.Width = size; dot.Height = size;
            dot.IsHitTestVisible = false;
            dot.Opacity = burst ? .94 : .66;
            dot.Fill = Halo(burst ? RGBA(255, 153, 211, 250) :
                RGBA(238, 195, 246, 205));
            Canvas.SetLeft(dot, x - size / 2);
            Canvas.SetTop(dot, y - size / 2);
            sparks.Children.Add(dot);
            LinkedListNode<UIElement> node = alive.AddLast(dot);
            var fade = new DoubleAnimation {
                From = dot.Opacity, To = 0.0,
                Duration = TimeSpan.FromSeconds(seconds),
                FillBehavior = FillBehavior.Stop
            };
            fade.Completed += delegate(object sender, EventArgs args) {
                if (node.List != null) alive.Remove(node);
                sparks.Children.Remove(dot);
            };
            dot.BeginAnimation(UIElement.OpacityProperty, fade);
            dot.BeginAnimation(Canvas.LeftProperty, new DoubleAnimation {
                From = x - size / 2, To = x + dx - size / 2,
                Duration = TimeSpan.FromSeconds(seconds)
            });
            dot.BeginAnimation(Canvas.TopProperty, new DoubleAnimation {
                From = y - size / 2, To = y + dy - size / 2,
                Duration = TimeSpan.FromSeconds(seconds)
            });
        }

        private void Closed(object sender, EventArgs e) {
            detached = true;
            window.PreviewMouseMove -= MouseMoved;
            window.PreviewMouseLeftButtonDown -= MouseClicked;
            window.MouseLeave -= MouseLeft;
            window.Closed -= Closed;
            sky.Children.Clear();
            sparks.Children.Clear();
            alive.Clear();
        }
    }
}
