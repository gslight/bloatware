:: Name:		bloatware.bat
:: Purpose:		Remove all bloatware on new PCs
:: Author:		George Slight
:: Revisions:	
:: Jan 2015 - initial version
:: Mar 2015 - Added more bloatware
:: Aug 2015 - Added more bloatware, and public release.


@echo off

cls
color 0f
set SCRIPT_VERSION=1.0.2
set SCRIPT_DATE=2015-09-10
set TARGET_METRO=no
title BLOATWARE v%SCRIPT_VERSION% (%SCRIPT_DATE%)

:: Get the date into ISO 8601 standard date format (yyyy-mm-dd) so we can use it 
FOR /f %%a in ('WMIC OS GET LocalDateTime ^| find "."') DO set DTS=%%a
set CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%

:: Get in the correct drive (~d0). This is sometimes needed when running from a thumb drive
%~d0 2>NUL
:: Get in the correct path (~dp0). This is useful if we start from a network share, it converts CWD to a drive letter
pushd %~dp0 2>NUL

echo %CUR_DATE% %TIME%    Launching script...
echo.


:: PREP JOB: Force WMIC location in case the system PATH is messed up
set WMIC=%SystemRoot%\system32\wbem\wmic.exe

:: Closes all browsers for correct removal
taskkill /f /im iexplore.exe /im firefox.exe /im chrome.exe

::::::::::::::::::::::::::
:: Interactive Removals ::
::::::::::::::::::::::::::

:: McAfee Internet Security
"%ProgramFiles%\McAfee\MSC\mcuihost.exe" /body:misp://MSCJsRes.dll::uninstall.html /id:uninstall 2>NUL
:: Dell Backup and Restore
"%ProgramFiles(x86)%\InstallShield Installation Information\{0ED7EE95-6A97-47AA-AD73-152C08A15B04}\setup.exe" -runfromtemp -l0x0409  -removeonly 2>NUL
:: McAfee Suite
"%ProgramFiles%\McAfee Security Scan\uninstall.exe" /S 2>NUL
"%ProgramFiles(x86)%\McAfee Security Scan\uninstall.exe" /S 2>NUL
:: CyberLink PowerDVD 12
"%ProgramFiles(x86)%\InstallShield Installation Information\{B46BEA36-0B71-4A4E-AE41-87241643FA0A}\Setup.exe" /z-uninstall /norestart /silent 2>NUL
:: HP Support Assistant
"%ProgramFiles(x86)%\InstallShield Installation Information\{EE202411-2C26-49E8-9784-1BC1DBF7DE96}\setup.exe" -runfromtemp -l0x0409  -removeonly 2>NUL
start /wait msiexec /x {8C696B4B-6AB1-44BC-9416-96EAC474CABE} /qn /norestart /passive
:: HP Theft Recovery
"%ProgramFiles(x86)%\InstallShield Installation Information\{B1E569B6-A5EB-4C97-9F93-9ED2AA99AF0E}\setup.exe" -runfromtemp -l0x0409  -removeonly 2>NUL
:: PDF Complete
"%ProgramFiles(x86)%\PDF Complete\uninstall.exe" 2>NUL
:: Evernote
"%ProgramFiles(x86)%\Evernote_TLauncher\uninstall.exe" /S 2>NUL
start /wait msiexec /x {f761359c-9ced-45ae-9a51-9d6605cd55c4} /qn /norestart /passive
:: Spotify
"%ProgramFiles(x86)%\Spotify\Spotify.exe" /uninstall 2>NUL
:: Toshiba Manuals
"%ProgramFiles(x86)%\InstallShield Installation Information\{90FF4432-21B7-4AF6-BA6E-FB8C1FED9173}\setup.exe" -runfromtemp -l0x0409  -removeonly 2>NUL
:: Toshiba Recovery Media Creator
"%ProgramFiles(x86)%\InstallShield Installation Information\{B65BBB06-1F8E-48F5-8A54-B024A9E15FDF}\Setup.exe" -runfromtemp -removeonly 2>NUL
"C:\Program Files (x86)\InstallShield Installation Information\{2A87D48D-3FDF-41fd-97CD-A1E370EFFFE2}\Setup.exe" /z-uninstall 2>NUL
"C:\Program Files (x86)\InstallShield Installation Information\{B46BEA36-0B71-4A4E-AE41-87241643FA0A}\Setup.exe" /z-uninstall 2>NUL
:: Removes Ask Toolbar
"C:\Program Files\Ask.com\Updater\Updater.exe" -uninstall 2>NUL
"C:\Program Files (x86)\Ask.com\Updater\Updater.exe" -uninstall 2>NUL
:: McAfee Security Scan
"%ProgramFiles%\McAfee Security Scan\uninstall.exe" /S 2>NUL
"%ProgramFiles(x86)%\McAfee Security Scan\uninstall.exe" /S 2>NUL
:: Removes Live Essentials
start /wait msiexec.exe /x {FE044230-9CA5-43F7-9B58-5AC5A28A1F33} /quiet /norestart
"c:\program files (x86)\windows live\installer\wlarp.exe" /cleanup:all /q 2>NUL
"c:\program files\windows live\installer\wlarp.exe" /cleanup:all /q 2>NUL
:: Search Protect by Conduit
"C:\Program Files\SearchProtect\bin\uninstall.exe" /S 2>NUL
"C:\Program Files (x86)\SearchProtect\bin\uninstall.exe" /S 2>NUL

:PROMPT
echo.
echo.
echo This next part can take up to 30 minutes and may not be silent, would you like to skip it? 
echo.              
SET /P SKIP=([Y]/N)?
IF /I "%SKIP%" NEQ "N" GOTO SKIP
echo.

:DONT_SKIP
FOR /F "tokens=*" %%i in (programs_to_target.txt) DO echo. %%i && %WMIC% product where "name like '%%i'" uninstall /nointeractive

:::::::::::::::::::::
:: Silent Removals ::
:::::::::::::::::::::

:SKIP
echo.

:: JOB: Remove default Metro apps (Windows 8/8.1/2012/2012-R2 only).
:: Read nine characters into the WIN_VER variable (starting at position 0 on the left) to check for Windows 8; 16 characters in to check for Server 2012.
:: The reason we read partially into the variable instead of comparing the whole thing is because we don't care what sub-version of 8/2012 we're on.
:: Also I'm lazy and don't want to write ten different comparisons for all the random sub-versions MS churns out with inconsistent names.
if "%WIN_VER:~0,9%"=="Windows 8" set TARGET_METRO=yes
if "%WIN_VER:~0,18%"=="Windows Server 201" set TARGET_METRO=yes
:: Check if we're forcefully skipping Metro de-bloat.
if /i %TARGET_METRO%==yes (
	call :log "%CUR_DATE% %TIME%    Windows 8/2012 detected, removing OEM Metro apps..."
	:: Force allowing us to start AppXSVC service. AppXSVC is the MSI Installer equivalent for "apps" (vs. programs)
		(
		net start AppXSVC
		:: Enable scripts in PowerShell
		powershell "Set-ExecutionPolicy Unrestricted -force 2>&1 | Out-Null"
		:: Call PowerShell to run the commands
		powershell "Get-AppXProvisionedPackage -online | Remove-AppxProvisionedPackage -online 2>&1 | Out-Null"
		powershell "Get-AppxPackage -AllUsers | Remove-AppxPackage 2>&1 | Out-Null"
		)
	:: Running DISM cleanup against unused App binaries..."
    Dism /Online /Cleanup-Image /StartComponentCleanup
)

:: Ask Toolbar
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C0300} /qn /norestart /passive
start /wait msiexec /x {86D4B82A-ABED-442A-BE86-96357B70F4FE} /qn /norestart /passive
:: Bing Bar
start /wait msiexec /x {3365E735-48A6-4194-9988-CE59AC5AE503} /qn /norestart /passive
start /wait msiexec /x {C28D96C0-6A90-459E-A077-A6706F4EC0FC} /qn /norestart /passive
start /wait msiexec /x {77F8A71E-3515-4832-B8B2-2F1EDBD2E0F1} /qn /norestart /passive
:: Dell Access
start /wait msiexec /x {F839C6BD-E92E-48FA-9CE6-7BFAF94F7096} /qn /norestart /passive
:: Dell Backup and Recovery Manager
start /wait msiexec /x {975DFE7C-8E56-45BC-A329-401E6B1F8102} /qn /norestart /passive
start /wait msiexec /x {50B4B603-A4C6-4739-AE96-6C76A0F8A388} /qn /norestart /passive
start /wait msiexec /x {731B0E4D-F4C7-450C-95B0-E1A3176B1C75} /qn /norestart /passive
rd /s /q C:\dell\dbrm 2>NUL
:: Dell Client System Update
start /wait msiexec /x {69093D49-3DD1-4FB5-A378-0D4DB4CF86EA} /qn /norestart /passive
start /wait msiexec /x {04566294-A6B6-4462-9721-031073EB3694} /qn /norestart /passive
start /wait msiexec /x {2B2B45B1-3CA0-4F8D-BBB3-AC77ED46A0FE} /qn /norestart /passive
:: Dell Command | Update
start /wait msiexec /x {EC542D5D-B608-4145-A8F7-749C02BE6D94} /qn /norestart /passive
:: Dell Command | Power
start /wait msiexec /x {DDDAF4A7-8B7D-4088-AECC-6F50E594B4F5} /qn /norestart /passive
:: Dell ControlPoint
start /wait msiexec /x {A9C61491-EF2F-4ED8-8E10-FB33E3C6B55A} /qn /norestart /passive
:: Dell ControlVault Host Components Installer
start /wait msiexec /x {5A26B7C0-55B1-4DA8-A693-E51380497A5E} /qn /norestart /passive
:: Dell Datasafe Online
start /wait msiexec /x {7EC66A95-AC2D-4127-940B-0445A526AB2F} /qn /norestart /passive
:: Dell Dock
start /wait msiexec /x {E60B7350-EA5F-41E0-9D6F-E508781E36D2} /qn /norestart /passive
:: Dell "Feature Enhancement" Pack
start /wait msiexec /x {992D1CE7-A20F-4AB0-9D9D-AFC3418844DA} /qn /norestart /passive
:: Dell Getting Started Guide
start /wait msiexec /x {7DB9F1E5-9ACB-410D-A7DC-7A3D023CE045} /qn /norestart /passive
:: Dell Power Manager
start /wait msiexec /x {CAC1E444-ECC4-4FF8-B328-5E547FD608F8} /qn /norestart /passive
:: Dell Support Center
start /wait msiexec /x {0090A87C-3E0E-43D4-AA71-A71B06563A4A} /qn /norestart /passive
:: Embassy Suite
start /wait msiexec /x {20A4AA32-B3FF-4A0B-853C-ACDDCD6CB344} /qn /norestart /passive
:: Epson Customer Participation
start /wait msiexec /x {814FA673-A085-403C-9545-747FC1495069} /qn /norestart /passive
:: Intel Trusted Connect Client
start /wait msiexec /x {44B72151-611E-429D-9765-9BA093D7E48A} /qn /norestart /passive
:: Intel Update
start /wait msiexec /x {78091D68-706D-4893-B287-9F1DFB24F7AF} /qn /norestart /passive
:: Intel Update Manager
start /wait msiexec /x {608E1B9B-A2E8-4A1F-8BAB-874EB0DD25E3} /qn /norestart /passive
:: Java Auto Updater
start /wait msiexec /x {4A03706F-666A-4037-7777-5F2748764D10} /qn /norestart /passive
start /wait msiexec /x {CCB6114E-9DB9-BD54-5AA0-BC5123329C9D} /qn /norestart /passive
:: Lenovo Message Center Plus
start /wait msiexec /x {3849486C-FF09-4F5D-B491-3E179D58EE15} /qn /norestart /passive
:: Lenovo Metrics Collector SDK
start /wait msiexec /x {DDAA788F-52E6-44EA-ADB8-92837B11BF26} /qn /norestart /passive
:: Lenovo Patch Utility
start /wait MsiExec /X {C6FB6B4A-1378-4CD3-9CD3-42BA69FCBD43} /qn /norestart /passive
:: Lenovo Reach
start /wait msiexec /x {3245D8C8-7FE0-4FD4-B04B-2720A333D592} /qn /norestart /passive
start /wait msiexec /x {0B5E0E89-4BCA-4035-BBA1-D1439724B6E2} /qn /norestart /passive
:: Lenovo Registration
start /wait msiexec /x {6707C034-ED6B-4B6A-B21F-969B3606FBDE} /qn /norestart /passive
:: Lenovo SMB Customizations
start /wait msiexec /x {AFD7B869-3B70-40C7-8983-769256BA3BD2} /qn /norestart /passive
:: Lenovo Solution Center
start /wait msiexec /x {63942F7E-3646-45EC-B8A9-EAC40FEB66DB} /qn /norestart /passive
start /wait msiexec /x {13BD494D-9ACD-420B-A291-E145DED92EF6} /qn /norestart /passive
start /wait msiexec /x {4C2B6F96-3AED-4E3F-8DCE-917863D1E6B1} /qn /norestart /passive
:: Lenovo System Update
start /wait msiexec /x {25C64847-B900-48AD-A164-1B4F9B774650} /qn /norestart /passive
start /wait msiexec /x {8675339C-128C-44DD-83BF-0A5D6ABD8297} /qn /norestart /passive
start /wait msiexec /x {C9335768-C821-DD44-38FB-A0D5A6DB2879} /qn /norestart /passive
:: Lenovo User Guide
start /wait msiexec /x {13F59938-C595-479C-B479-F171AB9AF64F} /qn /norestart /passive
:: Lenovo Warranty Info
start /wait msiexec /x {FD4EC278-C1B1-4496-99ED-C0BE1B0AA521} /qn /norestart /passive
:: Microsoft Search Enhancement Pack
start /wait msiexec /x {4CBA3D4C-8F51-4D60-B27E-F6B641C571E7} /qn /norestart /passive
:: Roxio File Backup
start /wait msiexec /x {60B2315F-680F-4EB3-B8DD-CCDC86A7CCAB} /qn /norestart /passive
:: Roxio BackOnTrack
start /wait msiexec /x {5A06423A-210C-49FB-950E-CB0EB8C5CEC7} /qn /norestart /passive
:: Trend Micro Trial
start /wait msiexec /x {BED0B8A2-2986-49F8-90D6-FA008D37A3D2} /qn /norestart /passive
:: Trend Micro Worry-Free Business Security Trial
start /wait msiexec /x {0A07E717-BB5D-4B99-840B-6C5DED52B277} /qn /norestart /passive
:: Windows Live Family Safety
start /wait msiexec /x {5F611ADA-B98C-4DBB-ADDE-414F08457ECF} /qn /norestart /passive
:: Windows Live Toolbar
start /wait msiexec /x {995F1E2E-F542-4310-8E1D-9926F5A279B3} /qn /norestart /passive
:: Toshiba Password Utility
start /wait msiexec /x {6C0A2179-56CB-4F1F-9681-E777A4F3C800} /qn /norestart /passive
:: Skype 5.3
start /wait msiexec /x {D6F879CC-59D6-4D4B-AE9B-D761E48D25ED} /qn /norestart /passive
:: Toshiba Tempro
start /wait msiexec /x {F082CB11-4794-4259-99A1-D91BA762AD15} /qn /norestart /passive
:: Toshiba Power Saver
start /wait msiexec /x {4573FA6D-5FC1-4CA0-8D90-BAF9325B28ED} /qn /norestart /passive
:: Toshiba PC Health Monitor
start /wait msiexec /x {9DECD0F9-D3E8-48B0-A390-1CF09F54E3A4} /qn /norestart /passive
:: Toshiba HDD/SSD Alert
start /wait msiexec /x {D4322448-B6AF-4316-B859-D8A0E84DCB38} /qn /norestart /passive
:: Toshiba eco Utility
start /wait msiexec /x {F5AFF327-9B52-4E96-B5A0-BD2488A8EEC9} /qn /norestart /passive
:: Toshiba Sleep Utility
start /wait msiexec /x {472175F3-ACB2-4977-8CC8-EB971C24F245} /qn /norestart /passive
:: Sierra Wireless AirCard Watcher
start /wait msiexec /x {A05C84FD-989E-4C30-B16A-730233E8237B} /qn /norestart /passive
:: Google Drive
start /wait msiexec /x {C60F3836-333A-4AE2-B526-CFDBA143A9BA} /qn /norestart /passive
:: HP customer experience enhancements
start /wait msiexec /x {07FA4960-B038-49EB-891B-9F95930AA544} /qn /norestart /passive
:: Removes PDForge Toolbar V6
start /wait msiexec /x {96B3C2A3-ADD6-4E63-89D3-1E3AC115D3FA} /qn /norestart /passive
:: Virtual DJ Toolbar
start /wait msiexec /x {56444A2D-5637-006A-76A7-A758B70C0A06} /qn /norestart /passive
:: Removes Ask Toolbar
start /wait msiexec /x {13F537F0-AF09-11D6-9029-0002B31F9E59} /qn /norestart /passive
start /wait msiexec /x {2318C2B1-4965-11D4-9B18-009027A5CD4F} /qn /norestart /passive
start /wait msiexec /x {2E5E800E-6AC0-411E-940A-369530A35E43} /qn /norestart /passive
start /wait msiexec /x {4E7BD74F-2B8D-469E-C0FB-F778B590AD7D} /qn /norestart /passive
start /wait msiexec /x {5A263CF7-56A6-4D68-A8CF-345BE45BC911} /qn /norestart /passive
start /wait msiexec /x {86D4B82A-ABED-442A-BE86-96357B70F4FE} /qn /norestart /passive
start /wait msiexec /x {AA58ED58-01DD-4D91-8333-CF10577473F7} /qn /norestart /passive
start /wait msiexec /x {AF69DE43-7D58-4638-B6FA-CE66B5AD205D} /qn /norestart /passive
start /wait msiexec /x {D4027C7F-154A-4066-A1AD-4243D8127440} /qn /norestart /passive
start /wait msiexec /x {EF99BD32-C1FB-11D2-892F-0090271D4F88} /qn /norestart /passive
start /wait msiexec /x {4152532D-4D45-4400-76A7-A758B70C0A06} /qn /norestart /passive
start /wait msiexec /x {41525333-2D56-3700-76A7-A758B70C0300} /qn /norestart /passive
start /wait msiexec /x {41525333-0076-A76A-76A7-A758B70C0A02} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C0A03} /qn /norestart /passive
start /wait msiexec /x {42435041-2d53-4154-00a7-a758b70b0a00} /qn /norestart /passive
start /wait msiexec /x {4F524A00-6A76-A76A-76A7-A758B70C1C01} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-2D53-4154-A758B70C1D00} /qn /norestart /passive
start /wait msiexec /x {4152532D-5247-006A-76A7-A758B70C0A00} /qn /norestart /passive
start /wait msiexec /x {41525333-2D56-3700-76A7-A758B70C1D00} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C0001} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C1C01} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C1D00} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C0700} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C1500} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C1C01} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C1D00} /qn /norestart /passive
start /wait msiexec /x {57434C32-2D56-3700-76A7-A758B70C1C01} /qn /norestart /passive
start /wait msiexec /x {57434C32-2D56-3700-76A7-A758B70C1D00} /qn /norestart /passive
start /wait msiexec /x {86D4B82A-ABED-442A-BE86-96357B70F4FE} /qn /norestart /passive
:: Bing/Windows Live Bar Removal
start /wait msiexec /x {C28D96C0-6A90-459E-A077-A6706F4EC0FC} /qn /norestart /passive
start /wait msiexec /x {786C4AD1-DCBA-49A6-B0EF-B317A344BD66} /qn /norestart /passive
start /wait msiexec /x {A5C4AD72-25FE-4899-B6DF-6D8DF63C93CF} /qn /norestart /passive
start /wait msiexec /x {341201D4-4F61-4ADB-987E-9CCE4D83A58D} /qn /norestart /passive
start /wait msiexec /x {F084395C-40FB-4DB3-981C-B51E74E1E83D} /qn /norestart /passive
start /wait msiexec /x {D5A145FC-D00C-4F1A-9119-EB4D9D659750} /qn /norestart /passive
start /wait msiexec /x {1e03db52-d5cb-4338-a338-e526dd4d4db1} /qn /norestart /passive
:: Removes Live Mesh
start /wait msiexec /x {DECDCB7C-58CC-4865-91AF-627F9798FE48} /qn /norestart /passive
:: Removes Live Mail
start /wait msiexec /x {C66824E4-CBB3-4851-BB3F-E8CFD6350923} /qn /norestart /passive
:: Removes Live Mesh ActiveX
start /wait msiexec /x {2902F983-B4C1-44BA-B85D-5C6D52E2C441} /qn /norestart /passive
:: Removes Live Messager
start /wait msiexec /x {EB4DF488-AAEF-406F-A341-CB2AAA315B90} /qn /norestart /passive
:: Removes Cisco EAP Fast Modules
start /wait msiexec /x {64bf0187-f3d2-498b-99ea-163af9ae6ec9} /qn /norestart /passive 
:: Removes Cisco LEAP Module
start /wait msiexec /x {51c7ad07-c3f6-4635-8e8a-231306d810fe} /qn /norestart /passive
:: Removes Cisco PEAP Module
start /wait msiexec /x {ed5776d5-59b4-46b7-af81-5f2d94d7c640} /qn /norestart /passive
:: removes Energy Star
start /wait msiexec /x {bd1a34c9-4764-4f79-ae1f-112f8c89d3d4} /qn /norestart /passive
:: Random bunch of clutter here, 
start /wait msiexec /x {23544215-E6E6-448B-B6E9-6268D5B3E74D} /qn /norestart /passive
start /wait msiexec /x {438363A8-F486-4C37-834C-4955773CB3D3} /qn /norestart /passive
start /wait msiexec /x {4E76FF7E-AEBA-4C87-B788-CD47E5425B9D} /qn /norestart /passive
start /wait msiexec /x {59202086-BEA1-411A-8AA4-A5DCD28FF537} /qn /norestart /passive
start /wait msiexec /x {6349342F-9CEF-4A70-995A-2CF3704C2603} /qn /norestart /passive
start /wait msiexec /x {7561C06A-7797-4462-A7C3-86F45AE901CF} /qn /norestart /passive
start /wait msiexec /x {B1E569B6-A5EB-4C97-9F93-9ED2AA99AF0E} /qn /norestart /passive
start /wait msiexec /x {6F340107-F9AA-47C6-B54C-C3A19F11553F} /qn /norestart /passive
start /wait msiexec /x {DBE16A07-DDFF-4453-807A-212EF93916E0} /qn /norestart /passive
start /wait msiexec /x {FE885DCE-4917-4E47-9881-883CBB3B8F50} /qn /norestart /passive
if exist "C:\Users\Public\Desktop\SageOne.lnk" del "C:\Users\Public\Desktop\SageOne.lnk" 2>NUL
if exist "C:\Users\Public\Desktop\TOSHIBA Services.lnk" del "C:\Users\Public\Desktop\TOSHIBA Services.lnk" 2>NUL
if exist "C:\Users\%username%\Desktop\eBay.lnk" del "C:\Users\%username%\Desktop\eBay.lnk" 2>NUL
if exist "C:\Users\Public\Desktop\Skype.lnk" del "C:\Users\Public\Desktop\Skype.lnk" 2>NUL
if exist "C:\Users\Public\Desktop\Box offer for HP.lnk" del "C:\Users\Public\Desktop\Box offer for HP.lnk" 2>NUL
start /wait msiexec /x {E2CAA395-66B3-4772-85E3-6134DBAB244E} /qn /norestart /passive
"C:\Program Files (x86)\InstallShield Installation Information\{BC12448A-0B41-4E11-B242-B1129512F5B7}\setup.exe" -l0x9  /remove 2>NUL
start /wait msiexec /x {BC8233D8-59BA-4D40-92B9-4FDE7452AA8B} /qn /norestart /passive
start /wait msiexec /x {C2D4CD4A-AE20-40B3-8726-8ED1C03E8C15} /qn /norestart /passive
"C:\Program Files (x86)\InstallShield Installation Information\{2A87D48D-3FDF-41fd-97CD-A1E370EFFFE2}\Setup.exe" /z-uninstall
"C:\Program Files (x86)\InstallShield Installation Information\{B46BEA36-0B71-4A4E-AE41-87241643FA0A}\Setup.exe" /z-uninstall
:: Bing Desktop
start /wait msiexec /x {7D095455-D971-4D4C-9EFD-9AF6A6584F3A} /qn /norestart /passive
:: Best Buy pc app
start /wait msiexec /x {FBBC4667-2521-4E78-B1BD-8706F774549B} /qn /norestart /passive
if exist "%ProgramData%\{D8EAE~1\Best Buy pc app Setup.msi" start /wait msiexec /x "%ProgramData%\{D8EAE~1\Best Buy pc app Setup.msi" /qn /norestart /passive
:: WildTangent GUIDs
start /wait msiexec /x {23170F69-40C1-2702-0938-000001000000} /qn /norestart /passive
start /wait msiexec /x {EE691BD9-2B2C-6BFB-6389-ABAF5AD2A4A1} /qn /norestart /passive
start /wait msiexec /x {6E3610B2-430D-4EB0-81E3-2B57E8B9DE8D} /qn /norestart /passive
start /wait msiexec /x {9E9EF3EC-22BC-445C-A883-D8DB2908698D} /qn /norestart /passive
:: \/ "Delicious Emilys Childhood Memories Premium Edition"....wtf
start /wait msiexec /x {FC0ADA4D-8FA5-4452-8AFF-F0A0BAC97EF7} /qn /norestart /passive
start /wait msiexec /x {6F340107-F9AA-47C6-B54C-C3A19F11553F} /qn /norestart /passive
start /wait msiexec /x {DD7C5FC1-DCA5-487A-AF23-658B1C00243F} /qn /norestart /passive
start /wait msiexec /x {0F929651-F516-4956-90F2-FFBD2CD5D30E} /qn /norestart /passive
start /wait msiexec /x {89C7E0A7-4D9D-4DCC-8834-A9A2B92D7EBB} /qn /norestart /passive
start /wait msiexec /x {9B56B031-A6C0-4BB7-8F61-938548C1B759} /qn /norestart /passive
start /wait msiexec /x {0C0F368E-17C4-4F28-9F1B-B1DA1D96CF7A} /qn /norestart /passive
start /wait msiexec /x {36AC0D1D-9715-4F13-B6A4-86F1D35FB4DF} /qn /norestart /passive
start /wait msiexec /x {03D562B5-C4E2-4846-A920-33178788BE00} /qn /norestart /passive
:: HP Connected Music
start /wait msiexec /x {8126E380-F9C6-4317-9CEE-9BBDDAB676E5} /qn /norestart /passive
:: HP PostScript Converter
start /wait msiexec /x {6E14E6D6-3175-4E1A-B934-CAB5A86367CD} /qn /norestart /passive
:: HP Registration Service
start /wait msiexec /x {D1E8F2D7-7794-4245-B286-87ED86C1893C} /qn /norestart /passive
:: HP SimplePass
start /wait msiexec /x {314FAD12-F785-4471-BCE8-AB506642B9A1} /qn /norestart /passive
:: HP Status Alerts
start /wait msiexec /x {9D1DE902-8058-4555-A16A-FBFAA49587DB} /qn /norestart /passive
:: Samsung SW Update (it disables Windows Update; very bad)
start /wait msiexec /x {AAFEFB05-CF98-48FC-985E-F04CD8AD620D} /qn /norestart /passive
:: Skype Click 2 Call
start /wait msiexec /x {6D1221A9-17BF-4EC0-81F2-27D30EC30701} /qn /norestart /passive
:: Toshiba ReelTime
start /wait msiexec /x {24811C12-F4A9-4D0F-8494-A7B8FE46123C} /qn /norestart /passive
:: Toshiba Book Place
start /wait msiexec /x {92C7DC44-DAD3-49FE-B89B-F92C6BA9A331} /qn /norestart /passive
:: Toshiba Value Added Package
start /wait msiexec /x {066CFFF8-12BF-4390-A673-75F95EFF188E} /qn /norestart /passive
:: Toshiba Wireless LAN Indicator
start /wait msiexec /x {CDADE9BC-612C-42B8-B929-5C6A823E7FF9} /qn /norestart /passive
:: Toshiba Bulletin Board
start /wait msiexec /x {C14518AF-1A0F-4D39-8011-69BAA01CD380}  /qn /norestart /passive
:: ESC Home Page Plugin
start /wait msiexec /x {E738A392-F690-4A9D-808E-7BAF80E0B398} /qn /norestart /passive
:: Unsure, was given this to remove something.
start /wait msiexec /x {173D1DA9-D107-4C85-B1DA-773DB53EEA6F} /qn /norestart /passive 

cls
color CF
echo. 
echo                       ___ ___ _  _ ___ ___ _  _ ___ ___  
echo                      ^| __^|_ _^| \^| ^|_ _/ __^| ^|^| ^| __^|   \ 
echo                      ^| _^| ^| ^|^| .` ^|^| ^|\__ \ __ ^| _^|^| ^|) ^|
echo                      ^|_^| ^|___^|_^|\_^|___^|___/_^|^|_^|___^|___/ 
echo.
echo                     time completed: %CUR_DATE% %TIME%

PAUSE>NUL
goto :EOF
:END
exit /b