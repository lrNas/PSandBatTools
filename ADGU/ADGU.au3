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
;Variavel global que define onde será o HKLM baseado na máquina que executa o programa.
Global $g_sHKLM64 = @AutoItX64 ? "HKEY_LOCAL_MACHINE" : "HKLM64"

;Função que cria arquivos com conteúdo
Func createFile($path, $content)
	;Cria o arquivo no caminho especificado como parâmetro
	_FileCreate($path)
	;Abre o arquivo em modo Leitura e Escrita
	Local $hFile = FileOpen($path, 2 + 8)
	;Escreve o conteúdo passado em parâmetro
	FileWrite($hFile, $content)
	;Fecha o arquivo
	FileClose($hFile)
EndFunc

;Procura configurações dentro do array gerado pelo arquivo conf.cf
Func findAndConf($configs, $array)
	;Define um array com quais informações serão procuradas no array de dados passado como parâmetro
	$toFind= StringSplit('span,dir,username,domain,password,depfile,cfFile',',',2)
	;Itera cada item do array acima
	for $value in $toFind
		;Debug:
 		;MsgBox(0, '', 'Current = ' & $value)
		;Procura no array de dados o valor atual
		$location = _ArraySearch($array, $value)
		;Define uma variável com o valor encontrado
		;se a posição estiver como vazio, pula a etapa
		if(isnumber($location)) then
			$item = $array[$location][1]
			DllStructSetData($configs, $value, $item)
		EndIf
		;Seria ideal criar um novo arquivo de configurações se falhar nessa etapa.
	next	
EndFunc

;Decripta o arquivo conf.cf e retorna um array de dados
Func decriptCF($configs, $cfFile)
	;Abre o arquivo no caminho informado como parâmetro
	$file = FileOpen($cfFile, 0)
	;Enquanto o retorno for -1 (falha em abrir) executa a rotina abaixo
	While($file=-1)
		;Chama o método de configuração do ADGU
		configureADGU($configs)
		;Define a localização do arquivo de configuração gerado
		$cfFile=DllStructGetData($configs, "cfFile")
		;Abre o arquivo
		$file = FileOpen($cfFile, 0)
	WEnd
	
	;Lê o conteudo do arquivo conf.cf
	$FileContent = FileRead($file)
	;Fecha o mesmo
	FileClose($file)
	;Lê o bit de decriptação
	$bit=DllStructGetData($configs, "bit")
	;Decripta o conteúdo do arquivo
	$decript = _Crypt_DecryptData($FileContent, $bit, $CALG_AES_256)
	;Gera transforma o binário decriptografado em texto limpo
	$configs = BinaryToString($decript)
	;Remove caracteres que vão atrapalhar a converter em array
	$string = StringReplace($configs, '"', "")
	;Converte os dados em um array bidimensional
	$itemArray = _ArrayFromString($string, ',', @CRLF)
	;Retorna o Array
	Return $itemArray
EndFunc

;Configura a instancia do programa conforme o arquivo conf.cf
Func configureFromFile($configs, $cfFile= @ScriptDir & "\conf.cf")
	;Inicia a decriptação do arquivo, gerando um array de dados
	$novoArray = decriptCF($configs,$cfFile)
	;Varre o array de dados em busca das configurações necessárias
	findAndConf($configs, $novoArray)
EndFunc

;Executa a rotina principal do ADGU (Update de grupos)
Func runADGU($configs)
	;Define o local para o conf.cf
	$cfFile = @ScriptDir & "\conf.cf"
	;Configura a partir do arquivo especificado
	configureFromFile($configs, $cfFile);
	;Define a execução do powershell como silenciosa, desmarcar a segunda linha para ficar visível
	$hidden = " -WindowStyle hidden "
	;$hidden = ""
	;Carrega configurações para variáveis atuais
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$depfile = DllStructGetData($configs, "depfile")
	;Executa o Script Powershell que muda o grupo de todos os usuários que possuam o departamento
	;igual ao especificado no arquivo dep.csv, como o usuário configurado no arquivo.
	$iPID = RunAsWait($username, $domain, $password, 2, "powershell.exe" & $hidden & " $When = ((Get-Date).AddDays(-" & $span & ")).Date;" & _
			"$users = Get-ADUser -Filter {(whenCreated -ge $When) -and (objectClass -eq 'user')} -Properties department,SamAccountName;" & _
			"$dep = Import-Csv -Path '" & $depfile & "';" & _
			"$objects=@();" & _
			"$users | ForEach-Object {$object = [pscustomobject]@{department = $_.department;" & _
			"user = $_.SamAccountName};$dep|ForEach-Object{if ($_.department -eq $object.department){Add-ADGroupMember $_.group $object.user}}}", @SystemDir, @SW_SHOW, $STDERR_MERGED)
EndFunc

;Chama a execução do ADGU instalado.
Func callADGU($configs)
	;Define o diretório de instalação conforme configuração atual
	$dir = DllStructGetData($configs, "dir")
	;Define o caminho para o executável
	$path = $dir &"\" & @ScriptName
	;Define o novo caminho do arquivo de configuração
	$cfFile= $dir&"\config.cf"
	;Cria o novo arquivo de configuração
	createCFFile($configs,$cfFile)
	;Pega as informações de credenciais necessárias para iniciar o programa
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	;Roda como o usuário salvo
	RunAs($username, $domain, $password, 2, $path)
EndFunc

;Cria o arquivo conf.cf
Func createCFFile($configs, $cfFile)
	;Define as variáveis conforme a estrutura de dados passada como parâmetro
	$dir = DllStructGetData($configs, "dir")
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$cfFile = DllStructGetData($configs, "cfFile")
	$bit = DllStructGetData($configs, "bit")
	$depfile = DllStructGetData($configs, "depfile")
	;Gera uma string que será criptografada com esses dados
	$content = '"span","' & $span & '"' & @CRLF & _
			'"dir","' & $dir & '"' & @CRLF & _
			'"username","' & $username & '"' & @CRLF & _
			'"domain","' & $domain & '"' & @CRLF & _
			'"password","' & $password & '"' & @CRLF & _
			'"cfFile","' & $cfFile & '"' & @CRLF & _
			'"depfile","' & $depfile & '"'
	;Encripta o conteudo da string anterior 
	$encripted = _Crypt_EncryptData($content, $bit, $CALG_AES_256)
	;Salva um arquivo com o conteúdo daquela string
	createFile($cfFile, $encripted)
EndFunc

;Pergunta se vai querer executar o programa
Func askForRun($configs, $titleElse, $descriptionElse)
	;Verifica se já tem messagebox criada, e cria se não tiver
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	;Chama uma message box perguntando se vai executar
	$iMsgBoxAnswer = MsgBox(292, "Executar AD Group Updater", "Deseja executar o AD Group Updater?")
	;Seleciona a resposta
	Select
	;caso sim
		Case $iMsgBoxAnswer = 6
		;Chama o adgu
			callADGU($configs)
		;Caso não
		Case $iMsgBoxAnswer = 7
		;Chama uma caixa, com o titulo e descrição fornecidos como parâmetro à função
			MsgBox(48, $titleElse, $descriptionElse)
	EndSelect
EndFunc

;Debuga a variável config
Func varDebug($configs)
	;Carrega todos os itens
	$dir = DllStructGetData($configs, "dir")
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$cfFile = DllStructGetData($configs, "cfFile")
	$bit = DllStructGetData($configs, "bit")
	$depfile = DllStructGetData($configs, "depfile")
	;Chama uma janela com o conteúdo de todos os itens
	MsgBox(48, "VALOR DAS VARIAVEIS", "$dir = '" & $dir & "'" & @CRLF & _
		"$username = '" & DllStructGetData($configs, "username") & "'" & @CRLF & _
		"$password = '" & DllStructGetData($configs, "password") & "'" & @CRLF & _
		"$domain = '" & DllStructGetData($configs, "domain") & "'" & @CRLF & _
		"$span = '" & DllStructGetData($configs, "span") & "'" & @CRLF & _
		"$cfFile = '" & DllStructGetData($configs, "cfFile") & "'" & @CRLF & _
		"$depfile = '" & DllStructGetData($configs, "depfile") & "'")
EndFunc

;Instala o ADGU
Func installADGU($configs)
	;Puxa configurações de um arquivo (como se fosse uma intalação silenciosa, usando o conf.cf de outra instalação)
	configureFromFile($configs)
	;Pega parâmetros da estrutura de dados atual
	$dir = DllStructGetData($configs, "dir")
	$depfile = DllStructGetData($configs, "depfile")
	;copia o dep.csv para o diretório de instalação
	FileCopy($depfile, $dir & "\dep.csv")
	;Muda o path do dep.csv para o que foi copiado
	$depfile = $dir & "\dep.csv"
	;Define a nova localização na variável de configuração
	DllStructSetData($configs, "depfile",$depfile)
	;lê onde está o conf.cf
	$cfFile = DllStructGetData($configs, "cfFile")
	;Caminho para o script atual
	$script = @ScriptFullPath
	;caminho para a pasta de instalação + nome do arquivo
	$destination = $dir&"\" &@ScriptName
	;Copia o arquivo do executavel para a pasta de instalação destino.
	FileCopy($script, $destination)
	;Cria registro no windows para executar o adgu toda vez que reiniciar
	RegWrite($g_sHKLM64 & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ADGroupUpdater", "REG_SZ", $destination)
	;Necessário criar entrada de uninstall
	;Necessário identificar erros na instalação

	;Cria atalhos no desktop
	FileCreateShortcut($destination, @DesktopCommonDir&"\Desinstalar ADGU",$dir, "/uninstall", _
	"Desinstalar Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "31")
	FileCreateShortcut($destination, @DesktopCommonDir&"\ADGU",$dir, "", _
	"Executar atualização de grupos com o Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "41")
	FileCreateShortcut($destination, @DesktopCommonDir&"\Configurar ADGU",$dir, "/config", _
	"Configurar Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "71")
	FileCreateShortcut($destination, @DesktopCommonDir&"\Adicionar Relações ADGU",$dir, "/add", _
	"Adicionar relações na lista de update do Active Directory Group Updater", @SystemDir & "\shell32.dll", "", "46")
	;Pergunta se quer executar.
	askForRun($configs,"Instalação AD Group Updater", "Programa instalado com sucesso")
EndFunc

;Desinstala ADGU
Func uninstallADGU()
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	$iMsgBoxAnswer = MsgBox(292, "Desinstalar AD Group Updater", "Deseja realmente desisnstalar o AD Group Updater?")
	If ($iMsgBoxAnswer == 6) Then
		;Deleta arquivos na pasta
		FileDelete(@ScriptDir)
		;Deleta o diretorio, recursivamente
		DirRemove(@ScriptDir, 1)
		;Remove os links criados no desktop
		FileDelete(@DesktopCommonDir&"\Desinstalar ADGU.lnk")
		FileDelete(@DesktopCommonDir&"\ADGU.lnk")
		FileDelete(@DesktopCommonDir&"\Adicionar Relações ADGU.lnk")
		FileDelete(@DesktopCommonDir&"\Configurar ADGU.lnk")
		;Remove o registro do programa
		RegDelete($g_sHKLM64 & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ADGroupUpdater")
		;Mensagem de deleção com sucesso
		MsgBox(48, "Desinstalar AD Group Updater", "Programa desinstalado com sucesso")
		;Tratar erros!
	EndIf
EndFunc

;Inicia a configuração geral do ADGU
Func configureADGU($configs)
	;Cria um form com o título Instalação / Configuração ADGU
	$Form1 = GUICreate("Instalação / Configuração ADGU", 394, 252, 192, 124)
	;Carrega as configurações atual para variáveis
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$depfile = DllStructGetData($configs, "depfile")
	$dir = DllStructGetData($configs, "dir")
	;Cria as labels do form
	$Label1 = GUICtrlCreateLabel("Dominio", 56, 32, 42, 17)
	$Label2 = GUICtrlCreateLabel("Username", 48, 64, 52, 17)
	$Label3 = GUICtrlCreateLabel("Senha", 56, 96, 35, 17)
	$Label4 = GUICtrlCreateLabel("DEP FILE", 48, 128, 51, 17)
	$Label5 = GUICtrlCreateLabel("Diretorio de instalação", 48, 155, 109, 17)
	$Label6 = GUICtrlCreateLabel("Periodo de dias", 48, 186, 109, 17)
	;Cria os inputs do form
	$Input1 = GUICtrlCreateInput($domain, 112, 24, 233, 21)
	$Input2 = GUICtrlCreateInput($username, 112, 56, 233, 21)
	$Input3 = GUICtrlCreateInput($password, 112, 88, 233, 21, $ES_AUTOHSCROLL + $ES_PASSWORD)
	$Input4 = GUICtrlCreateInput($depfile, 112, 120, 233, 21)
	$Input5 = GUICtrlCreateInput($dir, 176, 150, 169, 21)
	$Input6 = GUICtrlCreateInput($span, 176, 180, 169, 21)
	;Cria o botão OK do form
	$Button1 = GUICtrlCreateButton("Ok", 272, 210, 75, 25)
	;Exibe o form
	GUISetState(@SW_SHOW)
	;Define a variável Visualização
	$view = 1
	;Enquanto visualização for 1 (true) executa a rotina
	While $view
		;Pega a mensagem que a GUI passa
		$nMsg = GUIGetMsg()
		;Seleciona o caso
		Switch $nMsg
			;Se o caso for fechamento
			Case $GUI_EVENT_CLOSE
				;Adicionar painel: Tem certeza que quer cancelar
				Exit
			;Se a mensagem for ação do botão 1
			Case $Button1
				;Lê os campos de Input
				$dir = GUICtrlRead($Input5)
				$username = GUICtrlRead($Input2)
				$domain = GUICtrlRead($Input1)
				$password = GUICtrlRead($Input3)
				$depfile = GUICtrlRead($Input4)
				$span = Number(GUICtrlRead($Input6))
				;Configura o local do arquivo conf.cf
				$cfFile=$dir&"\conf.cf"
				;Define os dados conforme o que estava nos inputs
				DllStructSetData($configs, "span", $span)
				DllStructSetData($configs, "dir", $dir)
				DllStructSetData($configs, "username", $username)
				DllStructSetData($configs, "domain", $domain)
				DllStructSetData($configs, "cfFile", $cfFile)
				DllStructSetData($configs, "password", $password)
				DllStructSetData($configs, "depfile", $depfile)
				;Pega o local para a criação do conf.cf
				$cfFile = DllStructGetData($configs, "cfFile")
				;Cria um arquivo conf.cf novo, com os dados inseridos
				createCFFile($configs, $cfFile)
				;define a visão desse painel para 0 (fecha ele)
				$view = 0
		EndSwitch
	WEnd
EndFunc

;Rotina para adicionar relacionamentos de grupos por departamento
Func addRelation($configs)
	;Local do conf.cf
	$cfFile = @ScriptDir & "\conf.cf"
	;Configura a partir do arquivo conf.cf
	configureFromFile($configs, $cfFile)
	;Carrega o dep.csv com a lista de relações atuais
	$depfile = DllStructGetData($configs, "depfile")
	;Cria um form
	$Form1_1 = GUICreate("ADGU - Adicionar relação", 346, 195, 192, 124)
	;Cria a Label dos inputs
	$Label1 = GUICtrlCreateLabel("Departamento", 40, 16, 71, 17)
	$Label2 = GUICtrlCreateLabel("Grupo", 40, 64, 33, 17)
	$Label3 = GUICtrlCreateLabel("Arquivo", 40, 112, 40, 17)
	;Cria os inputs do form
	$Input1 = GUICtrlCreateInput("", 120, 8, 177, 21)
	$Input2 = GUICtrlCreateInput("", 120, 56, 177, 21)
	$Input3 = GUICtrlCreateInput($depfile, 120, 104, 177, 21)
	;Cria o botão adicionar
	$Button1 = GUICtrlCreateButton("Adicionar", 224, 144, 75, 25)
	;Exibe a gui
	GUISetState(@SW_SHOW)
	;Executa a rotina até que você feche a tela
	$show = 1
	While $show
		;Pega a mensagem da GUI
		$nMsg = GUIGetMsg()
		;Seleciona a resposta
		Switch $nMsg
			;fecha o arquivo ao clicar no x
			Case $GUI_EVENT_CLOSE
				$show=0
			;Se a resposta for botão 1, realiza a rotina
			Case $Button1
				;Pega o local do arquivo conforme no input 3
				$location = GUICtrlRead($Input3)
				;Pega as informações sobre a relação (Grupo e departamento)
				$dep = GUICtrlRead($Input1)
				$group = GUICtrlRead($Input2)
				;Abre o dep.csv
				Local $file = FileOpen($location, 8 + 3)
				;Escreve a linha da relação no CSV, e se tiver sucesso, grava em result
				$result = FileWrite($file, @CRLF & '"' & $dep & '","' & $group & '"')
				;Fecha o arquivo
				FileClose($location)
				;Apaga as informações do input
				GUICtrlSetData($Input1, "")
				GUICtrlSetData($Input2, "")
				;Seria ideal adicionar um filtro e quando setor estiver vazio, dar um alerta de que todas pessoas serão adicionadas nesse grupo, deseja fazer isso?
				;Se result for true, manda mensagem de que foi adicionado.
				If ($result) Then
					MsgBox(64, "ADGU - Adicionar relação", "Relação adicionada")
				Else
					MsgBox(16, "ADGU - Adicionar relação", "Problema ao adicionar relação, tente novamente")
				EndIf
		EndSwitch
	WEnd
EndFunc

;Inicializa o programa
;Cria estrutura de dados que será usada para configuração de dados
Local $estrutura ='struct;char bit[10];int span[3];char dir[128];char username[128];char domain[128];char password[128];char depfile[128];char cffile[128];endstruct'
$configs = DllStructCreate($estrutura)
;Dados pré-carregados para facilitar teste. Os com ; no final podem ser esvaziados
DllStructSetData($configs, 'bit', "0x01249F")
DllStructSetData($configs, 'span', 3);
DllStructSetData($configs, 'dir', "C:\ADGU");
DllStructSetData($configs, 'username', "Administrator");
DllStructSetData($configs, 'domain', "house.dom");
DllStructSetData($configs, 'password', "P4ssw0rd.");
DllStructSetData($configs, 'depfile', @ScriptDir&"\dep.csv");
DllStructSetData($configs, 'cfFile', @ScriptDir&"\conf.cf")


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
