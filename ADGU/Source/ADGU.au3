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

;Importa arquivos necessários
#include <components\imports.au3>
;Variavel global que define onde será o HKLM baseado na máquina que executa o programa.
Global $g_sHKLM64 = @AutoItX64 ? "HKEY_LOCAL_MACHINE" : "HKLM64"
;Carrega preset de configurações
$configs = configs()
;Inicializa o programa

;Checa se algum parâmetro foi inserido ao executar o comando
If ($CmdLine[0] > 0) Then
	;se foi, define como o primeiro parâmetro (não quero passar multiplos parâmetros nesse momento)
	$parameter = $CmdLine[1]
Else
	;Caso contrario, define como none.
	$parameter = "none"
EndIf
;Seria ideal fazer modos não verbosos sem o auxilio do conf.cf
Switch $parameter
	;Caso o parâmetro seja install
	Case "/install"
		installADGU($configs)
	;Caso o parâmetro seja uninstall
	Case "/uninstall"
		uninstallADGU()
	;Caso o parâmetro seja run
	Case "/run"
		runADGU($configs)
	;Caso o parâmetro seja config
	Case "/config"
		;busca o arquivo
		configureFromFile($configs)
		;configura o programa
		configureADGU($configs)
		;pede para rodar
		askForRun($configs,"Configuração AD Group Updater", "Programa configurado com sucesso")
	Case "/add"
		;Adiciona relação
		addRelation($configs)
		;Pede para rodar
		askForRun($configs,"Configuração AD Group Updater", "Programa configurado com sucesso")
	Case "none"
		;Procura se há chave de registro
		$reg = RegRead($g_sHKLM64 & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ADGroupUpdater")
		If ($reg == "") Then $reg = 0
		If (IsNumber($reg)) Then
			;Se não houver, instala o adgu
			installADGU($configs)
		Else
			;Se houver, executa o programa
			runADGU($configs)
		EndIf
EndSwitch
