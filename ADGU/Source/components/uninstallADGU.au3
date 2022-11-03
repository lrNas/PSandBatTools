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