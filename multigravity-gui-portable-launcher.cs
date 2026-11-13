// Single-file Windows launcher for the Multigravity WPF profile manager.
// The checked-in source files are embedded as resources at build time.
// Requires Windows PowerShell 5.1 and .NET Framework on the target machine.
using System;
using System.IO;
using System.Reflection;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security.Cryptography;
using System.Windows.Forms;
using System.Linq;

namespace Multigravity {
    internal static class PortableLauncher {
        private static readonly string[] Files = {
            "multigravity.ps1",
            "multigravity-gui.ps1",
            "multigravity-effects.cs",
            "multigravity-gui-icon.png",
            "multigravity-gui.ico"
        };

        // A separate per-user install directory keeps account/profile data elsewhere.
        private static readonly string UnpackDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Multigravity", "GlassSakuraPortable-v0.1.0");

        [STAThread]
        private static int Main(string[] args) {
            try {
                Directory.CreateDirectory(UnpackDirectory);
                Assembly assembly = Assembly.GetExecutingAssembly();
                foreach (string name in Files) {
                    ExtractFile(assembly, name);
                }
                string script = Path.Combine(UnpackDirectory, "multigravity-gui.ps1");
                using (Runspace runspace = RunspaceFactory.CreateRunspace()) {
                    runspace.ApartmentState = System.Threading.ApartmentState.STA;
                    runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                    runspace.Open();
                    using (PowerShell shell = PowerShell.Create()) {
                        shell.Runspace = runspace;
                        shell.AddScript("& '" + script.Replace("'", "''") + "'");
                        shell.Invoke();
                        if (shell.HadErrors) {
                            string errors = String.Join(Environment.NewLine,
                                shell.Streams.Error.Select(e => e.ToString()).ToArray());
                            throw new InvalidOperationException(errors);
                        }
                    }
                }
                return 0;
            } catch (Exception ex) {
                MessageBox.Show(ex.ToString(), "Multigravity Profile Manager",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
        }

        private static void ExtractFile(Assembly assembly, string name) {
            string resource = "Multigravity.Bundle." + name;
            byte[] bytes;
            using (Stream stream = assembly.GetManifestResourceStream(resource)) {
                if (stream == null)
                    throw new FileNotFoundException("Missing embedded resource", resource);
                using (MemoryStream buffer = new MemoryStream()) {
                    stream.CopyTo(buffer);
                    bytes = buffer.ToArray();
                }
            }
            string target = Path.Combine(UnpackDirectory, name);
            if (File.Exists(target) && SameBytes(File.ReadAllBytes(target), bytes))
                return;
            string temp = target + "." + Guid.NewGuid().ToString("N") + ".tmp";
            try {
                File.WriteAllBytes(temp, bytes);
                if (File.Exists(target)) {
                    // Atomic replacement prevents half-written scripts being loaded.
                    File.Replace(temp, target, null);
                } else {
                    File.Move(temp, target);
                }
            } finally {
                if (File.Exists(temp)) File.Delete(temp);
            }
        }
        private static bool SameBytes(byte[] a, byte[] b) {
            if (a.Length != b.Length) return false;
            using (SHA256 hash = SHA256.Create()) {
                return hash.ComputeHash(a).SequenceEqual(hash.ComputeHash(b));
            }
        }
    }
}
