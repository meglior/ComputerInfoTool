# ComputerInfoTool

Мощный модульный инструмент для аудита компьютеров в Active Directory.

## Возможности

- Получение информации из AD (ОС, OU, статус)
- Проверка доступности (Ping + DNS + IP)
- Win11 Readiness Audit (CPU, RAM, TPM 2.0, Secure Boot)
- Поиск RDP-подключений и LiteManager
- Проверка Kaspersky Endpoint / Security Center
- Отключение и перемещение неактивных компьютеров
- Проверка портов, файлов, установленного ПО
- Полноценное логирование
- Поддержка от 5 до 6000+ компьютеров

## Структура проекта

ComputerInfoTool/
├── Get-ComputerInfo.ps1          ← Главный скрипт
├── config.ps1                    ← Конфигурация + функции ОС
├── Functions/
│   ├── AD.ps1
│   ├── Logging.ps1
│   ├── OnlineCheck.ps1
│   ├── Win11Readiness.ps1
│   ├── RemoteAccessAudit.ps1
│   ├── KasperskyCheck.ps1
│   ├── DisableInactive.ps1
│   └── ...
├── Logs/
├── Reports/
└── README.md

## Примеры запуска

### Базовый запуск

```powershell
.\Get-ComputerInfo.ps1 -ComputerListPath "computers.txt"

#Полный аудит

.\Get-ComputerInfo.ps1 -OU "OU=Workstations,DC=partner,DC=ru" `
    -IncludeOnlineCheck `
    -IncludeWin11Readiness `
    -IncludeRemoteAccessAudit `
    -IncludeKasperskyCheck `
    -IncludeLastLogon

#Отключение неактивных компьютеров

.\Get-ComputerInfo.ps1 -OU "OU=Computers,DC=partner,DC=ru" `
    -IncludeDisableInactive `
    -DaysInactive 45 `
    -TargetOU "OU=_Заблокированные1,DC=partner,DC=ru" `
    -WhatIf
```

## Основные параметры

ПараметрОписание-ComputerListPathПуть к txt-файлу со списком компьютеров-OUOU для поиска-IncludeOnlineCheckПинг + IP + DNS-IncludeWin11ReadinessПолная проверка на Windows 11-IncludeRemoteAccessAuditRDP + LiteManager-IncludeKasperskyCheckПоиск Kaspersky-IncludeDisableInactiveОтключение старых ПК-LogLevelDebug / Verbose / Info / Warning