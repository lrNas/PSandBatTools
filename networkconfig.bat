PowerShell Set-NetAdapterAdvancedProperty -InterfaceDescription '*' -DisplayName 'Adaptive Link Speed' -DisplayValue 'Disabled'
PowerShell Set-NetAdapterAdvancedProperty -InterfaceDescription '*' -DisplayName 'Battery Mode Link Speed' -DisplayValue 'Not Speed Down'
PowerShell Set-NetAdapterAdvancedProperty -InterfaceDescription '*' -DisplayName 'Energy-Efficient Ethernet' -DisplayValue 'Disabled'
PowerShell Set-NetAdapterAdvancedProperty -InterfaceDescription '*' -DisplayName 'Idle Power Saving' -DisplayValue 'Disabled'
PowerShell Set-NetAdapterAdvancedProperty -InterfaceDescription '*' -DisplayName 'Selective suspend' -DisplayValue 'Disabled'
PowerShell Disable-NetAdapterBinding -Name '*' -DisplayName 'Juniper Network Service'
PowerShell Disable-NetAdapterBinding -Name '*' -ComponentID 'ms_tcpip6'
sc config Wlansvc start= auto
sc config WwanSvc start= auto
sc config DOT3SVC start= auto
ipconfig /release
ipconfig /renew
gpupdate /force
set /p DUMMY= Configurções de rede realizadas com sucesso. Aperte ENTER para fechar.