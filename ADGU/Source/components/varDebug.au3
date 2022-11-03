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