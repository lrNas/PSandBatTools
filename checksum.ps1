#Requires -RunAsAdministrator
Set-ExecutionPolicy Bypass
Set-ExecutionPolicy Unrestricted
$repeat='S'

while($repeat -eq 'S'){
 Write-Host 'Selecione sua operação'
 Write-Host '1-Criar hashlist'
 Write-Host '2-Comparar hashlist'
$selector=Read-Host '>'
if($selector -eq '1'){
    $localDestino=Read-Host 'Local de destino'

$FileList = Get-ChildItem -Recurse 

$Counter = 0
$Results = foreach ($FL_Item in $FileList)
    {
    $Counter ++
    Write-Host 'Processando arquivo '$Counter' de '($FileList.Count)
    $FileHash = Get-FileHash -LiteralPath $FL_Item.FullName -Algorithm MD5 -ErrorAction SilentlyContinue
    $thing=@{}
    if ($FileHash)
        {
        $thing=@{
            Hash = $FileHash.Hash
            Path = $FileHash.Path
            }
        }
        else
        {
        $thing={
            Hash = 'Erro'
            Path = $FL_Item.FullName
            }
        }
        New-Object -TypeName PSObject -Property $thing
    }    

    $pathSaida=$localDestino+"hash"+(Get-Date -Format ".ddMMyy-HHmm")+".csv"
$Results |
    Export-Csv -LiteralPath $pathSaida -NoTypeInformation


 Write-Host 'hashlist criada: '$pathSaida
}
if($selector -eq '2'){

$origemPath = Read-Host -Prompt 'Digite o local do arquivo CSV da pasta de Origem:'
$destinoPath = Read-Host -Prompt 'Digite o local do arquivo CSV da pasta de Destino:'
$origem = Import-Csv $origemPath
$destino = Import-Csv $destinoPath
$count=0
foreach($line in $origem)
{
 
    Write-Host 'Processando arquivo '$count' de '($origem.Count)

    if(-not($line.Hash -eq $destino[$count].Hash)){
     Write-Host ""
     Write-Host 'Arquivo Inválido:'
     Write-Host $line.Path
     Write-Host ''
    }
    $count=$count+1
}
 Write-Host ""
}


$repeat=Read-Host 'Deseja fazer outra operação? (S/N)'
}

$selector=Read-Host 'Pressione qualquer tecla para finalizar'
Set-ExecutionPolicy Byp