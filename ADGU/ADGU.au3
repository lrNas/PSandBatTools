#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=ADGU.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Necessário possuir AD DS para utilizar a ferramenta
#AutoIt3Wrapper_Res_Description=Ferramenta de UPDATE para relações de grupos de usuários AD
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=ADGU
#AutoIt3Wrapper_Res_ProductVersion=1.0
#AutoIt3Wrapper_Res_CompanyName=Github  @Lrnas
#AutoIt3Wrapper_Res_LegalCopyright=Github  @Lrnas
#AutoIt3Wrapper_Res_LegalTradeMarks=Github  @Lrnas
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1046
#AutoIt3Wrapper_icon=shell32_42.ico
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Add_Constants=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Date.au3>
#include <Crypt.au3>
#include <File.au3>
#include <Array.au3>
#include <Debug.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
Global $g_sHKLM64 = @AutoItX64 ? "HKEY_LOCAL_MACHINE" : "HKLM64"

Func createFile($path, $content)
	_FileCreate($path)
	Local $hFile = FileOpen($path, 2 + 8)
	FileWrite($hFile, $content)
	FileClose($hFile)
EndFunc

Func findAndConf($configs, $array, $name)
	$location = _ArraySearch($array, $name)
	;se array vazio, criar novo arquivo
	$item = $array[$location][1]
	DllStructSetData($configs, $name, $item)
EndFunc

Func decriptCF($configs, $cfFile)
	$file = FileOpen($cfFile, 0)
	While($file=-1)
		configureADGU($configs)
		$cfFile=DllStructGetData($configs, "cfFile")
		$file = FileOpen($cfFile, 0)
	WEnd

	$FileContent = FileRead($file)
	FileClose($file)
	$bit=DllStructGetData($configs, "bit")
	$decript = _Crypt_DecryptData($FileContent, $bit, $CALG_AES_256)
	$configs = BinaryToString($decript)
	$string = StringReplace($configs, '"', "")
	$itemArray = _ArrayFromString($string, ',', @CRLF)
	Return $itemArray
EndFunc

Func configureFromFile($configs, $cfFile= @ScriptDir & "\conf.cf")
	$novoArray = decriptCF($configs,$cfFile)
	findAndConf($configs, $novoArray, "span")
	findAndConf($configs, $novoArray, "dir")
	findAndConf($configs, $novoArray, "username")
	findAndConf($configs, $novoArray, "domain")
	findAndConf($configs, $novoArray, "password")
	findAndConf($configs, $novoArray, "depfile")
	findAndConf($configs, $novoArray, "cfFile")
EndFunc

Func runADGU($configs)
	$cfFile = @ScriptDir & "\conf.cf"
	configureFromFile($configs, $cfFile);
	$hidden = " -WindowStyle hidden "
	;$hidden = ""
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$depfile = DllStructGetData($configs, "depfile")
	$iPID = RunAsWait($username, $domain, $password, 2, "powershell.exe" & $hidden & " $When = ((Get-Date).AddDays(-" & $span & ")).Date;" & _
			"$users = Get-ADUser -Filter {(whenCreated -ge $When) -and (objectClass -eq 'user')} -Properties department,SamAccountName;" & _
			"$dep = Import-Csv -Path '" & $depfile & "';" & _
			"$objects=@();" & _
			"$users | ForEach-Object {$object = [pscustomobject]@{department = $_.department;" & _
			"user = $_.SamAccountName};$dep|ForEach-Object{if ($_.department -eq $object.department){Add-ADGroupMember $_.group $object.user}}}", @SystemDir, @SW_SHOW, $STDERR_MERGED)
EndFunc

Func callADGU($configs)
	$dir = DllStructGetData($configs, "dir")
	$path = $dir &"\" & @ScriptName
	$cfFile= $dir&"\config.cf"
	createCFFile($configs,$cfFile)
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	RunAs($username, $domain, $password, 2, $path)
EndFunc
Func createCFFile($configs, $cfFile)
	$dir = DllStructGetData($configs, "dir")
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$cfFile = DllStructGetData($configs, "cfFile")
	$bit = DllStructGetData($configs, "bit")
	$depfile = DllStructGetData($configs, "depfile")

	$content = '"span","' & $span & '"' & @CRLF & _
			'"dir","' & $dir & '"' & @CRLF & _
			'"username","' & $username & '"' & @CRLF & _
			'"domain","' & $domain & '"' & @CRLF & _
			'"password","' & $password & '"' & @CRLF & _
			'"cfFile","' & $cfFile & '"' & @CRLF & _
			'"depfile","' & $depfile & '"'
	$encripted = _Crypt_EncryptData($content, $bit, $CALG_AES_256)
	createFile($cfFile, $encripted)
EndFunc   ;==>createCFFile

Func askForRun($configs, $titleElse, $descriptionElse)
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	$iMsgBoxAnswer = MsgBox(292, "Executar AD Group Updater", "Deseja executar o AD Group Updater?")
	Select
		Case $iMsgBoxAnswer = 6 ;Yes
		Case $iMsgBoxAnswer = 7 ;No
	EndSelect
	If ($iMsgBoxAnswer == 6) Then
		callADGU($configs)
	Else
		MsgBox(48, $titleElse, $descriptionElse)
	EndIf
EndFunc

Func varDebug($configs)
	$dir = DllStructGetData($configs, "dir")
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$cfFile = DllStructGetData($configs, "cfFile")
	$bit = DllStructGetData($configs, "bit")
	$depfile = DllStructGetData($configs, "depfile")
	MsgBox(48, "VALOR DAS VARIAVEIS", "$dir = '" & $dir & "'" & @CRLF & _
		"$username = '" & DllStructGetData($configs, "username") & "'" & @CRLF & _
		"$password = '" & DllStructGetData($configs, "password") & "'" & @CRLF & _
		"$domain = '" & DllStructGetData($configs, "domain") & "'" & @CRLF & _
		"$span = '" & DllStructGetData($configs, "span") & "'" & @CRLF & _
		"$cfFile = '" & DllStructGetData($configs, "cfFile") & "'" & @CRLF & _
		"$depfile = '" & DllStructGetData($configs, "depfile") & "'")
EndFunc

Func installADGU($configs)
	configureFromFile($configs)
	$dir = DllStructGetData($configs, "dir")
	$depfile = DllStructGetData($configs, "depfile")
	FileCopy($depfile, $dir & "\dep.csv")
	$depfile = $dir & "\dep.csv"
	DllStructSetData($configs, "depfile",$depfile)
	$cfFile = DllStructGetData($configs, "cfFile")
	$script = @ScriptFullPath
	$destination = $dir&"\" &@ScriptName
	FileCopy($script, $destination)

	RegWrite($g_sHKLM64 & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ADGroupUpdater", "REG_SZ", $destination)
	;criar entrada de uninstall
	;Identificar erros na instalação

        ; Create a shortcut on the desktop to explorer.exe and set the hotkey combination Ctrl+Alt+T or in AutoIt ^!t to the shortcut.
        FileCreateShortcut($destination, @DesktopCommonDir&"\Desinstalar ADGU",$dir, "/uninstall", _
		"Desinstalar Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "31")
		FileCreateShortcut($destination, @DesktopCommonDir&"\ADGU",$dir, "", _
		"Executar atualização de grupos com o Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "41")
		FileCreateShortcut($destination, @DesktopCommonDir&"\Configurar ADGU",$dir, "/config", _
		"Configurar Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "71")
		FileCreateShortcut($destination, @DesktopCommonDir&"\Adicionar Relações ADGU",$dir, "/add", _
		"Adicionar relações na lista de update do Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "46")

	askForRun($configs,"Instalação AD Group Updater", "Programa instalado com sucesso")
EndFunc

Func uninstallADGU()
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	$iMsgBoxAnswer = MsgBox(292, "Desinstalar AD Group Updater", "Deseja realmente desisnstalar o AD Group Updater?")
	Select
		Case $iMsgBoxAnswer = 6 ;Yes
		Case $iMsgBoxAnswer = 7 ;No
	EndSelect

	If ($iMsgBoxAnswer == 6) Then
		FileDelete(@ScriptDir)
		DirRemove(@ScriptDir, 1)
		;Corrigir bugs de remoção
		FileDelete(@DesktopCommonDir&"\Desinstalar ADGU.ink")
		FileDelete(@DesktopCommonDir&"\ADGU.ink")
		FileDelete(@DesktopCommonDir&"\Adicionar Relações ADGU.ink")
		FileDelete(@DesktopCommonDir&"\Configurar ADGU.ink")
		RegDelete($g_sHKLM64 & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ADGroupUpdater")
		MsgBox(48, "Desinstalar AD Group Updater", "Programa desinstalado com sucesso")
		;Tratar erros
	EndIf
EndFunc

Func configureADGU($configs)
	$Form1 = GUICreate("Instalação / Configuração ADGU", 394, 252, 192, 124)
	$Label1 = GUICtrlCreateLabel("Dominio", 56, 32, 42, 17)
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$depfile = DllStructGetData($configs, "depfile")
	$dir = DllStructGetData($configs, "dir")
	$Input1 = GUICtrlCreateInput($domain, 112, 24, 233, 21)
	$Label2 = GUICtrlCreateLabel("Username", 48, 64, 52, 17)
	$Input2 = GUICtrlCreateInput($username, 112, 56, 233, 21)
	$Label3 = GUICtrlCreateLabel("Senha", 56, 96, 35, 17)
	$Input3 = GUICtrlCreateInput($password, 112, 88, 233, 21, $ES_AUTOHSCROLL + $ES_PASSWORD)
	$Label4 = GUICtrlCreateLabel("DEP FILE", 48, 128, 51, 17)
	$Input4 = GUICtrlCreateInput($depfile, 112, 120, 233, 21)
	$Label6 = GUICtrlCreateLabel("Periodo de dias", 48, 186, 109, 17)
	$Input6 = GUICtrlCreateInput($span, 176, 180, 169, 21)
	$Label5 = GUICtrlCreateLabel("Diretorio de instalação", 48, 155, 109, 17)
	$Input5 = GUICtrlCreateInput($dir, 176, 150, 169, 21)
	$Button1 = GUICtrlCreateButton("Ok", 272, 210, 75, 25)
	GUISetState(@SW_SHOW)
	$view = 1
	While $view
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				;Tem certeza que quer cancelar
				Exit
			Case $Button1
				$dir = GUICtrlRead($Input5)
				$username = GUICtrlRead($Input2)
				$domain = GUICtrlRead($Input1)
				$password = GUICtrlRead($Input3)
				$depfile = GUICtrlRead($Input4)
				$span = Number(GUICtrlRead($Input6))
				$cfFile=$dir&"\conf.cf"
				DllStructSetData($configs, "span", $span)
				DllStructSetData($configs, "dir", $dir)
				DllStructSetData($configs, "username", $username)
				DllStructSetData($configs, "domain", $domain)
				DllStructSetData($configs, "cfFile", $cfFile)
				DllStructSetData($configs, "password", $password)
				DllStructSetData($configs, "depfile", $depfile)
				$cfFile = DllStructGetData($configs, "cfFile")
				createCFFile($configs, $cfFile)
				$view = 0
		EndSwitch
	WEnd
EndFunc

Func addRelation($configs)
	$cfFile = @ScriptDir & "\conf.cf"
	configureFromFile($configs, $cfFile)
	$depfile = DllStructGetData($configs, "depfile")
	$Form1_1 = GUICreate("ADGU - Adicionar relação", 346, 195, 192, 124)
	$Label1 = GUICtrlCreateLabel("Departamento", 40, 16, 71, 17)
	$Input1 = GUICtrlCreateInput("", 120, 8, 177, 21)
	$Label2 = GUICtrlCreateLabel("Grupo", 40, 64, 33, 17)
	$Input2 = GUICtrlCreateInput("", 120, 56, 177, 21)
	$Button1 = GUICtrlCreateButton("Adicionar", 224, 144, 75, 25)
	$Label3 = GUICtrlCreateLabel("Arquivo", 40, 112, 40, 17)
	$Input3 = GUICtrlCreateInput($depfile, 120, 104, 177, 21)
	GUISetState(@SW_SHOW)
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				Exit
			Case $Button1
				$location = GUICtrlRead($Input3)
				$dep = GUICtrlRead($Input1)
				$group = GUICtrlRead($Input2)
				Local $file = FileOpen($location, 8 + 3)
				$result = FileWrite($file, @CRLF & '"' & $dep & '","' & $group & '"')
				FileClose($location)
				GUICtrlSetData($Input1, "")
				GUICtrlSetData($Input2, "")
				;Quando setor estiver vazio, dar um alerta de que todas pessoas serão adicionadas nesse grupo, deseja fazer isso?
				If ($result) Then
					MsgBox(64, "ADGU - Adicionar relação", "Relação adicionada")
				Else
					MsgBox(16, "ADGU - Adicionar relação", "Problema ao adicionar relação, tente novamente")
				EndIf
		EndSwitch
	WEnd
EndFunc



Local $estrutura ='struct;char bit[10];int span[3];char dir[128];char username[128];char domain[128];char password[128];char depfile[128];char cffile[128];endstruct'
$configs = DllStructCreate($estrutura)
DllStructSetData($configs, 'bit', "0x01249F")
DllStructSetData($configs, 'span', 3)
DllStructSetData($configs, 'dir', "C:\ADGU")
DllStructSetData($configs, 'username', "Administrator")
DllStructSetData($configs, 'domain', "house.dom")
DllStructSetData($configs, 'password', "P4ssw0rd.")
DllStructSetData($configs, 'depfile', @ScriptDir&"\dep.csv")
DllStructSetData($configs, 'cfFile', @ScriptDir&"\conf.cf")



If ($CmdLine[0] > 0) Then
	$parameter = $CmdLine[1]
Else
	$parameter = "none"
EndIf
;fazer modos não verbosos
Switch $parameter
	Case "/install"
		;Valores a ser apresentados ao executar (Face Values)
		installADGU($configs)
	Case "/uninstall"
		uninstallADGU()
	Case "/run"
		runADGU($configs)
	Case "/config"
		configureFromFile($configs)
		configureADGU($configs)
		askForRun($configs,"Configuração AD Group Updater", "Programa configurado com sucesso")
	Case "/add"
		addRelation($configs)
	Case "none"
		$reg = RegRead($g_sHKLM64 & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ADGroupUpdater")
		If ($reg == "") Then $reg = 0
		If (IsNumber($reg)) Then
			installADGU($configs)
		Else
			runADGU($configs)
		EndIf
EndSwitch
