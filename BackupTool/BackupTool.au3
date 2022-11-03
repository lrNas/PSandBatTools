#include <File.au3>
#include <Crypt.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GuiConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <ProgressConstants.au3>


;Define onde os arquivos tempor�rios ser�o criados
$temp=@TempDir&"\bck\"

;Fun��o que compacta arquivos utilizando o 7z
Func _7z($Aorigem, $Adestino, $show = @SW_HIDE, $CompLvl = 9)
	;Armazena numa vari�vel o local onde fica armazenado o 7z.exe
	Local $7za_exe =  StringRegExpReplace(@ProgramFilesDir & "\"," \(x86\)","")&"7-Zip\7z.exe"

	;Define o comando que vai ser executado no 7z
	Local $statement = ' a ' & $Adestino & 'bck.7z ' & $Aorigem & ' -mx' & $CompLvl & ' -v150m'

	;chama a execu��o do 7z
	Local $return7za = ShellExecuteWait($7za_exe, $statement, '', $SHEX_OPEN, $show)

	;checa se o processo teve erros e devolve o resultado
	Select
		Case $return7za = 0
			Return 0
		Case Else
			Return SetError(1, $return7za, 0)
	EndSelect
EndFunc

;Fun��o que compara o checksum de arquivos para garantir a integridade da c�pia
Func revChecksum($pathOr,$pathDest)
	;Cria hash do arquivo de origem
    Local $hashOrigem = _Crypt_HashFile($pathOr,$CALG_SHA_256)
	;Cria hash do arquivo de destino
    Local $hashDestino = _Crypt_HashFile($pathDest,$CALG_SHA_256)
	;retorna se os hashs s�o diferentes
    Return $hashOrigem <> $hashDestino
EndFunc

;Fun��o que atualiza a barra de progresso
Func updateBar($item,$iterator,$totalItems)
	;calcula a percentagem conforme a quantidade de arquivos j� copiados
	$Percent = Round($iterator*(100/$totalItems),1)
	;define a barra de porcentagem
    GUICtrlSetData($item,$Percent)
	;atualiza a visualiza��o
	GUISetState(@SW_SHOW)
EndFunc

;Fun��o que realiza a transfer�ncia de arquivo entre uma m�quina e outra
Func transfer($origem,$hostDestino,$userDest,$adm,$senha)
	;cria a tela de transfer�ncia com barra de progresso
	$Form1 = GUICreate("Transferindo ...", 402, 119, 192, 124)
	$Progress1 = GUICtrlCreateProgress(32, 32, 342, 25)

	;armazena a string do local para onde o arquivo ser� copiado
    Local $remote =  "\\" & $hostDestino & "\c$"

	;mapeia o drive, utilizando usu�rio e senha que foram fornecidos
	DriveMapAdd("n:",$remote,0, $adm, $senha)

	;Cria iterador para mapear arquivos
	Local $iterator=0

	;Busca a lista de todos os arquivos, com contagem no array 0
    Local $fileArray = _FileListToArray($origem)

	;Armazena a contagem de todos os arquivos
	Local $totalItems=$fileArray[0]

	;calcula a percentagem atual e exibe na barra
	updateBar($Progress1,$iterator,$totalItems)

	;cria a pasta destino
	DirCreate("n:\users\"&$userDest&"\bck\")
	;Itera todos arquivos, ignorando o item na posi��o 0, que � a soma
    For $item In $fileArray
        If $iterator <>0 Then
			;Define o nome do arquivo destino, com base no de origem
            Local $destinoRemoto = "n:\users\"&$userDest&"\bck\"&$item
			;Define o local onde o arquivo deve ser buscado para c�pia
            Local $origemLocal = $temp&$item
			;realiza a compara��o reversa de checksumc at� que esteja correto
            while (revChecksum($origemLocal,$destinoRemoto))
				;Se o arquivo for diferente, deleta e inicia a c�pia de novo
                FileDelete($destinoRemoto)
                FileCopy($origemLocal,$destinoRemoto)
			WEnd
		EndIf
		$iterator+=1
		;calcula a percentagem atual e exibe na barra
		updateBar($Progress1,$iterator,$totalItems)
    Next

	;cria um arquivo bat para extrair tudo e excluir arquivos usados
	Local $file = fileopen ("n:\users\"&$userDest&"\bck\extract.bat" ,1)
    FileWriteLine ($file , "cd C:\Program Files\7-Zip")
	FileWriteLine ($file , "7z x C:\users\"&$userDest&"\bck\bck.7z.001 -oc:\users\ -aoa")
	FileWriteLine ($file , "rmdir /s /q C:\users\"&$userDest&"\bck\")
    fileclose($file)

	;"desmapeia" drive mapeado para a transfer�ncia
	DriveMapDel("n:")
	;exclui arquivos tempor�rios
	DirRemove($temp)
	;Fecha a janela de transferindo e cria uma mensagem de sucesso
	If WinExists("Transferindo ...") = 1 Then GUIDelete($Form1)
	MsgBox(64,"Copia finalizada","Transfer�ncia finalizada com sucesso!")
EndFunc

;Fun��o que inicia o fluxo do processo
Func  start($origem,$hostnDestino,$userDest,$adm,$senha)
	;Remove a pasta que o programa usa para fazer backup, para evitar conflitos
	DirRemove($temp,1)

	;Inicia o m�todo que utiliza o 7z para fazer compress�o
	$retResult = _7z($origem, $temp,@SW_SHOW)

	;Em caso de erro, interrompe o processo
    If $retResult <> 0 Then
		MsgBox(64, "Erro:", $retResult)
		Exit
	EndIf
	;Passando do erro, chama o m�todo de transfer�ncia
	transfer($temp,$hostnDestino,$userDest,$adm,$senha)
EndFunc

;Fun��o que filtra usu�rios excluidos
Func filter($users,$excluded)
	;itera todos os excluidos
	for $item in $excluded
		;busca o index do excluido na o array de users
		Local $index = _ArraySearch($users,$item)
		;remove do array
		_ArrayDelete($users,$index)
	Next
	;devolve o array filtrado
	return $users
EndFunc

;Fun��o que apresenta a primeira janela
Func drawStartForm()
	;Cria o container principal de janela
	$Form1 = GUICreate("BckTool", 247, 270, 322, 165)
	;Puxa alista de usu�rios em C:\Users. O array 0 cont�m a quantidade de usu�rios nessa pasta.
	Local $users = _FileListToArray("c:\users\","*",2)
	$Combo1=""
	;Filtra usu�rios que n�o devem ser exibidos
	Local $excluded[6] = ["All Users","Default User","Default","Public","Todos os Usu�rios","Usu�rio Padr�o"]
	Local $userFiltrado = filter($users,$excluded)
	;Vari�veis para o combobox
	Local $comboInformation = ""
	Local $iterator =0
	;La�o de cria��o de entradas para o combobox
	For $item In $userFiltrado
		;Descarta o array 0, que contem a quantidade e filtra os usu�rios
        If $iterator <>0 Then
				if $iterator <>1 Then
					;Se estiver em outro nome de usu�rio, coloca na lista de op��es do combobox
					$comboInformation&=$item&"|"
				else
					;Se estiver no primeiro nome de usu�rio, coloca como a op��o selecionada no combobox
					$Combo1 = GUICtrlCreateCombo($item, 80, 24, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))

				EndIf
        EndIf
		;Adiciona 1 para que o iterador possa executar a contagem
		$iterator+=1
	Next

	;remove um | que � adicionado automaticamente
	$iLength = StringLen($comboInformation)
	$comboInformation = StringLeft($comboInformation,($iLength -1))

	;adiciona os nomes de usu�rio � lista do combobox
	GUICtrlSetData(-1, $comboInformation)

	;cria as labels
	$Label1 = GUICtrlCreateLabel("Usu�rio", 24, 24, 51, 20)
	$Label2 = GUICtrlCreateLabel("Hostname", 24, 72, 66, 20)
	$Label3 = GUICtrlCreateLabel("Administrador", 24, 120, 66, 20)
	$Label2 = GUICtrlCreateLabel("Senha", 24, 168, 66, 20)
	GUICtrlSetFont(-1, 10, 400, 0, "MS Sans Serif")

	;cria os inputs de texto
	$Input1 = GUICtrlCreateInput("", 96, 72, 129, 21)
	$Input2 = GUICtrlCreateInput("", 96, 120, 129, 21)
	$Input3 = GUICtrlCreateInput("", 96, 168, 129, 21,$ES_PASSWORD)

	;cria um bot�o para iniciar
	$Button1 = GUICtrlCreateButton("Transferir", 152, 236, 75, 25)

	;manda exibir os elementos gr�ficos
	GUISetState(@SW_SHOW)

	;Inicia um loop infinito que verifica mensagens de bot�es
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			;Caso a mensagem seja do bot�o de fechar
			Case $GUI_EVENT_CLOSE
				Exit
			;Caso a mensagem seja do bot�o 1 (Transferir)
			Case $Button1
				;Pega o n�mero de sele��o do combobox
				Local $usern = _GUICtrlComboBox_GetCurSel($Combo1)+1
				;Pega todas as op��es do combobox
				Local $options = _GUICtrlComboBox_GetListArray($Combo1)
				;Pega entre as op��es, a op��o do n�mero $usern para obter o valor string
				Local $userDest = $options[$usern]
				;Define a pasta de origem com base no usu�rio selecionado
				Local $origem = "c:\users\"&$userDest
				;L� o host de destino, nome do adm e senha para mapear drivers
				Local $hostDestino = GUICtrlRead($Input1)
				Local $adm = GUICtrlRead($Input2)
				Local $senha = GUICtrlRead($Input3)

				;Fecha a janela para chamar a pr�xima
				If WinExists("BckTool") = 1 Then GUIDelete($Form1)
				;Inicia o processo de compress�o e envio, vide m�todo
				start($origem,$hostDestino,$userDest,$adm,$senha)
				;Encerra o programa
				Exit
		EndSwitch
	WEnd
EndFunc

;CHAMADA DO FLUXO:
drawStartForm()