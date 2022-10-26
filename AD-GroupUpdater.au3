#include <File.au3>
;Diretório de instalação

Func createFile($path,$content)
_FileCreate($path)
Local $hFile=FileOpen($path,2+8)
FileWrite($hFile,$content)
FileClose($hFile)
EndFunc

$dir=InputBox("Local de destino","Digite aqui o local padrão de instalação","C:\Program Files\ADGU")
$span=InputBox("Tempo de intervalo","Digite a idade máxima da conta que vai ser atualizada na rotina","-1")
$depFile=InputBox("Departamentos X Grupos","Digite o local do arquivo CSV origem com a lista de grupos dos departamentos","c:\dep.csv")

;~ $dir=@TempDir&"\ADGU\"
;~ $span=-3
;~ $depFile=@ScriptDir&"\dep.csv"


Global Const $iPSfile=$dir&"\routine.ps1"
Global $exPSscript="$When = ((Get-Date).AddDays("&$span&")).Date"& @CRLF
$exPSscript&="$users = Get-ADUser -Filter {(whenCreated -ge $When) -and (objectClass -eq 'user')} -Properties department,SamAccountName"& @CRLF
$exPSscript&="$dep = Import-Csv -Path '"&$dir&"\dep.csv'"& @CRLF
$exPSscript&="@()"& @CRLF
$exPSscript&= "$users | ForEach-Object {"& @CRLF
$exPSscript&= "    $object = [pscustomobject]@{"& @CRLF
$exPSscript&= "        department = $_.department"& @CRLF
$exPSscript&= "        user = $_.SamAccountName"& @CRLF
$exPSscript&= "    }"& @CRLF
$exPSscript&= "    $dep |ForEach-Object{"& @CRLF
$exPSscript&= "        if($_.department -eq $object.department){"& @CRLF
$exPSscript&= "        Add-ADGroupMember $_.group $object.user"& @CRLF
$exPSscript&= "        }"& @CRLF
$exPSscript&= "    }"& @CRLF
$exPSscript&= "  }"& @CRLF
createFile($iPSfile,$exPSscript)

$trigger="$credential = $host.ui.PromptForCredential('AD User Groups Updater', 'Insira a credencial de Administrador AD para iniciar a rotina', '', 'domain')"
$trigger&=@CRLF&"Start-Process -WindowStyle hidden -FilePath '"&$dir&"\routine.ps1' -Credential $credential"
;inserir verificação se o usuário tem direito de editar o AD

Global Const $preRoutine=$dir&"\trigger.ps1"
createFile($preRoutine,$trigger)

;RegWrite("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run","AD Group Updater", "REG_SZ", $preRoutine)

;Copiar csv ou acessar em um lugar específico?
FileCopy($depFile,$dir) 

;Uninstaller
;editor de parâmetros
;scheduler
;editor de lista de diretórios
