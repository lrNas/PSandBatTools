;Executa a rotina principal do ADGU (Update de grupos)
Func runADGU($configs)
	;Define o local para o conf.cf
	$cfFile = @ScriptDir & "\conf.cf"
	;Configura a partir do arquivo especificado
	configureFromFile($configs, $cfFile);
	;Define a execução do powershell como silenciosa, desmarcar a segunda linha para ficar visível
	$hidden = " -WindowStyle hidden "
	;$hidden = ""
	;Carrega configurações para variáveis atuais
	$username = DllStructGetData($configs, "username")
	$password = DllStructGetData($configs, "password")
	$domain = DllStructGetData($configs, "domain")
	$span = DllStructGetData($configs, "span")
	$depfile = DllStructGetData($configs, "depfile")
	;Executa o Script Powershell que muda o grupo de todos os usuários que possuam o departamento
	;igual ao especificado no arquivo dep.csv, como o usuário configurado no arquivo.
	$iPID = RunAsWait($username, $domain, $password, 2, "powershell.exe" & $hidden & " $When = ((Get-Date).AddDays(-" & $span & ")).Date;" & _
			"$users = Get-ADUser -Filter {(whenCreated -ge $When) -and (objectClass -eq 'user')} -Properties department,SamAccountName;" & _
			"$dep = Import-Csv -Path '" & $depfile & "';" & _
			"$objects=@();" & _
			"$users | ForEach-Object {$object = [pscustomobject]@{department = $_.department;" & _
			"user = $_.SamAccountName};$dep|ForEach-Object{if ($_.department -eq $object.department){Add-ADGroupMember $_.group $object.user}}}", @SystemDir, @SW_SHOW, $STDERR_MERGED)
EndFunc
