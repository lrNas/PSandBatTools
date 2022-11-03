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