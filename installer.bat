set dir= %~dp0%
for /F %%x in ('dir /B/D %dir%items') do %dir%items\%%%x /s

rmdir /S C:\SWSetup
Sc config wlansvc start=auto
powershell Set-WinUserLanguageList -LanguageList pt-br -force
set /p DUMMY=Instalacao realizada com sucesso. Aperte ENTER para fechar.