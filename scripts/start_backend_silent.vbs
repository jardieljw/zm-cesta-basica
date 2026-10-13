Set fso = CreateObject("Scripting.FileSystemObject")
' Obtém a pasta onde este script .vbs está (a pasta scripts)
scriptsDir = fso.GetParentFolderName(WScript.ScriptFullName)
' Obtém a pasta raiz do projeto (um nível acima)
projectDir = fso.GetParentFolderName(scriptsDir)

Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = projectDir

' Executa o start_backend_server.bat de forma 100% invisível (parâmetro 0)
batPath = scriptsDir & "\start_backend_server.bat"
WshShell.Run chr(34) & batPath & chr(34), 0, False