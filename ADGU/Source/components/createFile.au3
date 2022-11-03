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