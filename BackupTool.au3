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


;Define onde os arquivos temporários serão criados
$temp=@TempDir&"\bck\"

;Função que compacta arquivos utilizando o 7z
Func _7z($Aorigem, $Adestino, $show = @SW_HIDE, $CompLvl = 9)
	;Armazena numa variável o local onde fica armazenado o 7z.exe
	Local $7za_exe =  StringRegExpReplace(@ProgramFilesDir & "\"," \(x86\)","")&"7-Zip\7z.exe"

	;Define o comando que vai ser executado no 7z
	Local $statement = ' a ' & $Adestino & 'bck.7z ' & $Aorigem & ' -mx' & $CompLvl & ' -v150m'

	;chama a execução do 7z
	Local $return7za = ShellExecuteWait($7za_exe, $statement, '', $SHEX_OPEN, $show)

	;checa se o processo teve erros e devolve o resultado
	Select
		Case $return7za = 0
			Return 0
		Case Else
			Return SetError(1, $return7za, 0)
	EndSelect
EndFunc

;Função que compara o checksum de arquivos para garantir a integridade da cópia
Func revChecksum($pathOr,$pathDest)
	;Cria hash do arquivo de origem
    Local $hashOrigem = _Crypt_HashFile($pathOr,$CALG_SHA_256)
	;Cria hash do arquivo de destino
    Local $hashDestino = _Crypt_HashFile($pathDest,$CALG_SHA_256)
	;retorna se os hashs são diferentes
    Return $hashOrigem <> $hashDestino
EndFunc

;Função que atualiza a barra de progresso
Func updateBar($item,$iterator,$totalItems)
	;calcula a percentagem conforme a quantidade de arquivos já copiados
	$Percent = Round($iterator*(100/$totalItems),1)
	;define a barra de porcentagem
    GUICtrlSetData($item,$Percent)
	;atualiza a visualização
	GUISetState(@SW_SHOW)
EndFunc

;Função que realiza a transferência de arquivo entre uma máquina e outra
Func transfer($origem,$hostDestino,$userDest,$adm,$senha)
	;cria a tela de transferência com barra de progresso
	$Form1 = GUICreate("Transferindo ...", 402, 119, 192, 124)
	$Progress1 = GUICtrlCreateProgress(32, 32, 342, 25)

	;armazena a string do local para onde o arquivo será copiado
    Local $remote =  "\\" & $hostDestino & "\c$"

	;mapeia o drive, utilizando usuário e senha que foram fornecidos
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
	;Itera todos arquivos, ignorando o item na posição 0, que é a soma
    For $item In $fileArray
        If $iterator <>0 Then
			;Define o nome do arquivo destino, com base no de origem
            Local $destinoRemoto = "n:\users\"&$userDest&"\bck\"&$item
			;Define o local onde o arquivo deve ser buscado para cópia
            Local $origemLocal = $temp&$item
			;realiza a comparação reversa de checksumc até que esteja correto
            while (revChecksum($origemLocal,$destinoRemoto))
				;Se o arquivo for diferente, deleta e inicia a cópia de novo
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

	;"desmapeia" drive mapeado para a transferência
	DriveMapDel("n:")
	;exclui arquivos temporários
	DirRemove($temp)
	;Fecha a janela de transferindo e cria uma mensagem de sucesso
	If WinExists("Transferindo ...") = 1 Then GUIDelete($Form1)
	MsgBox(64,"Copia finalizada","Transferência finalizada com sucesso!")
EndFunc

;Função que inicia o fluxo do processo
Func  start($origem,$hostnDestino,$userDest,$adm,$senha)
	;Remove a pasta que o programa usa para fazer backup, para evitar conflitos
	DirRemove($temp,1)

	;Inicia o método que utiliza o 7z para fazer compressão
	$retResult = _7z($origem, $temp,@SW_SHOW)

	;Em caso de erro, interrompe o processo
    If $retResult <> 0 Then
		MsgBox(64, "Erro:", $retResult)
		Exit
	EndIf
	;Passando do erro, chama o método de transferência
	transfer($temp,$hostnDestino,$userDest,$adm,$senha)
EndFunc

;Função que filtra usuários excluidos
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

;Função que apresenta a primeira janela
Func drawStartForm()
	;Cria o container principal de janela
	$Form1 = GUICreate("BckTool", 247, 270, 322, 165)
	;Puxa alista de usuários em C:\Users. O array 0 contém a quantidade de usuários nessa pasta.
	Local $users = _FileListToArray("c:\users\","*",2)
	$Combo1=""
	;Filtra usuários que não devem ser exibidos
	Local $excluded[6] = ["All Users","Default User","Default","Public","Todos os Usuários","Usuário Padrão"]
	Local $userFiltrado = filter($users,$excluded)
	;Variáveis para o combobox
	Local $comboInformation = ""
	Local $iterator =0
	;Laço de criação de entradas para o combobox
	For $item In $userFiltrado
		;Descarta o array 0, que contem a quantidade e filtra os usuários
        If $iterator <>0 Then
				if $iterator <>1 Then
					;Se estiver em outro nome de usuário, coloca na lista de opções do combobox
					$comboInformation&=$item&"|"
				else
					;Se estiver no primeiro nome de usuário, coloca como a opção selecionada no combobox
					$Combo1 = GUICtrlCreateCombo($item, 80, 24, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))

				EndIf
        EndIf
		;Adiciona 1 para que o iterador possa executar a contagem
		$iterator+=1
	Next

	;remove um | que é adicionado automaticamente
	$iLength = StringLen($comboInformation)
	$comboInformation = StringLeft($comboInformation,($iLength -1))

	;adiciona os nomes de usuário à lista do combobox
	GUICtrlSetData(-1, $comboInformation)

	;cria as labels
	$Label1 = GUICtrlCreateLabel("Usuário", 24, 24, 51, 20)
	$Label2 = GUICtrlCreateLabel("Hostname", 24, 72, 66, 20)
	$Label3 = GUICtrlCreateLabel("Administrador", 24, 120, 66, 20)
	$Label2 = GUICtrlCreateLabel("Senha", 24, 168, 66, 20)
	GUICtrlSetFont(-1, 10, 400, 0, "MS Sans Serif")

	;cria os inputs de texto
	$Input1 = GUICtrlCreateInput("", 96, 72, 129, 21)
	$Input2 = GUICtrlCreateInput("", 96, 120, 129, 21)
	$Input3 = GUICtrlCreateInput("", 96, 168, 129, 21,$ES_PASSWORD)

	;cria um botão para iniciar
	$Button1 = GUICtrlCreateButton("Transferir", 152, 236, 75, 25)

	;manda exibir os elementos gráficos
	GUISetState(@SW_SHOW)

	;Inicia um loop infinito que verifica mensagens de botões
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			;Caso a mensagem seja do botão de fechar
			Case $GUI_EVENT_CLOSE
				Exit
			;Caso a mensagem seja do botão 1 (Transferir)
			Case $Button1
				;Pega o número de seleção do combobox
				Local $usern = _GUICtrlComboBox_GetCurSel($Combo1)+1
				;Pega todas as opções do combobox
				Local $options = _GUICtrlComboBox_GetListArray($Combo1)
				;Pega entre as opções, a opção do número $usern para obter o valor string
				Local $userDest = $options[$usern]
				;Define a pasta de origem com base no usuário selecionado
				Local $origem = "c:\users\"&$userDest
				;Lê o host de destino, nome do adm e senha para mapear drivers
				Local $hostDestino = GUICtrlRead($Input1)
				Local $adm = GUICtrlRead($Input2)
				Local $senha = GUICtrlRead($Input3)

				;Fecha a janela para chamar a próxima
				If WinExists("BckTool") = 1 Then GUIDelete($Form1)
				;Inicia o processo de compressão e envio, vide método
				start($origem,$hostDestino,$userDest,$adm,$senha)
				;Encerra o programa
				Exit
		EndSwitch
	WEnd
EndFunc

;CHAMADA DO FLUXO:
drawStartForm()