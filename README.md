🖥️ ComputerInfoTool
Описание
Мощный модульный инструмент для аудита компьютеров в Active Directory.

✨ Возможности
Возможность	Описание
📂 Active Directory	Получение информации из AD (ОС, OU, статус)
🌐 Доступность	Проверка Ping + DNS + IP
🪟 Win11 Readiness	Аудит готовности к Windows 11 (CPU, RAM, TPM 2.0, Secure Boot)
🔌 Удалённый доступ	Поиск RDP-подключений и LiteManager
🛡️ Антивирус	Проверка Kaspersky Endpoint / Security Center
🚫 Неактивные ПК	Отключение и перемещение неактивных компьютеров
🔍 Дополнительно	Проверка портов, файлов, установленного ПО
📝 Логирование	Полноценное логирование
⚡ Масштабируемость	Поддержка от 5 до 6000+ компьютеров
📁 Структура проекта
ComputerInfoTool/
├── ⭐ Get-ComputerInfo.ps1          ← Главный скрипт
├── ⚙️ config.ps1                    ← Конфигурация + функции ОС
├── 📦 Functions/
│   ├── AD.ps1
│   ├── Logging.ps1
│   ├── OnlineCheck.ps1
│   ├── Win11Readiness.ps1
│   ├── RemoteAccessAudit.ps1
│   ├── KasperskyCheck.ps1
│   ├── DisableInactive.ps1
│   └── ...
├── 📝 Logs/
├── 📊 Reports/
└── 📖 README.md
🚀 Примеры запуска
🔹 Базовый запуск
.\Get-ComputerInfo.ps1 -ComputerListPath "computers.txt"
🔹 Полный аудит
Рекомендуется для комплексной проверки
.\Get-ComputerInfo.ps1 -OU "OU=Workstations,DC=partner,DC=ru" `
    -IncludeOnlineCheck `
    -IncludeWin11Readiness `
    -IncludeRemoteAccessAudit `
    -IncludeKasperskyCheck `
    -IncludeLastLogon
🔹 Отключение неактивных компьютеров
Внимание!
Перед выполнением рекомендуется использовать параметр -WhatIf для проверки!

.\Get-ComputerInfo.ps1 -OU "OU=Computers,DC=partner,DC=ru" `
    -IncludeDisableInactive `
    -DaysInactive 45 `
    -TargetOU "OU=_Заблокированные1,DC=partner,DC=ru" `
    -WhatIf
⚙️ Основные параметры
Параметр	Описание
-ComputerListPath	Путь к txt-файлу со списком компьютеров
-OU	OU для поиска в Active Directory
-IncludeOnlineCheck	Пинг + IP + DNS
-IncludeWin11Readiness	Полная проверка на Windows 11
-IncludeRemoteAccessAudit	RDP + LiteManager
-IncludeKasperskyCheck	Поиск Kaspersky
-IncludeDisableInactive	Отключение старых ПК
-LogLevel	Уровень логирования: Debug / Verbose / Info / Warning
