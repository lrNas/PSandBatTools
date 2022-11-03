;Rotina para adicionar relacionamentos de grupos por departamento
Func addRelation($configs)
	;Local do conf.cf
	$cfFile = @ScriptDir & "\conf.cf"
	;Configura a partir do arquivo conf.cf
	configureFromFile($configs, $cfFile)
	;Carrega o dep.csv com a lista de relações atuais
	$depfile = DllStructGetData($configs, "depfile")
	;Cria um form
	$Form1_1 = GUICreate("ADGU - Adicionar relação", 346, 195, 192, 124)
	;Cria a Label dos inputs
	$Label1 = GUICtrlCreateLabel("Departamento", 40, 16, 71, 17)
	$Label2 = GUICtrlCreateLabel("Grupo", 40, 64, 33, 17)
	$Label3 = GUICtrlCreateLabel("Arquivo", 40, 112, 40, 17)
	;Cria os inputs do form
	$Input1 = GUICtrlCreateInput("", 120, 8, 177, 21)
	$Input2 = GUICtrlCreateInput("", 120, 56, 177, 21)
	$Input3 = GUICtrlCreateInput($depfile, 120, 104, 177, 21)
	;Cria o botão adicionar
	$Button1 = GUICtrlCreateButton("Adicionar", 224, 144, 75, 25)
	;Exibe a gui
	GUISetState(@SW_SHOW)
	;Executa a rotina até que você feche a tela
	$show = 1
	While $show
		;Pega a mensagem da GUI
		$nMsg = GUIGetMsg()
		;Seleciona a resposta
		Switch $nMsg
			;fecha o arquivo ao clicar no x
			Case $GUI_EVENT_CLOSE
				$show=0
			;Se a resposta for botão 1, realiza a rotina
			Case $Button1
				;Pega o local do arquivo conforme no input 3
				$location = GUICtrlRead($Input3)
				;Pega as informações sobre a relação (Grupo e departamento)
				$dep = GUICtrlRead($Input1)
				$group = GUICtrlRead($Input2)
				;Abre o dep.csv
				Local $file = FileOpen($location, 8 + 3)
				;Escreve a linha da relação no CSV, e se tiver sucesso, grava em result
				$result = FileWrite($file, @CRLF & '"' & $dep & '","' & $group & '"')
				;Fecha o arquivo
				FileClose($location)
				;Apaga as informações do input
				GUICtrlSetData($Input1, "")
				GUICtrlSetData($Input2, "")
				;Seria ideal adicionar um filtro e quando setor estiver vazio, dar um alerta de que todas pessoas serão adicionadas nesse grupo, deseja fazer isso?
				;Se result for true, manda mensagem de que foi adicionado.
				If ($result) Then
					MsgBox(64, "ADGU - Adicionar relação", "Relação adicionada")
				Else
					MsgBox(16, "ADGU - Adicionar relação", "Problema ao adicionar relação, tente novamente")
				EndIf
		EndSwitch
	WEnd
EndFunc