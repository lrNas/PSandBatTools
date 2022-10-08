#include <File.au3>
#include <Crypt.au3>

$temp=@TempDir&"\bck\"
Func _7z($Aorigem, $Adestino, $show = @SW_HIDE, $CompLvl = 9)
	Local $7za_exe =  StringRegExpReplace(@ProgramFilesDir & "\"," \(x86\)","")&"7-Zip\7z.exe"
	Local $statement = ' a ' & $Adestino & 'bck.7z ' & $Aorigem & ' -mx' & $CompLvl & ' -v256m -bd'
	Local $return7za = ShellExecuteWait($7za_exe, $statement, '', $SHEX_OPEN, $show)
	Select
		Case $return7za = 0
			Return 0
		Case Else
			Return SetError(1, $return7za, 0)
	EndSelect
EndFunc

Func revChecksum($pathOr,$pathDest)
    Local $hashOrigem = _Crypt_HashFile($pathOr,$CALG_SHA_256)
    Local $hashDestino = _Crypt_HashFile($pathDest,$CALG_SHA_256)
    Return $hashOrigem <> $hashDestino
EndFunc

Func transfer($origem,$hostDestino,$userDest)
    Local $remote =  "\\" & $hostDestino & "\c$"
	DriveMapAdd("n:",$remote,0, "Administrator", "1Dois3456.")
    Local $fileArray = _FileListToArray($origem)
    Local $iterator=0
    For $item In $fileArray
        If $iterator ==0 Then
            $iterator+=1
        Else
            Local $destinoRemoto = "n:\users\"&$userDest&"\"&$item
            Local $origemLocal = $temp&$item
            while (revChecksum($origemLocal,$destinoRemoto))
                FileDelete($destinoRemoto)
                FileCopy($origemLocal,$destinoRemoto)
            WEnd
        EndIf
    Next
    DriveMapDel("n:")
EndFunc

$origem = FileSelectFolder("Selecione a pasta que quer comprimir", "")
If @error Then Exit
$hostnDestino = InputBox("Hostname", "Digite o hostname de destino", "machine", " ", "-1", "-1", "100", "100")
$userDest = InputBox("Usuario", "Digite o Usuário de destino", "lrnas", " ", "-1", "-1", "100", "100")

$retResult = _7z($origem, $temp)

If $retResult <> 0 Then
	MsgBox(64, "Erro:", $retResult)
    Exit
EndIf
transfer($temp,$hostnDestino,$userDest)