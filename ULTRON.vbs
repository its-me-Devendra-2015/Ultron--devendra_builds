' Double-click to launch ULTRON with no console window (first run shows the installer window once).
Set s = CreateObject("WScript.Shell"): Set f = CreateObject("Scripting.FileSystemObject")
d = f.GetParentFolderName(WScript.ScriptFullName): s.CurrentDirectory = d
style = 0: If Not f.FolderExists(d & "\node_modules\electron") Then style = 1
s.Run "cmd /c start.bat", style, False
