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