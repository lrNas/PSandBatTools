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