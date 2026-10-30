' Inicia o Agente de Impressão sem abrir nenhuma janela.
' Usado tanto para rodar manualmente (duplo clique) quanto pela inicialização automática do Windows.
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
strPastaAtual = objFSO.GetParentFolderName(WScript.ScriptFullName)
objShell.CurrentDirectory = strPastaAtual
' Garante que o node.exe seja encontrado mesmo se o PATH do processo que chamou este
' script estiver desatualizado (comum logo após instalar o Node.js).
objShell.Run "cmd /c set ""PATH=%PATH%;C:\Program Files\nodejs"" && node dist\index.js", 0, False
