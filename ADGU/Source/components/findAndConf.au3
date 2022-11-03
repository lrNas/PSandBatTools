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