# Указываем параметры приложения
param (
    [String]$AppName,
    [String]$AppVersion,
    [String]$LocalizedName,
    [String]$MsiPath,
    [String]$InstallCommand
)

# Импорт модуля и подключение к диску
Import-Module "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"
$SiteCode = "-"  
Set-Location "$SiteCode`:"

# Кастомные параметры для DBeaver
$Publisher = "DBeaver Company"
$CollectionName = "-"
$DeadlineDateTime = [datetime]::Now.AddHours(1)

# Создание нового приложения
New-CMApplication -Name $AppName -Description "DBeaver is free and open source universal database tool for developers and database administrators. Usability is the main goal of this project, program UI is carefully designed and implemented. It is free and open-source (ASL). It is multiplatform." -Publisher $Publisher -SoftwareVersion $AppVersion -LocalizedName $LocalizedName -IconLocationFile "\\-\Sources\Icons\DBever_.jpg"
$App = Get-CMApplication -Name $AppName
Move-CMObject -FolderPath "$SiteCode:\Application\DB management" -InputObject $App

# Создание условия обнаружения
$clause = New-CMDetectionClauseRegistryKeyValue -Hive LocalMachine -KeyName 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DBeaver' -PropertyType Version -ValueName 'DisplayVersion' -Value -ExpectedValue $AppVersion -ExpressionOperator GreaterEquals

# Добавление типа развертывания
Add-CMScriptDeploymentType -ApplicationName $AppName -DeploymentTypeName DT_Script_Npp -InstallCommand $InstallCommand -UninstallCommand '"C:\Program Files\DBeaver\Uninstall.exe" /S /allusers' -AddDetectionClause $clause -ContentLocation $MsiPath -InstallationBehaviorType InstallForSystem -EstimatedRuntimeMins 10 -LogonRequirementType WhetherOrNotUserLoggedOn

# Распространение контента
Start-CMContentDistribution -ApplicationName $AppName -DistributionPointName '-'
#Start-CMContentDistribution -ApplicationName $AppName -DistributionPointName '-'
#Start-CMContentDistribution -ApplicationName $AppName -DistributionPointName '-'
#Start-CMContentDistribution -ApplicationName $AppName -DistributionPointName '-'

# Создание развертывания
New-CMApplicationDeployment -ApplicationName  $AppName -CollectionName $CollectionName -DeployAction Install -DeadlineDateTime $DeadlineDateTime -DeployPurpose Available -UserNotification DisplaySoftwareCenterOnly

#Просто так не прокатит. Надо доп учетку.
# Отправка письма
#$smtpServer = "" 
#$smtpFrom = ""  
#$smtpTo = ""  
#$subject = "Новое приложение создано: $AppName"
#$body = @"
#Создано новое приложение:
#Имя приложения: $AppName
#Версия: $AppVersion
#Время создания: $(Get-Date)
#Развернуто в коллекцию: $CollectionName
#"@
#
#Send-MailMessage -SmtpServer $smtpServer -From $smtpFrom -To $smtpTo -Subject $subject -Body $body -Encoding UTF8
