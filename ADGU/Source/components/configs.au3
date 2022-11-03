func configs()
    ;Cria estrutura de dados que será usada para configuração de dados
    Local $estrutura ='struct;char bit[10];int span[3];char dir[128];char username[128];char domain[128];char password[128];char depfile[128];char cffile[128];endstruct'
    $configs = DllStructCreate($estrutura)
    ;Dados pré-carregados para facilitar teste. Os com ; no final podem ser esvaziados
    DllStructSetData($configs, 'bit', "0x01249F")
    DllStructSetData($configs, 'span', 3);
    DllStructSetData($configs, 'dir', "C:\ADGU");
    DllStructSetData($configs, 'username', "Administrator");
    DllStructSetData($configs, 'domain', "house.dom");
    DllStructSetData($configs, 'password', "P4ssw0rd.");
    DllStructSetData($configs, 'depfile', @ScriptDir&"\dep.csv");
    DllStructSetData($configs, 'cfFile', @ScriptDir&"\conf.cf")
    return $configs
EndFunc