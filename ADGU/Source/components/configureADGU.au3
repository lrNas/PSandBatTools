;Inicia a configuração geral do ADGU
Func configureADGU($configs)
	;Cria um form com o título Instalação / Configuração ADGU
	$Form1 = GUICreate("Instalação / Configuração ADGU", 394, 252, 192, 124)
	;Carrega as configurações atual para variáveis
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$depfile = DllStructGetData($configs, "depfile")
	$dir = DllStructGetData($configs, "dir")
	;Cria as labels do form
	$Label1 = GUICtrlCreateLabel("Dominio", 56, 32, 42, 17)
	$Label2 = GUICtrlCreateLabel("Username", 48, 64, 52, 17)
	$Label3 = GUICtrlCreateLabel("Senha", 56, 96, 35, 17)
	$Label4 = GUICtrlCreateLabel("DEP FILE", 48, 128, 51, 17)
	$Label5 = GUICtrlCreateLabel("Diretorio de instalação", 48, 155, 109, 17)
	$Label6 = GUICtrlCreateLabel("Periodo de dias", 48, 186, 109, 17)
	;Cria os inputs do form
	$Input1 = GUICtrlCreateInput($domain, 112, 24, 233, 21)
	$Input2 = GUICtrlCreateInput($username, 112, 56, 233, 21)
	$Input3 = GUICtrlCreateInput($password, 112, 88, 233, 21, $ES_AUTOHSCROLL + $ES_PASSWORD)
	$Input4 = GUICtrlCreateInput($depfile, 112, 120, 233, 21)
	$Input5 = GUICtrlCreateInput($dir, 176, 150, 169, 21)
	$Input6 = GUICtrlCreateInput($span, 176, 180, 169, 21)
	;Cria o botão OK do form
	$Button1 = GUICtrlCreateButton("Ok", 272, 210, 75, 25)
	;Exibe o form
	GUISetState(@SW_SHOW)
	;Define a variável Visualização
	$view = 1
	;Enquanto visualização for 1 (true) executa a rotina
	While $view
		;Pega a mensagem que a GUI passa
		$nMsg = GUIGetMsg()
		;Seleciona o caso
		Switch $nMsg
			;Se o caso for fechamento
			Case $GUI_EVENT_CLOSE
				;Adicionar painel: Tem certeza que quer cancelar
				Exit
			;Se a mensagem for ação do botão 1
			Case $Button1
				;Lê os campos de Input
				$dir = GUICtrlRead($Input5)
				$username = GUICtrlRead($Input2)
				$domain = GUICtrlRead($Input1)
				$password = GUICtrlRead($Input3)
				$depfile = GUICtrlRead($Input4)
				$span = Number(GUICtrlRead($Input6))
				;Configura o local do arquivo conf.cf
				$cfFile=$dir&"\conf.cf"
				;Define os dados conforme o que estava nos inputs
				DllStructSetData($configs, "span", $span)
				DllStructSetData($configs, "dir", $dir)
				DllStructSetData($configs, "username", $username)
				DllStructSetData($configs, "domain", $domain)
				DllStructSetData($configs, "cfFile", $cfFile)
				DllStructSetData($configs, "password", $password)
				DllStructSetData($configs, "depfile", $depfile)
				;Pega o local para a criação do conf.cf
				$cfFile = DllStructGetData($configs, "cfFile")
				;Cria um arquivo conf.cf novo, com os dados inseridos
				createCFFile($configs, $cfFile)
				;define a visão desse painel para 0 (fecha ele)
				$view = 0
		EndSwitch
	WEnd
EndFunc