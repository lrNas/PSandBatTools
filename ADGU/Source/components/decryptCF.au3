;Decripta o arquivo conf.cf e retorna um array de dados
Func decryptCF($configs, $cfFile)
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
