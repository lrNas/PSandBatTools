
$pathOrigem = Read-host 'Entre o caminho da pasta a ser copiada:'
$target = Read-host 'Entre o hostname ou ip da máquina de destino:'
$pathDestino = '\\'+$target+'\c$'
Write-Host "Credenciais de acesso à máquina:"
$user = Read-Host "Usuário"
$pass = Read-Host "Senha"
$net = new-object -ComObject WScript.Network
$net.MapNetworkDrive("u:", $pathDestino, $false, $user, $pass)

#Iterar arquivos em vez de copiar recursivamente, pra em caso de falha começar do ultimo arquivo recebido.
Copy-Item $pathOrigem -Destination $pathDestino -Force -Recurse

net use u: /delete