;Configura a instancia do programa conforme o arquivo conf.cf
Func configureFromFile($configs, $cfFile= @ScriptDir & "\conf.cf")
	;Inicia a decriptação do arquivo, gerando um array de dados
	$novoArray = decryptCF($configs,$cfFile)
	;Varre o array de dados em busca das configurações necessárias
	findAndConf($configs, $novoArray)
EndFunc