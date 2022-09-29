

#Recuperar hostname da nova máquina do cliente em algum lugar e armazenar nesse target

$target = Read-host 'Entre o hostname da máquina de destino:'
#Detectar se é C ou se é E
$pathOrigem = 'C:\Backup'
$pathDestino = '\\'+$target+'\c$'

$net = new-object -ComObject WScript.Network
$net.MapNetworkDrive("u:", $pathDestino, $false, 'usuario', 'senha')

#Iterar arquivos em vez de copiar recursivamente, pra em caso de falha começar do ultimo arquivo recebido.
Copy-Item $pathOrigem -Destination $pathDestino -Force -Recurse

net use u: /delete