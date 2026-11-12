// Standalone native-icon host for the Multigravity WPF PowerShell interface.
// Built locally by install.ps1 using the .NET Framework C# compiler.
using System;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Windows.Forms;

namespace Multigravity
{
    internal static class GuiLauncher
    {
        [STAThread]
        private static int Main(string[] args)
        {
            string scriptPath = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory, "multigravity-gui.ps1");

            try
            {
                if (!File.Exists(scriptPath))
                    throw new FileNotFoundException("WPF profile manager script is missing.", scriptPath);

                using (Runspace runspace = RunspaceFactory.CreateRunspace())
                {
                    runspace.ApartmentState = System.Threading.ApartmentState.STA;
                    runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                    runspace.Open();

                    using (PowerShell shell = PowerShell.Create())
                    {
                        shell.Runspace = runspace;
                        shell.AddScript("& '" + scriptPath.Replace("'", "''") + "'");
                        shell.Invoke();

                        if (shell.HadErrors)
                        {
                            string errors = String.Join(Environment.NewLine,
                                shell.Streams.Error.Select(e => e.ToString()).ToArray());
                            throw new InvalidOperationException(errors);
                        }
                    }
                }
                return 0;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Multigravity startup error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
        }
    }
}
