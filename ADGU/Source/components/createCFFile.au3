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