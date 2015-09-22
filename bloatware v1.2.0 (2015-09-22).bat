:: Name:		bloatware v1.2.0 (2015-09-22).bat
:: Purpose:		Remove all bloatware on new PCs
:: Author:		George Slight
:: Revisions:	
:: Jan 2015 - initial version
:: Mar 2015 - Added more bloatware
:: Aug 2015 - Added more bloatware, and public release.
:: Sep 2015 - Added more bloatware, windows 8/10 support for removing metro apps
:: Sep 2015 - Big update, automatic updates to get the latest version of the script.
:: Sep 2015 - Another update, now added Temp File Cleanup.
@echo off

:: "its fucking beautiful works a treat on HP and Dell" -Manoj
:: "I just ran this script and now everything has been wiped off of my computer and my bank account is now empty… Thanks George!" -MattD

cls
color 0f
set SCRIPT_VERSION=1.2.0
set SCRIPT_DATE=2015-09-22
set TARGET_METRO=no
title BLOATWARE v%SCRIPT_VERSION% (%SCRIPT_DATE%)

set REPO_SCRIPT_DATE=0
set REPO_SCRIPT_VERSION=0

:: PREP: Update check
:: Use wget to fetch sha256sums.txt from the repo and parse through it. Extract latest version number and release date from last line (which is always the latest release)
wget.exe --no-check-certificate https://raw.githubusercontent.com/gslight/bloatware/master/sha256sums.txt -O sha256sums.txt 2>NUL
:: Assuming there was no error, go ahead and extract version number into REPO_SCRIPT_VERSION, and release date into REPO_SCRIPT_DATE
if /i %ERRORLEVEL%==0 (
	for /f "tokens=1,2,3 delims= " %%a in (sha256sums.txt) do set WORKING=%%b
	for /f "tokens=4 delims=,()" %%a in (sha256sums.txt) do set WORKING2=%%a
	)
if /i %ERRORLEVEL%==0 (
	set REPO_SCRIPT_VERSION=%WORKING:~1,6%
	set REPO_SCRIPT_DATE=%WORKING2%
	)


:: Notify if an update was found
SETLOCAL ENABLEDELAYEDEXPANSION
if /i %SCRIPT_VERSION% LSS %REPO_SCRIPT_VERSION% (
	set CHOICE=y
	color Cf
	cls
	echo.
	echo  ^^! A newer version of bloatware is available on the official repo.
	echo.
	echo    Your version:   %SCRIPT_VERSION% ^(%SCRIPT_DATE%^)
	echo    Latest version: %REPO_SCRIPT_VERSION% ^(%REPO_SCRIPT_DATE%^)
	echo.
	set /p CHOICE= Auto-download latest version now? [Y/n]:
	if !CHOICE!==y (
		color Cf
		cls
		echo.
		echo %TIME%   Downloading new version, please wait...
		echo.
		wget.exe --no-check-certificate -q "https://raw.githubusercontent.com/gslight/bloatware/master/bloatware%%20v%REPO_SCRIPT_VERSION%%%20(%REPO_SCRIPT_DATE%).bat" -O "bloatware v%REPO_SCRIPT_VERSION% (%REPO_SCRIPT_DATE%).bat"
		:: Wget breaks the title, fixing it here.
		title BLOATWARE %REPO_SCRIPT_VERSION% ^(%REPO_SCRIPT_DATE%^) now downloaded
		echo.
		echo %TIME%   Download finished. 
		ENDLOCAL DISABLEDELAYEDEXPANSION
		echo.
		:: Clean up after ourselves
		del /f /q sha256sums.txt
		del /f /q "bloatware v%SCRIPT_VERSION% (%SCRIPT_DATE%).bat"
		echo %TIME%   Please re-run the newest version %REPO_SCRIPT_VERSION% ^(%REPO_SCRIPT_DATE%^)
		echo.
		pause>NUL
		exit
		)
	)
	color 0f
)
cls
:: Wget breaks the title, fixing it here.
title BLOATWARE v%SCRIPT_VERSION% (%SCRIPT_DATE%)

:: Here we check if we want to cleanup temp files and download the latest script from github.

echo.
echo Would you like to download and cleanup temp files once the applications have been uninstalled?
echo.
set /P TempCleanup=Remove Temp Files - [Y]/n?
if /I %TempCleanup% NEQ "N" GOTO SKIPCLEANUP
:: Now we call wget to download TempFileCleanup.bat and then run it at the end.
wget.exe --no-check-certificate https://raw.githubusercontent.com/gslight/bloatware/master/TempFileCleanup.bat -O TempFileCleanup.bat 2>NUL

:: Wget breaks the title, fixing it here.
title BLOATWARE v%SCRIPT_VERSION% (%SCRIPT_DATE%)

: SKIPCLEANUP
:: PREP: Detect the version of Windows we're on. This determines a few things later in the script, such as whether or not to attempt removal of Windows 8/8.1 metro apps
set WIN_VER=undetected
for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName ^| Find "ProductName"') DO set WIN_VER=%%i %%j

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

:: Here we ask if we want to remove Office 2013 Click to run, as this is a bit of a bloatware - Waiting on a copy of the msiexec to start the install
cls
color CF
echo.
echo Would you like to remove Office 2013 Click-to-run (OEM) that normally comes with new PCs, this can take up on average around 1-2GB. However if you wish to install Office 2013 (OEM) on their PC at a later date you will have to redownload it from scratch again and depending on their internet speed this may take a while.
echo.              
SET /P RemoveOffice=Uninstall Office 2013 C2R [Y]/n?
IF /I "%RemoveOffice%" NEQ "N" GOTO START
echo.
:: Office 2013 C2R Suite
start /wait msiexec /x {90150000-0138-0409-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x "%ProgramData%\Microsoft\OEMOffice15\OOBE\x86\oemoobe.msi" /qn /norestart
cls

::::::::::::::::::::::::::
:: Interactive Removals ::
::::::::::::::::::::::::::
:START
color 0f
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
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C0300} /qn /norestart /passive
start /wait msiexec /x {86D4B82A-ABED-442A-BE86-96357B70F4FE} /qn /norestart /passive
:: McAfee Security Scan
"%ProgramFiles%\McAfee Security Scan\uninstall.exe" /S 2>NUL
"%ProgramFiles(x86)%\McAfee Security Scan\uninstall.exe" /S 2>NUL
:: Removes Live Essentials
start /wait msiexec.exe /x {FE044230-9CA5-43F7-9B58-5AC5A28A1F33} /qn /norestart /passive
"c:\program files (x86)\windows live\installer\wlarp.exe" /cleanup:all /q 2>NUL
"c:\program files\windows live\installer\wlarp.exe" /cleanup:all /q 2>NUL
:: Search Protect by Conduit
"C:\Program Files\SearchProtect\bin\uninstall.exe" /S 2>NUL
"C:\Program Files (x86)\SearchProtect\bin\uninstall.exe" /S 2>NUL
:: Remove AOL Toolbar
"C:\Program Files\AOL\AOL Toolbar 4.0\uninstall.exe" 2>NUL
"C:\Program Files (x86)\AOL\AOL Toolbar 4.0\uninstall.exe" 2>NUL
"C:\Program Files\AOL\AOL Toolbar 5.0\uninstall.exe" 2>NUL
"C:\Program Files (x86)\AOL\AOL Toolbar 5.0\uninstall.exe"  2>NUL
:: Remove Yahoo Toolbar
"C:\Program Files\Yahoo!\Common\unyt.exe" /S 2>NUL
RD "C:\Program Files\Yahoo!\" /S /Q 2>NUL
"C:\Program Files (x86)\Yahoo!\Common\unyt.exe" /S 2>NUL
RD "C:\Program Files (x86)\Yahoo!\" /S /Q 2>NUL
:: AVG Toolbars
"C:\Program Files\AVG SafeGuard toolbar\UNINSTALL.exe" /PROMPT /UNINSTALL 2>NUL
"C:\Program Files\AVG Secure Search\UNINSTALL.exe" /PROMPT /UNINSTALL 2>NUL
"C:\Program Files (x86)\AVG SafeGuard toolbar\UNINSTALL.exe" /PROMPT /UNINSTALL 2>NUL
"C:\Program Files (x86)\AVG Secure Search\UNINSTALL.exe" /PROMPT /UNINSTALL 2>NUL
:: BT Toolbar
"C:\Program Files (x86)\bttb\uninstall.exe" 2>NUL
"C:\Program Files\bttb\uninstall.exe" 2>NUL
:: Buenosearch Toolbar
"C:\Program Files (x86)\buenosearch LTD\buenosearch\1.8.28.7\GUninstaller.exe" -uprtc -ask "Bueno Toolbar" -rmbus "buenosearch toolbar" -nontfy -key "buenosearch" 2>NUL
"C:\Program Files\buenosearch LTD\buenosearch\1.8.28.7\GUninstaller.exe" -uprtc -ask "Bueno Toolbar" -rmbus "buenosearch toolbar" -nontfy -key "buenosearch" 2>NUL
:: removes Xobi
"C:\Program Files (x86)\Xobni\UninstallerWizard.exe" -uninstall 2>NUL
"C:\Program Files\Xobni\UninstallerWizard.exe" -uninstall 2>NUL
:: Browser Defender
"C:\ProgramData\BrowserDefender\2.6.1562.221\{c16c1ccb-1111-4e5c-a2f3-533ad2fec8e8}\uninstall.exe" /Uninstall /{15D2D75C-9CB2-4efd-BAD7-B9B4CB4BC693} /su=3a6664ea8d80382b /um 2>NUL
:: Search Protect by Conduit
"C:\Program Files\SearchProtect\bin\uninstall.exe" /S 2>NUL
"C:\Program Files (x86)\SearchProtect\bin\uninstall.exe" /S 2>NUL
:: SearchFlyBar2 Toolbar
"C:\Program Files\SearchFlyBar2\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\SearchFlyBar2\uninstall.exe" toolbar 2>NUL
:: FLV Runner Toolbar
"C:\Program Files\FLV_Runner\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\FLV_Runner\uninstall.exe" toolbar 2>NUL
"C:\Program Files\FLV_Runner_B2\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\FLV_Runner_B2\uninstall.exe" toolbar 2>NUL
"C:\Program Files\Begin-download_FLV_B2\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\Begin-download_FLV_B2\uninstall.exe" toolbar 2>NUL
:: xVidly4 Toolbar
"C:\Program Files\xvidly4\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\xvidly4\uninstall.exe" toolbar 2>NUL
:: BitTorrentControl_v12 Toolbar
"C:\Program Files (x86)\BitTorrentControl_v12\uninstall.exe" toolbar 2>NUL
"C:\Program Files\BitTorrentControl_v12\uninstall.exe" toolbar 2>NUL
:: Whittesmoke Toolbar
"C:\Program Files (x86)\WhiteSmoke_New\uninstall.exe" toolbar 2>NUL
"C:\Program Files\WhiteSmoke_New\uninstall.exe" toolbar 2>NUL
:: Easyfundraising Toolbar
"C:\Program Files (x86)\easyfundraising toolbar\tbunsy24A.tmp\uninstaller.exe" 2>NUL
"C:\Program Files\easyfundraising toolbar\tbunsy24A.tmp\uninstaller.exe" 2>NUL
:: Inbox Toolbar
"C:\Program Files\Inbox Toolbar\unins000.exe" /silent 2>NUL
"C:\Program Files (x86)\Inbox Toolbar\unins000.exe" /silent 2>NUL
:: ALOT Toolbar
"C:\Program Files\alot\alotUninst.exe" 2>NUL
"C:\Program Files (x86)\alot\alotUninst.exe" 2>NUL
:: browserTweeks Toolbar
"C:\Program Files\BrowserTweaks\IEScreenshot\unins000.exe" /silent 2>NUL
"C:\Program Files (x86)\BrowserTweaks\IEScreenshot\unins000.exe" /silent 2>NUL
:: Chatzum Toolbar
"C:\Program Files (x86)\ChatZum Toolbar\tbunsb9EE4.tmp\uninstaller.exe" 2>NUL
"C:\Program Files\ChatZum Toolbar\tbunsb9EE4.tmp\uninstaller.exe" 2>NUL
:: Data Toolbar 2.3.2
start /wait msiexec.exe /x {39238ce4-f7e3-4289-820d-4575907a2cad} /qn /norestart /passive
:: Facemoods Toolbar
"C:\Program Files (x86)\facemoods.com\facemoods\1.4.17.11\uninstall.exe" 2>NUL
"C:\Program Files\facemoods.com\facemoods\1.4.17.11\uninstall.exe" 2>NUL
:: Free_Game_ Bar_2
"C:\Program Files\Free_Game_Bar_2\uninstall.exe" 2>NUL
"C:\Program Files (x86)\Free_Game_Bar_2\uninstall.exe" 2>NUL
:: Games Bar A Toolbar
"C:\Program Files\Games_Bar_A\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\Games_Bar_A\uninstall.exe" toolbar 2>NUL
:: Incredibar Toolbar for IE
"C:\Program Files\Incredibar.com\incredibar\1.5.11.14\uninstall.exe" 2>NUL
"C:\Program Files\IncrediMail_MediaBar_2\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\Incredibar.com\incredibar\1.5.11.14\uninstall.exe" 2>NUL
"C:\Program Files (x86)\IncrediMail_MediaBar_2\uninstall.exe" toolbar 2>NUL
:: IE Toolbar 4.6 by Sweetpacks
start /wait msiexec.exe /x {c3e85ee9-5892-4142-b537-bceb3dac4c3d} /qn /norestart /passive
:: IsoBuster Toolbar
"C:\Program Files\IsoBuster\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\IsoBuster\uninstall.exe" toolbar 2>NUL
:: NCH Toolbar
"C:\Program Files\NCH\uninstall.exe" 2>NUL
"C:\Program Files (x86)\NCH\uninstall.exe" 2>NUL
:: Nectar Search Toolbars
"C:\Program Files\Nectar Search Toolbar\Uninst.exe" 2>NUL
"C:\Program Files (x86)\Nectar Search Toolbar\Uninst.exe" 2>NUL
:: Winzip Bar
"C:\Program Files\WinZipBar\uninstall.exe" 2>NUL
"C:\Program Files (x86)\WinZipBar\uninstall.exe" 2>NUL
:: PageRank Toolbar
"C:\Program Files\PageRage\uninstall.exe" 2>NUL
"C:\Program Files (X86)\PageRage\uninstall.exe" 2>NUL
:: Radio TV 2.1 Toolbar
"C:\Program Files\Radio_TV_2.1\uninstall.exe" 2>NUL
"C:\Program Files (x86)\Radio_TV_2.1\uninstall.exe" 2>NUL
:: TV Bar 2 B Toolbar
"C:\Program Files (x86)\TV_Bar_2_B\uninstall.exe" 2>NUL
"C:\Program Files\TV_Bar_2_B\uninstall.exe" 2>NUL
:: Radio Bar 1 Toolbar
"C:\Program Files\Radio_Bar_1\uninstall.exe" 2>NUL
"C:\Program Files (x86)\Radio_Bar_1\uninstall.exe" 2>NUL
:: StartNow Toolbar
"C:\Program Files (x86)\StartNow Toolbar\StartNowToolbarUninstall.exe" 2>NUL
"C:\Program Files\StartNow Toolbar\StartNowToolbarUninstall.exe" 2>NUL
:: Search Results Toolbar
"C:\Program Files (x86)\searchresults1\uninstall.exe" 2>NUL
"C:\Program Files\searchresults1\uninstall.exe" 2>NUL
:: Search-Results Toolbar
"C:\PROGRA~1\SEARCH~1\Datamngr\SRTOOL~1\uninstall.exe" 2>NUL
"C:\PROGRA~2\SEARCH~1\Datamngr\SRTOOL~1\uninstall.exe" 2>NUL
:: SearchQU Toolbar
"C:\Program Files\Searchqu Toolbar\uninstall.exe" 2>NUL
"C:\Program Files (x86)\Searchqu Toolbar\uninstall.exe" 2>NUL
"C:\Program Files (x86)\Windows searchqu Toolbar\uninstall.exe" 2>NUL
"C:\Program Files\Windows searchqu Toolbar\uninstall.exe" 2>NUL
:: Stumbleupon Toolbar
"C:\Program Files (x86)\StumbleUpon\uninstall.exe" 2>NUL
"C:\Program Files\StumbleUpon\uninstall.exe" 2>NUL
:: SmilboxEN Toolbar
"C:\Program Files (x86)\SmileBox_EN\uninstall.exe" 2>NUL
"C:\Program Files\SmileBox_EN\uninstall.exe" 2>NUL
:: Utorrent Toolbar
"C:\Program Files\uTorrentBar\uninstall.exe" 2>NUL
"C:\Program Files (x86)\uTorrentBar\uninstall.exe" 2>NUL
:: WiseConvert B Toolbar
"C:\Program Files\WiseConvert_B\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\WiseConvert_B\uninstall.exe" toolbar 2>NUL
:: Wise Convert B2 Toolbat for IE
"C:\ProgramData\Conduit\IE\CT3297951\UninstallerUI.exe" -ctid=CT3297951 -toolbarName=WiseConvert B2 -toolbarEnv=conduit -type=IE 2>NUL
:: WiseConvert Toolbar
"C:\Program Files\WiseConvert\uninstall.exe" 2>NUL
"C:\Program Files (x86)\WiseConvert\uninstall.exe" 2>NUL
:: xVidly4 Toolbar
"C:\Program Files (x86)\xvidly4\uninstall.exe" toolbar 2>NUL
"C:\Program Files\xvidly4\uninstall.exe" toolbar 2>NUL
:: YTD Toolbar V7.2
start /wait msiexec.exe /x {4bbd417f-13b6-4477-b7c2-ae705864058d} /qn /norestart /passive
:: YTD Toolbar V7.5
start /wait msiexec.exe /x {5af054b4-ee0f-4492-90b2-d82ea28e0711} /qn /norestart /passive
:: Zynga Toolbar
"C:\Program Files (x86)\Zynga\uninstall.exe" 2>NUL
"C:\Program Files\Zynga\uninstall.exe" 2>NUL
:: Web Accessibility Toolbar 2011
"C:\Program Files\WAT_EN\unins000.exe" /silent 2>NUL
"C:\Program Files (x86)\WAT_EN\unins000.exe" /silent 2>NUL
:: Web Accessibility Toolbar
"C:\Program Files\Accessibility_Toolbar\unins000.exe" /silent 2>NUL
"C:\Program Files (x86)\Accessibility_Toolbar\unins000.exe" /silent 2>NUL
:: Web Accessibility Toolbar 2013
"C:\Program Files (x86)\Accessibility_Toolbar\unins000.exe" /silent 2>NUL
"C:\Program Files\Accessibility_Toolbar\unins000.exe" /silent 2>NUL
:: Windows iLivid Toolbar
"C:\Program Files\Windows iLivid Toolbar\uninstall.exe" 2>NUL
"C:\Program Files (x86)\Windows iLivid Toolbar\uninstall.exe" 2>NUL
:: Movies Toolbar
"C:\PROGRA~2\MOVIES~1\Datamngr\SRTOOL~1\GC\uninstall.exe" /UN=CR /PID=^AG6 2>NUL
"C:\PROGRA~1\MOVIES~1\Datamngr\SRTOOL~1\FF\uninstall.exe" /UN=FF /PID=LVD2-DTX 2>NUL
"C:\PROGRA~1\MOVIES~1\Datamngr\SRTOOL~1\IE\uninstall.exe" /UN=IE /PID=LVD2-DTX 2>NUL
:: Babylon Toolbar (IE)
"C:\Program Files\BabylonToolbar\BabylonToolbar\1.5.3.17\uninstall.exe" 2>NUL
"C:\Program Files (x86)\BabylonToolbar\BabylonToolbar\1.5.3.17\uninstall.exe" 2>NUL
:: Babylon Toolbar
start /wait msiexec.exe /x {e55e7026-ef2a-4a17-aaa7-db98ea3fd1b1} /qn /norestart /passive
"C:\Program Files\BabylonToolbar\BabylonToolbar\1.8.4.9\GUninstaller.exe" -uprtc -key "BabylonToolbar" 2>NUL
"C:\Program Files (x86)\BabylonToolbar\BabylonToolbar\1.8.4.9\GUninstaller.exe" -uprtc -key "BabylonToolbar" 2>NUL
:: Delta Toolbar
"C:\Program Files\Delta\delta\1.8.21.5\GUninstaller.exe" -uprtc -ask -rmbus 'delta' -key "delta" 2>NUL
"C:\Program Files\Delta\delta\1.8.24.6\GUninstaller.exe" -uprtc -ask -rmbus "Delta toolbar" -nontfy -bname=dlt -key "delta" 2>NUL
"C:\Program Files (x86)\Delta\delta\1.8.21.5\GUninstaller.exe" -uprtc -ask -rmbus 'delta' -key "delta" 2>NUL
"C:\Program Files (x86)\Delta\delta\1.8.24.6\GUninstaller.exe" -uprtc -ask -rmbus "Delta toolbar" -nontfy -bname=dlt -key "delta" 2>NUL
:: POKKI (Desktop Apps and Game Installer)
"C:\Windows\system32\config\systemprofile\AppData\Local\Pokki\Uninstall.exe" 2>NUL
:: FLV Runner Toolbar
"C:\Program Files\FLV_Runner\uninstall.exe" toolbar 2>NUL
"C:\Program Files (x86)\FLV_Runner\uninstall.exe" toolbar 2>NUL
:: Productivity 3.1 B2 Toolbar
"C:\ProgramData\Conduit\IE\CT3297930\UninstallerUI.exe" -ctid=CT3297930 -toolbarName=Productivity 3.1 B2 -toolbarEnv=conduit -type=IE -origin=AddRemove -userMode=2 2>NUL
:: Nation Toolbar
"C:\Program Files\Nation Toolbar\tbunss2A93.tmp\uninstaller.exe" 2>NUL
"C:\Program Files (x86)\Nation Toolbar\tbunss2A93.tmp\uninstaller.exe" 2>NUL
:: MyToolbar
"C:\Program Files\My Toolbar\ATBPToolbar.1.0.Uninstall.exe" 2>NUL
"C:\Program Files (x86)\My Toolbar\ATBPToolbar.1.0.Uninstall.exe" 2>NUL
:: Connect DLC Toolbar for IE
"C:\ProgramData\Conduit\IE\CT3306061\UninstallerUI.exe" -ctid=CT3306061 -toolbarName=Connect DLC 5 -toolbarEnv=conduit -type=IE -origin=AddRemove -userMode=2 2>NUL
:: BrowserPlus2 Toolbar
"C:\ProgramData\Conduit\IE\CT3309350\UninstallerUI.exe" -ctid=CT3309350 -toolbarName=BrowserPlus2 -toolbarEnv=conduit -type=IE 2>NUL
:: Removes Coupon
"C:\Program Files\Coupons\uninstall.exe" "/U:C:\Program Files\Coupons\Uninstall\uninstall.xml" 2>NUL
"C:\Program Files (x86)\Coupons\uninstall.exe" "/U:C:\Program Files (x86)\Coupons\Uninstall\uninstall.xml" /S 2>NUL
"C:\Program Files (x86)\Coupon Printer\uninstall.exe" "/U:C:\Program Files (x86)\Coupon Printer\Uninstall\uninstall.xml" 2>NUL
"C:\Program Files\Coupon Printer\uninstall.exe" "/U:C:\Program Files\Coupon Printer\Uninstall\uninstall.xml" 2>NUL
:: Browser Good
"C:\Program Files (x86)\Browser Good\BrowserGooduninstall.exe" 2>NUL
:: Removes RegClean Pro
"C:\Program Files (x86)\RegClean Pro\unins000.exe" /silent 2>NUL
"C:\Program Files\RegClean Pro\unins000.exe" /silent 2>NUL
:: Removes Registry Mechanic
"C:\Program Files\PC Tools Registry Mechanic\unins000.exe" /SILENT 2>NUL
"C:\Program Files (x86)\PC Tools Registry Mechanic\unins000.exe" /SILENT 2>NUL
:: Removes Arcade Candy
"%UserProfile%\Local Settings\Application Data\ArcadeCandy\candyRemove.exe" 2>NUL
:: Removes PriceGong
"C:\Program Files\PriceGong\Uninst.exe" 2>NUL
"C:\Program Files (x86)\PriceGong\Uninst.exe" 2>NUL
:: Removes Smart Shopper
"C:\Program Files\ShopperReports3\bin\3.0.491.0\ShopperReportsUninstaller.exe" Web 2>NUL
"C:\Program Files (x86)\ShopperReports3\bin\3.0.491.0\ShopperReportsUninstaller.exe" Web 2>NUL
:: Removes Select Rebates
"C:\Program Files\SelectRebates\SelectRebatesUninstall.exe" 2>NUL
"C:\Program Files (x86)\SelectRebates\SelectRebatesUninstall.exe" 2>NUL
:: Candy
"%UserProfile%\Local Settings\Application Data\ArcadeCandy\candyRemove.exe"  2>NUL
:: Bubble Sound
"C:\Program Files\BubbleSound\Uninstall.exe" 2>NUL
:: Web Protector Plus
"C:\Program Files (x86)\WebProtectorPlus\uninstall.exe" 2>NUL
:: Baidu Antivirus
"C:\Program Files\Baidu Security\Baidu Antivirus\Uninstall.exe" 2>NUL
:: Freeze.com NetAssistant
start /wait msiexec.exe /X{C792A75A-2A1F-4991-9B85-291745478A79} /qn /norestart /passive
:: Nuance PDF Reader
start /wait MsiExec.exe /X{5F6C549F-78DA-4E0E-AE70-0BD981936D99} /qn /norestart /passive
:: InstallQ Updater
Start /wait MsiExec.exe /X{294A2E0E-3A0B-4D1F-8282-11DEF2040227} /qn /norestart /passive
:: System Checkup
"C:\Program Files\iolo\System Checkup\uninstscu.exe" /uninstall 2>NUL

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
	echo "%CUR_DATE% %TIME%    Windows 8/2012 detected, removing OEM Metro apps..."
	:: Force allowing us to start AppXSVC service. AppXSVC is the MSI Installer equivalent for "apps" (vs. programs)
		(
		net start AppXSVC
		:: Enable scripts in PowerShell
		powershell "Set-ExecutionPolicy Unrestricted -force 2>&1 | Out-Null"
		:: Call PowerShell to run the commands
		powershell "Get-AppXProvisionedPackage -online | Remove-AppxProvisionedPackage -online 2>&1 | Out-Null"
		powershell "Get-AppxPackage -AllUsers | Remove-AppxPackage 2>&1 | Out-Null"
		:: Running DISM cleanup against unused App binaries..."
		Dism /Online /Cleanup-Image /StartComponentCleanup
		)
)

:: Absolute Notifier // Absolute Reminder
start /wait msiexec /x {40F4FF7A-B214-4453-B973-080B09CED019} /qn /norestart /passive
start /wait msiexec /x {FB500000-0010-0000-0000-074957833700} /qn /norestart /passive

:: Acer Bluetooth Win7 Suite -64 7.2.0.56
start /wait msiexec /x {FCD6D60F-AF2B-49E3-ABC4-A4C96B56225D} /qn /norestart /passive

:: Accidental Damage Services Agreement
start /wait msiexec /x {EBE939ED-4612-45FD-A39E-77AC199C4273} /qn /norestart /passive

:: Acrobat.com (various versions)
start /wait msiexec /x {6D8D64BE-F500-55B6-705D-DFD08AFE0624} /qn /norestart /passive
start /wait msiexec /x {6978914A-A5AC-4F14-8158-DB66EE41E72B} /qn /norestart /passive
start /wait msiexec /x {287ECFA4-719A-2143-A09B-D6A12DE54E40} /qn /norestart /passive
start /wait msiexec /x {E7C97E98-4C2D-BEAF-5D2F-CC45A2F95D90} /qn /norestart /passive
start /wait msiexec /x {77DCDCE3-2DED-62F3-8154-05E745472D07} /qn /norestart /passive

:: Ad-Aware Web Companion (various versions) // Ad-Aware Updater
start /wait msiexec /x {88B10E3E-8911-4FAC-8663-CCF6E33C58B3} /qn /norestart /passive
start /wait msiexec /x {FABDFEBE-A430-48B4-89F2-B35594E43965} /qn /norestart /passive
start /wait msiexec /x {902C3D36-9254-437D-98AC-913B78E60864} /qn /norestart /passive

:: Adobe Bridge 1.0
start /wait msiexec /x {B74D4E10-1033-0000-0000-000000000001} /qn /norestart /passive

:: Adobe Content Viewer
start /wait msiexec /x {483A865C-A74A-12BF-1276-D0111A488F50} /qn /norestart /passive

:: Adobe Community Help
start /wait msiexec /x {A127C3C0-055E-38CF-B38F-1E85F8BBBFFE} /qn /norestart /passive

:: Adobe Common File Installer
start /wait msiexec /x {8EDBA74D-0686-4C99-BFDD-F894678E5B39} /qn /norestart /passive

:: Adobe Download Assistant
start /wait msiexec /x {5C804EBB-475F-4555-A225-1D6573F158BD} /qn /norestart /passive
start /wait msiexec /x {DE3A9DC5-9A5D-6485-9662-347162C7E4CA} /qn /norestart /passive

:: Adobe Help Center 1.0
start /wait msiexec /x {E9787678-1033-0000-8E67-000000000001} /qn /norestart /passive

:: Adobe Help Manager
start /wait msiexec /x {AF37176A-78CA-545B-34EF-8B6A21514DD1} /qn /norestart /passive
start /wait msiexec /x {ACEB2BAF-96DF-48FD-ADD5-43842D4C443D} /qn /norestart /passive

:: Adobe Media Player
start /wait msiexec /x {39F6E2B4-CFE8-C30A-66E8-489651F0F34C} /qn /norestart /passive

:: Adobe Refresh Manager
start /wait msiexec /x {AC76BA86-0804-1033-1959-001824147215} /qn /norestart /passive
start /wait msiexec /x {A2BCA9F1-566C-4805-97D1-7FDC93386723} /qn /norestart /passive
start /wait msiexec /x {AC76BA86-0804-1033-1959-001802114130} /qn /norestart /passive
start /wait msiexec /x {AC76BA86-0804-1033-1959-001824144531} /qn /norestart /passive

:: Adobe Setup (various versions)
start /wait msiexec /x {11A955CD-4398-405A-886D-E464C3618FBF} /qn /norestart /passive
start /wait msiexec /x {1D181764-DCD0-41B8-AA7B-0A599F027A72} /qn /norestart /passive
start /wait msiexec /x {7C548501-3501-468A-A443-CC42F5B3626B} /qn /norestart /passive

:: Adobe Widget Browser
start /wait msiexec /x {EFBE6DD5-B224-96E5-72B9-68D328CB12A6} /qn /norestart /passive

:: Advertising Center 0.0.0.2
start /wait msiexec /x {3784D297-8089-43B6-B57F-11B7E96413CD} /qn /norestart /passive

:: Alienware Customer Surveys
start /wait msiexec /x {13A3A271-B2AA-486C-9AD5-F272079BB9B5} /qn /norestart /passive

:: AlignmentUtility (various versions)
start /wait msiexec /x {4C5E314A-31CA-4223-9A90-CE0C4D5800A4} /qn /norestart /passive
start /wait msiexec /x {B0D59FDC-FEAB-49A2-9B5A-E5E0A8F9D7E0} /qn /norestart /passive

:: Amazon 1Button App 1.0.0.4
start /wait msiexec /x {134E190A-CE2A-4436-BDEB-387CC36A96C9} /qn /norestart /passive

:: AMD Accelerated Video Transcoding
start /wait msiexec /x {A6AFFBD8-D006-967F-51AF-0120F0261080} /qn /norestart /passive
start /wait msiexec /x {8642397F-CF08-6B30-A477-A039BBAA511E} /qn /norestart /passive
start /wait msiexec /x {9427FF53-EEF7-6D70-73AE-596A6B0CBC36} /qn /norestart /passive
start /wait msiexec /x {D77162FE-B7B2-8E1E-D80D-89DE6217DF13} /qn /norestart /passive
start /wait msiexec /x {BBA5B0EB-5746-C279-2A12-2AF046FD37CD} /qn /norestart /passive
start /wait msiexec /x {6F483F38-6162-7606-1D0B-054852C8E011} /qn /norestart /passive
start /wait msiexec /x {E7ACB435-E0B4-4770-77DE-ED38887CD133} /qn /norestart /passive
start /wait msiexec /x {ABD675FF-147C-689A-50B9-6DC57DE4044F} /qn /norestart /passive
start /wait msiexec /x {3BF3599D-7F28-C60B-1C5D-82BFD4E5EF33} /qn /norestart /passive
start /wait msiexec /x {D1822C34-F342-B6AA-6369-899C9D2A9227} /qn /norestart /passive

:: AMD Catalyst Control Center - Branding
start /wait msiexec /x {24D38277-CE6E-4E12-A2EE-F46832A4FA2F} /qn /norestart /passive

:: AMD Drag and Drop Transcoding (various versions)
start /wait msiexec /x {0336B81E-E745-7FE9-74D5-157EBCDF71E3} /qn /norestart /passive
start /wait msiexec /x {503F672D-6C84-448A-8F8F-4BC35AC83441} /qn /norestart /passive
start /wait msiexec /x {5D2B5E19-C333-4519-3D32-AAB8EEE9ACA4} /qn /norestart /passive
start /wait msiexec /x {D42B82F2-116E-8588-D868-5E98EF9B0CF8} /qn /norestart /passive
start /wait msiexec /x {FEA214BD-EE6F-B3B9-FE9E-80D2B14849D5} /qn /norestart /passive

:: AMD OEM Application Profile
start /wait msiexec /x {C89A97B6-F991-EBB5-77B7-927BCF420EBE} /qn /norestart /passive

:: AMD Problem Report Wizard  //  ATI Problem Report Wizard
start /wait msiexec /x {149FBD36-6E9E-2035-42B0-59D91714138D} /qn /norestart /passive
start /wait msiexec /x {8A079327-5B79-24B5-9E95-91960E763CB2} /qn /norestart /passive
start /wait msiexec /x {C36C7280-879A-D8A7-570F-844CB6E5F7E8} /qn /norestart /passive
start /wait msiexec /x {2E794F67-DAC1-C4A3-9128-0C841DF8A1BE} /qn /norestart /passive

:: AMD Wireless Display v3.0
start /wait msiexec /x {0A2E1907-D0DE-0D01-CA64-CB0AB0BFE539} /qn /norestart /passive
start /wait msiexec /x {426582A8-202F-D13C-8BD5-F00551BAFC93} /qn /norestart /passive
start /wait msiexec /x {630E5EF7-72F8-9E5D-BEF5-ED85B698E160} /qn /norestart /passive
start /wait msiexec /x {C16CD4C0-48EE-0F40-C9FD-0778EAF73FBD} /qn /norestart /passive
start /wait msiexec /x {D7C275A6-3266-0FBC-2D84-17A6AC226F01} /qn /norestart /passive
start /wait msiexec /x {ED273D26-E354-1A5B-A0D0-CB5258D43BD2} /qn /norestart /passive
start /wait msiexec /x {1D33EC42-4787-56CD-8137-95D8418FFEE8} /qn /norestart /passive

:: AOLIcon (lol)
start /wait msiexec /x {FFC7F03B-7069-4F7B-B0A5-9C173E898AC9} /qn /norestart /passive

:: ArcSoft Magic-i Visual Effects 2 // ArcSoft WebCam Companion 3 and 4 // Family Paint // WebCam Message Board
start /wait msiexec /x {B1893E3F-9BDF-443F-BED0-1AAA2D9E0D68} /qn /norestart /passive
start /wait msiexec /x {DE8AAC73-6D8D-483E-96EA-CAEDDADB9079} /qn /norestart /passive
start /wait msiexec /x {B77DE05C-7C84-4011-B93F-A29D0D2840F4} /qn /norestart /passive
start /wait msiexec /x {2B2F5B94-F377-41A2-8DA8-899BC538A4E1} /qn /norestart /passive
start /wait msiexec /x {7D44F1E8-968F-48D8-A966-2890A2CFFC6F} /qn /norestart /passive

:: Ashampoo Burning Studio FREE v.1.14.5
start /wait msiexec /x {91B33C97-91F8-FFB3-581B-BC952C901685} /qn /norestart /passive

:: Ask Toolbar
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C0300} /qn /norestart /passive
start /wait msiexec /x {86D4B82A-ABED-442A-BE86-96357B70F4FE} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C2201} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-006A-76A7-A758B70C0F01} /qn /norestart /passive
start /wait msiexec /x {9149AE79-3421-4A3A-834E-543948B045A2} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5637-4300-76A7-A758B70C0A00} /qn /norestart /passive

:: Ask Search App by Ask
start /wait msiexec /x {43C423D9-E6D6-4607-ADC9-EBB54F690C57} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5350-4500-76A7-A758B70C1500} /qn /norestart /passive
start /wait msiexec /x {4F524A2D-5350-4500-76A7-A758B70C2201} /qn /norestart /passive

:: ASPCA and CWA Reminder misc programs (we-care.com Macy's nagware)
start /wait msiexec /x {7E482AF6-AA1F-4CC5-BA13-0536675F5744} /qn /norestart /passive
start /wait msiexec /x {987F1753-1F42-4DF2-A5EA-0CCB777F3EB0} /qn /norestart /passive
start /wait msiexec /x {E4FB0B39-C991-4EE7-95DD-1A1A7857D33D} /qn /norestart /passive
start /wait msiexec /x {1F1E283D-23D9-4E09-B967-F46A053FEA89} /qn /norestart /passive
start /wait msiexec /x {0228288D-975E-42F7-9993-E91A82E6BBD9} /qn /norestart /passive
start /wait msiexec /x {6F5E2F4A-377D-4700-B0E3-8F7F7507EA15} /qn /norestart /passive
start /wait msiexec /x {B618B8E1-FB71-4237-8361-C3EA3EF15EF7} /qn /norestart /passive

:: ASUS Ai Charger
start /wait msiexec /x {7FB64E72-9B0E-4460-A821-040C341E414A} /qn /norestart /passive

:: ASUS WinFlash
start /wait msiexec /x {FFCF82EC-895F-4AC8-925E-3412FE25EF62} /qn /norestart /passive

:: Avery Toolbar
start /wait msiexec /x {8D20B4D7-3422-4099-9332-39F27E617A6F} /qn /norestart /passive

:: AVG 2014
start /wait msiexec /x {FC3B3A5D-7058-4627-9F1E-F95CC38B6054} /qn /norestart /passive
start /wait msiexec /x {524569AC-B3EE-468B-BFD5-19A89EA7CE8E} /qn /norestart /passive
start /wait msiexec /x {91569630-3DDC-43EB-9425-E6C41431D535} /qn /norestart /passive
start /wait msiexec /x {A64D4055-F3E5-40E7-982A-C1FC10C3B4AF} /qn /norestart /passive
start /wait msiexec /x {B53BE722-137D-4A7C-BC7A-F495DF36AF59} /qn /norestart /passive
start /wait msiexec /x {F4735E8D-3570-4606-A4E9-0BE44F3B0DFC} /qn /norestart /passive

:: AVG 2015
start /wait msiexec /x {3B3927B0-0A21-4B4C-9FF3-AB4C42E2AF79} /qn /norestart /passive
start /wait msiexec /x {966F007B-0D8A-44A6-A6C3-5395983C356D} /qn /norestart /passive
start /wait msiexec /x {0B7BE3CA-AF33-4CE3-BC27-1456C96EF996} /qn /norestart /passive
start /wait msiexec /x {7A5DB14B-14B0-4F09-A130-BF60503B4248} /qn /norestart /passive

:: Avira Launcher
start /wait msiexec /x {EA226E08-91E7-4F05-B61E-3EDBBBEB15BB} /qn /norestart /passive

:: AzureBay Screen Saver
start /wait msiexec /x {958A793F-F1D2-4A90-B6A5-C52E2D74E8FE} /qn /norestart /passive

:: Best Buy pc app
start /wait msiexec /x {FBBC4667-2521-4E78-B1BD-8706F774549B} /qn /norestart /passive
if exist "%ProgramData%\{D8EAE~1\Best Buy pc app Setup.msi" start /wait msiexec /x "%ProgramData%\{D8EAE~1\Best Buy pc app Setup.msi" /qn /norestart 2>NUL

:: Bing Bar, Bing Rewards Client Installer and Bing Bar Platform
start /wait msiexec /x {3365E735-48A6-4194-9988-CE59AC5AE503} /qn /norestart /passive
start /wait msiexec /x {C28D96C0-6A90-459E-A077-A6706F4EC0FC} /qn /norestart /passive
start /wait msiexec /x {77F8A71E-3515-4832-B8B2-2F1EDBD2E0F1} /qn /norestart /passive
start /wait msiexec /x {1AE46C09-2AB8-4EE5-88FB-08CD0FF7F2DF} /qn /norestart /passive
start /wait msiexec /x {49977584-B20E-46AB-818F-845815378904} /qn /norestart /passive
start /wait msiexec /x {A0BBC906-9A33-4C79-A26A-758ED3503769} /qn /norestart /passive
start /wait msiexec /x {1E03DB52-D5CB-4338-A338-E526DD4D4DB1} /qn /norestart /passive
start /wait msiexec /x {3611CA6C-5FCA-4900-A329-6A118123CCFC} /qn /norestart /passive
start /wait msiexec /x {61EDBE71-5D3E-4AB7-AD95-E53FEAF68C17} /qn /norestart /passive
start /wait msiexec /x {6ACE7F46-FACE-4125-AE86-672F4F2A6A28} /qn /norestart /passive
start /wait msiexec /x {B4089055-D468-45A4-A6BA-5A138DD715FC} /qn /norestart /passive
start /wait msiexec /x {A7E8CB11-B09E-46F8-9BAE-B2E01EBF7E51} /qn /norestart /passive

:: Bing Desktop
start /wait msiexec /x {7D095455-D971-4D4C-9EFD-9AF6A6584F3A} /qn /norestart /passive

:: Business Complete Care Services Agreement
start /wait msiexec /x {A3BE3F1E-2472-4211-8735-E8239BE49D9F} /qn /norestart /passive

:: Browser Address Error Redirector
start /wait msiexec /x {DF9A6075-9308-4572-8932-A4316243C4D9} /qn /norestart /passive

:: CA Pest Patrol Realtime Protection 001.001.0034
start /wait msiexec /x {F05A5232-CE5E-4274-AB27-44EB8105898D} /qn /norestart /passive

:: Camtasia (various versions)
start /wait msiexec /x {DB93E2C2-851F-44B2-B09C-351D2C624AE1} /qn /norestart /passive
start /wait msiexec /x {7A0735CD-5B9D-4FAF-A717-CF99619DDAF8} /qn /norestart /passive
start /wait msiexec /x {4974F6DC-BA3F-4708-9CF2-8F8B28A8E1C3} /qn /norestart /passive
start /wait msiexec /x {6D791152-409B-48C9-8050-E31D3B1CDDF0} /qn /norestart /passive
start /wait msiexec /x {008FD9E3-5F74-42FC-ACF9-B72AB7ED85E3} /qn /norestart /passive
start /wait msiexec /x {051E55AD-CCE1-4D3B-BA6A-88AD3F656C23} /qn /norestart /passive
start /wait msiexec /x {296C22B8-5355-4C13-B42B-C06B1A5D1B4E} /qn /norestart /passive
start /wait msiexec /x {21680605-EAEA-4A34-9C25-F44BB813CC3E} /qn /norestart /passive
start /wait msiexec /x {BC256BAA-A3D1-438F-ABE8-14E56FF6ECBA} /qn /norestart /passive
start /wait msiexec /x {FE95684E-62F9-49A1-988E-C88A123DBB18} /qn /norestart /passive
start /wait msiexec /x {BB62BAD9-AAAB-4552-B304-A3787EC2475B} /qn /norestart /passive
start /wait msiexec /x {94F167B1-395E-483C-9D12-20F077D7B4A9} /qn /norestart /passive
start /wait msiexec /x {EDBD11F4-45C8-4028-BC1A-FFE74DE37CB4} /qn /norestart /passive
start /wait msiexec /x {85BA4B05-A25A-4ABC-A637-14C1F7C6A1FA} /qn /norestart /passive
start /wait msiexec /x {2919BC46-3875-4175-A60E-71861076DE99} /qn /norestart /passive
start /wait msiexec /x {1875B4A0-974E-49C9-A817-99D14E19F5F8} /qn /norestart /passive
start /wait msiexec /x {F11EC76D-794E-4B72-BD73-4EC73498F4A8} /qn /norestart /passive
start /wait msiexec /x {D01C1100-5746-41C3-B309-29D674B92E2A} /qn /norestart /passive
start /wait msiexec /x {4325407D-1B78-475B-971A-7266BF17C293} /qn /norestart /passive
start /wait msiexec /x {0AC51B58-A50C-40F6-B991-523D730945DD} /qn /norestart /passive
start /wait msiexec /x {E42B58B2-D4A2-4632-8745-BFF041FBB4D9} /qn /norestart /passive
start /wait msiexec /x {2172CD50-F0DF-43D0-9C1F-7BD964D0289B} /qn /norestart /passive
start /wait msiexec /x {31591351-2BAE-4B88-8943-B18402D8112A} /qn /norestart /passive
start /wait msiexec /x {639B2D77-2476-4605-A5D7-8C5D816952C3} /qn /norestart /passive
start /wait msiexec /x {462A7AF7-6DCE-4609-97E4-A7BBE0B46DEF} /qn /norestart /passive
start /wait msiexec /x {F63723C9-BF65-4339-B98C-D6FC2A96182B} /qn /norestart /passive
start /wait msiexec /x {1884FF01-9F27-4D61-A6F2-85AA0A4B42A8} /qn /norestart /passive
start /wait msiexec /x {59D59A58-7421-4836-9E5C-6D39B005ED78} /qn /norestart /passive
start /wait msiexec /x {030EBB17-26C3-4C81-A14D-22AB5D2986EC} /qn /norestart /passive
start /wait msiexec /x {7E01BCC1-806C-4826-97E0-15426F0D1CC9} /qn /norestart /passive
start /wait msiexec /x {962C7B98-BEA8-45B9-8D56-2F3CBCA4F16B} /qn /norestart /passive
start /wait msiexec /x {DAC80429-24C7-44F9-828C-9740142FA620} /qn /norestart /passive
start /wait msiexec /x {95CF0C2A-6B62-4C11-A7BB-FD137CCCB0D6} /qn /norestart /passive
start /wait msiexec /x {DDBA1A68-E2A5-4C88-B96B-4F21DF964DED} /qn /norestart /passive
start /wait msiexec /x {2865F201-43B8-4CCC-9106-FE554F32138F} /qn /norestart /passive
start /wait msiexec /x {DE612AA6-7629-42F8-93CE-0D43A1BB5033} /qn /norestart /passive
start /wait msiexec /x {5EB67AA7-CC7C-4047-8A18-4B7D30FF8E5C} /qn /norestart /passive
start /wait msiexec /x {8C8AEE08-F427-452F-95B4-B36ECE4FADE3} /qn /norestart /passive
start /wait msiexec /x {F8492A18-EEBC-42B1-AF88-807BA37C43DA} /qn /norestart /passive
start /wait msiexec /x {D2756F6B-BC48-4792-8E3E-0B7053630B1D} /qn /norestart /passive
start /wait msiexec /x {71A6F5AA-EBDC-4BDF-B231-35B98FA3B9AE} /qn /norestart /passive
start /wait msiexec /x {8F0459D3-EEE8-414E-9CE1-36C00A19D507} /qn /norestart /passive
start /wait msiexec /x {CFBC28D9-F7D0-4725-871B-E8A22703ECCB} /qn /norestart /passive
start /wait msiexec /x {D3317ECB-5C48-4A6B-8C84-7457A9410159} /qn /norestart /passive
start /wait msiexec /x {BA14C68E-AEDC-4395-BB16-B3D365CF26AF} /qn /norestart /passive
start /wait msiexec /x {8073CD13-1B0E-446A-A678-9589A2EFFB92} /qn /norestart /passive
start /wait msiexec /x {1667846F-BC00-4CE6-ADA5-1CE122C33FE2} /qn /norestart /passive
start /wait msiexec /x {FB8A7032-9682-451E-9E64-89C25CD9E43B} /qn /norestart /passive
start /wait msiexec /x {DB25BCF6-2C58-473E-A2B6-6F77311F79D1} /qn /norestart /passive
start /wait msiexec /x {368C2E4B-A37E-466B-958E-C0CD6D6964F4} /qn /norestart /passive
start /wait msiexec /x {6E30B8A2-4AAA-487E-A80F-E147A9D084DD} /qn /norestart /passive
start /wait msiexec /x {8F4934B1-83CB-4BFC-8A90-40FF4530115D} /qn /norestart /passive
start /wait msiexec /x {A27DAE1A-995D-451F-9CCB-C7BF698E4ED4} /qn /norestart /passive
start /wait msiexec /x {D2F1FCB3-A65C-4BAA-A665-E498C9E80945} /qn /norestart /passive
start /wait msiexec /x {720F2C5A-DE7A-42A4-B08F-AD504B555155} /qn /norestart /passive
start /wait msiexec /x {64025BB4-168A-44E5-A10D-37D38A8E0124} /qn /norestart /passive
start /wait msiexec /x {870A52F4-A2EB-4187-97EA-654BD11A4C6C} /qn /norestart /passive
start /wait msiexec /x {40FEB178-1855-45A7-B988-F44F1FA896B7} /qn /norestart /passive
start /wait msiexec /x {222AB816-01E5-43B3-A10D-3F355FAAE513} /qn /norestart /passive
start /wait msiexec /x {8A3F916F-F9EB-469D-8C09-42273B8C1A66} /qn /norestart /passive
start /wait msiexec /x {AC89E267-9561-405B-B07F-DD5AAF92D042} /qn /norestart /passive
start /wait msiexec /x {CF9072B6-A82D-4E3E-8F3C-31614CB150EB} /qn /norestart /passive
start /wait msiexec /x {D4B7F322-6CFA-4CEE-AAE4-C5ADFA67F83C} /qn /norestart /passive
start /wait msiexec /x {933B3C90-AEA9-41EB-B555-6A38ADEC50A1} /qn /norestart /passive
start /wait msiexec /x {D85DD9A0-45CF-435B-98CB-144269DFE8A0} /qn /norestart /passive
start /wait msiexec /x {957B1FBE-BDB3-4BCC-A3D8-70A0E4A23360} /qn /norestart /passive
start /wait msiexec /x {6BDB867A-7975-40B5-93CE-11F133E1CDA9} /qn /norestart /passive
start /wait msiexec /x {6A1A98D3-E814-4E84-B683-69800993380B} /qn /norestart /passive
start /wait msiexec /x {7DB2CB6A-7248-4DC0-82FE-491D3570807E} /qn /norestart /passive
start /wait msiexec /x {2790A7CF-0EBD-4728-9364-6B63C5E680E3} /qn /norestart /passive
start /wait msiexec /x {B35C8CCE-95A1-45A4-BAB7-46154F60D8B2} /qn /norestart /passive
start /wait msiexec /x {80A19900-E0FA-425B-A1F6-0F7C013CE45A} /qn /norestart /passive
start /wait msiexec /x {6467DEB1-C20C-44F0-B25C-7A21F264D4F3} /qn /norestart /passive
start /wait msiexec /x {1EFB479B-C396-4E5B-BBB5-A845C59383CD} /qn /norestart /passive
start /wait msiexec /x {4786D940-0F26-43A4-98B5-4CAC01CD9FBE} /qn /norestart /passive
start /wait msiexec /x {D43CBD3F-F4CB-4780-A686-CFD3775FC2A1} /qn /norestart /passive
start /wait msiexec /x {ADC02977-F2BA-4F25-A550-B754562107A0} /qn /norestart /passive
start /wait msiexec /x {A1433F59-803E-4CFF-911D-847B22149A6B} /qn /norestart /passive
start /wait msiexec /x {5EE6CCD2-6142-4D09-8803-D31312574DC5} /qn /norestart /passive
start /wait msiexec /x {E729BCE1-294E-4364-8170-84036E7696E1} /qn /norestart /passive
start /wait msiexec /x {944321D8-225A-410E-932C-B8B219DF07D5} /qn /norestart /passive
start /wait msiexec /x {CD019882-E447-4F30-8FA4-521478BEE8E9} /qn /norestart /passive
start /wait msiexec /x {8F8BB210-4F82-4818-BF80-1CB57A62B996} /qn /norestart /passive
start /wait msiexec /x {8375085C-00D4-43EA-8E65-263E8C738E08} /qn /norestart /passive
start /wait msiexec /x {BCFE8F84-3EB8-40AD-B52F-F07B64F927AA} /qn /norestart /passive
start /wait msiexec /x {2FD5A4CA-421B-4C9E-952B-EA5B98B40AC3} /qn /norestart /passive
start /wait msiexec /x {85B51189-8F56-4338-9928-E1BFD7DB9211} /qn /norestart /passive
start /wait msiexec /x {3614C95F-1376-4551-BDED-EC6B79E74D60} /qn /norestart /passive
start /wait msiexec /x {967635DD-BA84-45AC-82EC-908D415B71A2} /qn /norestart /passive
start /wait msiexec /x {5E25963C-8033-4EC2-BDEA-0869E75611C7} /qn /norestart /passive
start /wait msiexec /x {9B8F134C-3A56-4365-A3FA-BD1824FD1B89} /qn /norestart /passive
start /wait msiexec /x {AD4F337C-7752-415A-9602-DF17B4F46E68} /qn /norestart /passive
start /wait msiexec /x {C7FDA25B-9A0F-487B-9502-35ABBF701599} /qn /norestart /passive
start /wait msiexec /x {BCBE985F-DE7D-41EA-A8AB-A575AEEDBDBD} /qn /norestart /passive
start /wait msiexec /x {823FCD0D-756D-44BE-A546-1D4D9FBBEA8C} /qn /norestart /passive
start /wait msiexec /x {990B884F-569C-5078-DD76-8BE91A569291} /qn /norestart /passive
start /wait msiexec /x {7D263751-40FB-D719-9F42-B62B67553D6F} /qn /norestart /passive
start /wait msiexec /x {BD37CF23-3458-BFD1-7583-F8FFC37561F2} /qn /norestart /passive
start /wait msiexec /x {931991F4-99D4-95A6-1235-EAA599884AC6} /qn /norestart /passive
start /wait msiexec /x {C2471823-76DB-B529-F037-8D02CAC5DE5E} /qn /norestart /passive
start /wait msiexec /x {1FAB6902-546D-9060-D0C8-4B502160AA06} /qn /norestart /passive
start /wait msiexec /x {DAE76FE1-BD65-3251-1B6F-6B519A661A1F} /qn /norestart /passive
start /wait msiexec /x {FE3E16F2-D838-7B5F-A31E-2D55757D18E7} /qn /norestart /passive
start /wait msiexec /x {BF34B28A-4D50-439A-6B6B-13EA41235E43} /qn /norestart /passive
start /wait msiexec /x {9E77F8EF-588E-D11B-697F-5514B97779DF} /qn /norestart /passive
start /wait msiexec /x {571F7B9B-96B8-E1B8-E198-0458BF5F80C4} /qn /norestart /passive
start /wait msiexec /x {3D516940-6675-41C1-E3DA-E3D358A7C207} /qn /norestart /passive
start /wait msiexec /x {0AB6726B-2C04-75E6-D30A-AA8C0E26E46A} /qn /norestart /passive
start /wait msiexec /x {3253D3E5-C08E-E22B-BA99-DE88F520CBB3} /qn /norestart /passive
start /wait msiexec /x {82EE309C-B63C-1AAA-79AB-8A5E5986B687} /qn /norestart /passive
start /wait msiexec /x {B9818C90-560C-8DC7-E254-38323B9A41EA} /qn /norestart /passive
start /wait msiexec /x {E7809829-3AC8-FBFA-2001-0D9BEBE51386} /qn /norestart /passive
start /wait msiexec /x {1D74451F-B220-E2E4-7FCD-520AA66F1A85} /qn /norestart /passive
start /wait msiexec /x {B740C369-EA8D-2FDB-4265-CB70DD08095D} /qn /norestart /passive
start /wait msiexec /x {2CC1453B-3385-F6FF-735F-F3BA36758715} /qn /norestart /passive
start /wait msiexec /x {F79997CC-F030-93C6-7882-92DC241D7C07} /qn /norestart /passive
start /wait msiexec /x {7540EB6A-FE9B-4EE2-37D9-A88DC87AA9E6} /qn /norestart /passive

:: Catalyst Control Center - Branding
start /wait msiexec /x {FB90923E-F94F-4343-A084-F0AB39305C8B} /qn /norestart /passive
start /wait msiexec /x {01E6CFB0-2EAA-A019-7894-18986696E711} /qn /norestart /passive
start /wait msiexec /x {0C37C41C-3BD1-256C-3C82-B5C707776249} /qn /norestart /passive
start /wait msiexec /x {104A2DA8-93BF-00B1-D6F5-97F83340F272} /qn /norestart /passive
start /wait msiexec /x {19145121-B4FB-D7DF-2900-16E96E8C8E83} /qn /norestart /passive
start /wait msiexec /x {1FE5BFA8-C0E0-68FD-52DD-42FB11B3B160} /qn /norestart /passive
start /wait msiexec /x {21AEC16B-1C21-81B4-DA88-2235CC1F7E39} /qn /norestart /passive
start /wait msiexec /x {2480B673-194C-3C4B-1523-4C20F354E40C} /qn /norestart /passive
start /wait msiexec /x {2726B6FF-D8F9-8F29-2A7D-8192AAE79D3F} /qn /norestart /passive
start /wait msiexec /x {30BF4E6C-D866-46F7-A4F6-81A45E97706E} /qn /norestart /passive
start /wait msiexec /x {358DF310-8B72-6178-4CDA-A6DB6616E477} /qn /norestart /passive
start /wait msiexec /x {36C0C3FC-6B7E-467A-81DB-6E4532B44374} /qn /norestart /passive
start /wait msiexec /x {3E275667-C19E-1AC0-A9EC-6D37AE67469C} /qn /norestart /passive
start /wait msiexec /x {544587B1-B057-F0B3-7B19-6898ADBED9AC} /qn /norestart /passive
start /wait msiexec /x {648B4A01-F609-1D4E-556C-0F18B54E9E1C} /qn /norestart /passive
start /wait msiexec /x {71E65D48-AC13-814E-413B-F31E142D11CE} /qn /norestart /passive
start /wait msiexec /x {A2DADCDD-694A-528E-C53B-A22B7C657039} /qn /norestart /passive
start /wait msiexec /x {CA89CAC3-0A6C-3B72-F48C-EABC2A84FCC9} /qn /norestart /passive
start /wait msiexec /x {CD05F1BC-FC63-1E93-4094-82BC33662E76} /qn /norestart /passive
start /wait msiexec /x {D9803478-F222-AC9C-48FB-1F4D6B54F1FF} /qn /norestart /passive
start /wait msiexec /x {DDD0527D-837F-5695-F2B7-941418FD9C01} /qn /norestart /passive
start /wait msiexec /x {E21A8F3C-1ACB-46B1-CE72-E9CF09549DED} /qn /norestart /passive
start /wait msiexec /x {E437ABBE-10E1-2CE5-F908-2FE8D611C88B} /qn /norestart /passive
start /wait msiexec /x {EB4901E9-48AE-0A2E-8747-1269A390B72D} /qn /norestart /passive

:: Catalyst Control Center Graphics Previews Common (various version numbers)
start /wait msiexec /x {190A9F41-85D0-CDB3-AA2D-A076D30953C9} /qn /norestart /passive
start /wait msiexec /x {AA725670-A7B4-D1B0-4EF5-F4B2E418C9F4} /qn /norestart /passive
start /wait msiexec /x {4841F481-1272-A1BE-D424-78628D252426} /qn /norestart /passive
start /wait msiexec /x {DCA43467-6F0F-CC7B-B944-F54AA1752BBE} /qn /norestart /passive
start /wait msiexec /x {B4205456-1F3F-7156-5EE2-DA1045FD7207} /qn /norestart /passive
start /wait msiexec /x {22139F5D-9405-455A-BDEB-658B1A4E4861} /qn /norestart /passive
start /wait msiexec /x {9C72C2F4-7DDE-9A3E-630D-BDAFFCFBD4B9} /qn /norestart /passive
start /wait msiexec /x {C7151D49-868B-B1F3-4E5D-ADA0E69FCB6E} /qn /norestart /passive
start /wait msiexec /x {49FE4B97-0E1E-F9EC-2123-4DFA80064694} /qn /norestart /passive
start /wait msiexec /x {E9A1960E-7756-2299-C700-DC7CA6EDD6E4} /qn /norestart /passive
start /wait msiexec /x {8452B997-80A4-B2F9-9CAD-00A3FA45AD92} /qn /norestart /passive
start /wait msiexec /x {A1ACD45F-0D8E-0566-0EC0-530CDCD7E8F4} /qn /norestart /passive
start /wait msiexec /x {DBA6B3EF-A8C0-4EB2-9554-3A7879838580} /qn /norestart /passive
start /wait msiexec /x {0F943E47-5762-2CBD-4762-ED2F2EB520F6} /qn /norestart /passive
start /wait msiexec /x {E63184B2-FA1E-F6AC-6CE3-E59DC4F1E3D4} /qn /norestart /passive
start /wait msiexec /x {19A492A0-888F-44A0-9B21-D91700763F62} /qn /norestart /passive
start /wait msiexec /x {E5441D19-417C-8C34-3F31-CCBD563C946E} /qn /norestart /passive
start /wait msiexec /x {568B558F-259C-1314-9D2E-E639179E6D33} /qn /norestart /passive
start /wait msiexec /x {6768141D-31CA-44E4-A827-8C95D22467F4} /qn /norestart /passive
start /wait msiexec /x {76582A2F-F5FD-BF58-C69F-1E9AB9CBDF6A} /qn /norestart /passive
start /wait msiexec /x {DCB72B24-65FC-C9E1-6E67-5C2E90339329} /qn /norestart /passive
start /wait msiexec /x {7A185D7D-6683-C6D6-8BDD-3D7E8AD9E618} /qn /norestart /passive
start /wait msiexec /x {BC5B6AD1-0581-3EB5-00FB-39A5203B7CA0} /qn /norestart /passive
start /wait msiexec /x {69D85106-CBD8-0F32-DD9E-7F39F5533E19} /qn /norestart /passive
start /wait msiexec /x {50BFCE80-042B-E53F-05EF-ACA0CC16A0DF} /qn /norestart /passive
start /wait msiexec /x {9A3F65CA-78FA-4749-004B-23743CF642D1} /qn /norestart /passive

:: CCC Catalyst Control Center multi-lingual Help files. Too many to individually list, Google each GUID for more info
start /wait msiexec /x {1E2ABB89-F7F3-8D64-3345-27E5735AA20C} /qn /norestart /passive
start /wait msiexec /x {990B884F-569C-5078-DD76-8BE91A569291} /qn /norestart /passive
start /wait msiexec /x {CD4005E4-E612-14BB-1BC4-636AE955D995} /qn /norestart /passive
start /wait msiexec /x {EB938F46-2780-1AF2-2579-A41EA96F8C1F} /qn /norestart /passive
start /wait msiexec /x {AA90CE8A-A77C-3CEB-DCD8-56DFDEDE808F} /qn /norestart /passive
start /wait msiexec /x {D05EA7FA-B112-103C-FBBE-8163B1B33A30} /qn /norestart /passive
start /wait msiexec /x {221BFD98-55F8-C64E-C2FA-56694133DB69} /qn /norestart /passive
start /wait msiexec /x {2904E0A2-B74F-EFAD-A523-46D0F64B3B4A} /qn /norestart /passive
start /wait msiexec /x {A8170CD1-F477-12A2-FCDE-E93759682F6F} /qn /norestart /passive
start /wait msiexec /x {8B5938FB-35EA-DF7F-E1FF-EB3E577E7125} /qn /norestart /passive
start /wait msiexec /x {F2569C93-029A-D00E-560F-40954008865B} /qn /norestart /passive
start /wait msiexec /x {9E77F8EF-588E-D11B-697F-5514B97779DF} /qn /norestart /passive
start /wait msiexec /x {99D70190-1870-B004-820B-6DCFD622703F} /qn /norestart /passive
start /wait msiexec /x {6DEE7496-3ED6-DE4C-9BEF-1E7F247CAAD1} /qn /norestart /passive
start /wait msiexec /x {27282E77-DB14-5769-2032-F381343DAA31} /qn /norestart /passive
start /wait msiexec /x {5CF1C22A-11DA-C6AC-7E66-289A858F5C46} /qn /norestart /passive
start /wait msiexec /x {CE24C50B-3A91-3880-4F4D-9EDD595E01DF} /qn /norestart /passive
start /wait msiexec /x {5C97100A-CBFA-F752-1CC4-8D59BB06DA51} /qn /norestart /passive
start /wait msiexec /x {5A1AE61E-393A-DE99-4733-AB36127B36F6} /qn /norestart /passive
start /wait msiexec /x {D33FFCDF-6B95-3586-F8B8-27CE5FF728C6} /qn /norestart /passive
start /wait msiexec /x {1D74451F-B220-E2E4-7FCD-520AA66F1A85} /qn /norestart /passive
start /wait msiexec /x {1D9F8C88-F76A-6B07-2276-98DF1173901B} /qn /norestart /passive
start /wait msiexec /x {086E1D65-EF19-280C-5616-7A87A6B95F88} /qn /norestart /passive
start /wait msiexec /x {2BC2EDB2-6F5C-3058-D312-B991AB26E870} /qn /norestart /passive
start /wait msiexec /x {1935505D-28FE-0FFE-9EB6-6AF73397C7BE} /qn /norestart /passive
start /wait msiexec /x {00CCB6C5-DD11-F614-5955-FACAFA2C80F7} /qn /norestart /passive
start /wait msiexec /x {01CD9E78-5D95-C7FB-EC23-64B39130EE31} /qn /norestart /passive
start /wait msiexec /x {020BA2C3-6D2E-78D0-9294-E4DDE937AE01} /qn /norestart /passive
start /wait msiexec /x {029C5BE5-462A-2FB8-5C54-362AFEEA7D44} /qn /norestart /passive
start /wait msiexec /x {031F80EB-1FE5-45EF-9DE2-E2F5AF01259F} /qn /norestart /passive
start /wait msiexec /x {03B2606F-6D79-81DD-6A43-88D7F00CDD09} /qn /norestart /passive
start /wait msiexec /x {049CA153-97D5-B668-E17D-EBA7D3B6FF2C} /qn /norestart /passive
start /wait msiexec /x {050FFD99-5C2F-9A1F-416E-AE0F4651CCB1} /qn /norestart /passive
start /wait msiexec /x {062ABD24-47F8-D865-BCB6-A724A94BC9A5} /qn /norestart /passive
start /wait msiexec /x {063B9998-A8C5-84A0-77A7-18F4844CF358} /qn /norestart /passive
start /wait msiexec /x {0655C185-FD48-5EBA-484A-CD530291F44D} /qn /norestart /passive
start /wait msiexec /x {06EC2942-D573-D6BD-3964-9D874353DDD7} /qn /norestart /passive
start /wait msiexec /x {070232F8-068B-1FF6-B5C4-F8F38E09C7E1} /qn /norestart /passive
start /wait msiexec /x {073AB210-9BDA-2F64-6B41-494F35C1E73F} /qn /norestart /passive
start /wait msiexec /x {0866F9CF-ABEA-0DCC-BF9F-29CE382B7D8D} /qn /norestart /passive
start /wait msiexec /x {092D7377-3DB8-B59E-7226-8B66AC437440} /qn /norestart /passive
start /wait msiexec /x {0A143C9B-DCE4-5089-E3DE-12BBCA178C12} /qn /norestart /passive
start /wait msiexec /x {0B15A8C3-3B8A-F229-A880-82EA62908425} /qn /norestart /passive
start /wait msiexec /x {0B23199B-B1CF-3D51-BB10-671DF99FC026} /qn /norestart /passive
start /wait msiexec /x {0BF79EF6-BD51-8FF9-35DE-290FBD97EC44} /qn /norestart /passive
start /wait msiexec /x {0CA35BA7-09C8-800A-7080-0F822D7096EF} /qn /norestart /passive
start /wait msiexec /x {0D3161D2-BFF2-1CD8-A951-EDFA4095DEEB} /qn /norestart /passive
start /wait msiexec /x {0E28CD09-29FD-119F-5544-815FBEBD69C2} /qn /norestart /passive
start /wait msiexec /x {0E786111-4DE4-FE39-FBDF-6BF28A318F7B} /qn /norestart /passive
start /wait msiexec /x {0F7BFF8F-274A-05FE-2D37-A0C644424871} /qn /norestart /passive
start /wait msiexec /x {0F8D819B-1AE4-E88B-1C03-610107019E30} /qn /norestart /passive
start /wait msiexec /x {0FBFA28A-C373-53BD-C553-58D6F6553D92} /qn /norestart /passive
start /wait msiexec /x {100E80FD-AAC1-89BA-B008-F1B8EBE7C668} /qn /norestart /passive
start /wait msiexec /x {104DE091-6C4F-C5A9-F619-5D6C965A0296} /qn /norestart /passive
start /wait msiexec /x {1078B6F2-93D7-FDB8-E8E2-84A61AB669CA} /qn /norestart /passive
start /wait msiexec /x {10F16BA8-BBEB-20C7-DF4D-22C6E19A9A80} /qn /norestart /passive
start /wait msiexec /x {110DE0FF-32D1-6203-ACDF-279DFA792DA1} /qn /norestart /passive
start /wait msiexec /x {115BAB0B-AB04-E481-76F5-82D90C3049A6} /qn /norestart /passive
start /wait msiexec /x {11E875AA-DF42-811E-96D9-5054A5A474B5} /qn /norestart /passive
start /wait msiexec /x {1205F38A-449D-D189-DA2C-812700240426} /qn /norestart /passive
start /wait msiexec /x {12ABA680-4BF6-E22B-0EEC-6E3D90B70635} /qn /norestart /passive
start /wait msiexec /x {12F80942-5FE0-7CE9-F1B3-121795A32054} /qn /norestart /passive
start /wait msiexec /x {13464292-6666-B2DB-1B0C-A3FE14DAD1F9} /qn /norestart /passive
start /wait msiexec /x {13FF5C00-EC03-D752-9302-141BE27B3C19} /qn /norestart /passive
start /wait msiexec /x {142C4779-8446-4458-3FC4-76195D41241C} /qn /norestart /passive
start /wait msiexec /x {14ADD362-A9D0-DB6D-6445-A99F8EDA5559} /qn /norestart /passive
start /wait msiexec /x {15030405-7B1E-7300-1C6C-9FE98BA68CB4} /qn /norestart /passive
start /wait msiexec /x {15412249-0AFA-D2A1-E7E2-E57AE1A96781} /qn /norestart /passive
start /wait msiexec /x {15775C9B-CD12-BDAF-F5FA-E06A7CB4F25D} /qn /norestart /passive
start /wait msiexec /x {18E58A5D-D8BD-EF4B-006A-104E5FE8CB13} /qn /norestart /passive
start /wait msiexec /x {1950EACB-6D88-F21E-4B25-26ECDD0C62A7} /qn /norestart /passive
start /wait msiexec /x {19EAB36E-A979-0870-F58F-6F4F34017D29} /qn /norestart /passive
start /wait msiexec /x {19F2D706-4834-2DD2-D12E-C10E75A57C81} /qn /norestart /passive
start /wait msiexec /x {1A30F95F-68D7-27DC-8C60-1A9A01EB2B50} /qn /norestart /passive
start /wait msiexec /x {1A4AABD1-8619-9747-3914-0B50A2B420EA} /qn /norestart /passive
start /wait msiexec /x {1A6752E1-966B-9D1F-F6B7-DDBCA6FC87ED} /qn /norestart /passive
start /wait msiexec /x {1B01541D-B1B8-8B7E-E82B-70551A1AF961} /qn /norestart /passive
start /wait msiexec /x {1BF82343-8EE6-8B76-90CF-31059B9D1842} /qn /norestart /passive
start /wait msiexec /x {1C22B23F-47AE-B9EC-8D40-1383B4CCA3E2} /qn /norestart /passive
start /wait msiexec /x {1CB8B169-534E-6F89-CDF9-0B812FBACF9A} /qn /norestart /passive
start /wait msiexec /x {1CDB842D-9C18-5EBC-91D4-C6F8DA0AE7CE} /qn /norestart /passive
start /wait msiexec /x {1DA0220A-454D-C668-763E-B232686FC505} /qn /norestart /passive
start /wait msiexec /x {1DE3F8C9-9F64-0F84-1512-06A15746C004} /qn /norestart /passive
start /wait msiexec /x {1E32C2AB-9722-5F41-7BDE-24B5AFD2BCE6} /qn /norestart /passive
start /wait msiexec /x {1E4062A9-EC7A-A6E9-348E-58B30D6EEADA} /qn /norestart /passive
start /wait msiexec /x {1F4B31CD-3824-5E93-060C-D333BFA36C6E} /qn /norestart /passive
start /wait msiexec /x {204F0053-6818-D50D-B132-55D5D0D1125D} /qn /norestart /passive
start /wait msiexec /x {2058DA53-D5F2-D8D9-7325-39B0E367D1E1} /qn /norestart /passive
start /wait msiexec /x {2070F457-B044-FCEE-B6DA-CB2C12CD76A5} /qn /norestart /passive
start /wait msiexec /x {2090B6D0-E025-5A67-9838-8F1D5768E643} /qn /norestart /passive
start /wait msiexec /x {210DD1FC-AAF8-4357-25FE-89E699BDB62E} /qn /norestart /passive
start /wait msiexec /x {2144B7B3-F251-6371-B2DB-071B9ECAC5A8} /qn /norestart /passive
start /wait msiexec /x {21CA031D-7805-5F8B-7A19-7954D5041A79} /qn /norestart /passive
start /wait msiexec /x {2226CEE6-E82A-AAD8-BA76-178734BBD484} /qn /norestart /passive
start /wait msiexec /x {222F2F2B-63FF-8B2C-05AE-8D418E66331B} /qn /norestart /passive
start /wait msiexec /x {224CA902-F494-FD2A-4211-771454ED464B} /qn /norestart /passive
start /wait msiexec /x {228CDD95-4069-8D94-7584-82BDE9A68B63} /qn /norestart /passive
start /wait msiexec /x {23AFE193-77EE-5A15-0FE2-1EA7407E0D53} /qn /norestart /passive
start /wait msiexec /x {243A6B8F-203D-EDAD-350D-15393AD822CD} /qn /norestart /passive
start /wait msiexec /x {244DFA33-CAE6-6D3A-BD58-B65EAD0AF73C} /qn /norestart /passive
start /wait msiexec /x {252FC4D1-4056-7237-6B19-4C66D0CF45A9} /qn /norestart /passive
start /wait msiexec /x {26070CDA-A7C5-2114-0533-38DE06C65E7F} /qn /norestart /passive
start /wait msiexec /x {267D591E-CC5C-9951-890A-97BD66717E30} /qn /norestart /passive
start /wait msiexec /x {2696556B-1D2B-26B3-75B1-52F342C150D0} /qn /norestart /passive
start /wait msiexec /x {2701BCE6-FAAF-7F58-5993-78D631439450} /qn /norestart /passive
start /wait msiexec /x {2746C43F-4D85-73C6-8ADC-C38453C3531E} /qn /norestart /passive
start /wait msiexec /x {27B201A5-A73B-1E7E-0C62-978A1B4A6696} /qn /norestart /passive
start /wait msiexec /x {285C9F30-3BF8-697B-BD1D-353435E94B78} /qn /norestart /passive
start /wait msiexec /x {288306FF-D5B5-7398-0617-E52F625C6797} /qn /norestart /passive
start /wait msiexec /x {28CA24E3-D323-3900-9519-4FFE9984EC53} /qn /norestart /passive
start /wait msiexec /x {29725F9E-027A-22DC-7B17-9413A5C5E51C} /qn /norestart /passive
start /wait msiexec /x {29967A7C-6E18-91CD-BBE4-9C09F401E950} /qn /norestart /passive
start /wait msiexec /x {2AD4FF67-43E9-77AD-D90C-584F950E2D12} /qn /norestart /passive
start /wait msiexec /x {2AF5D46E-6313-EC1D-1EA6-D542ECA0525A} /qn /norestart /passive
start /wait msiexec /x {2C0988B9-3BEA-7A45-2A67-BD0267973878} /qn /norestart /passive
start /wait msiexec /x {2CAF2C07-3219-8143-0E1C-EB1E20223171} /qn /norestart /passive
start /wait msiexec /x {2CB90FEE-EAAF-A572-72CF-014DDF5333F0} /qn /norestart /passive
start /wait msiexec /x {2CF48C8D-38F6-09E3-C24D-69999191726F} /qn /norestart /passive
start /wait msiexec /x {2D1C2307-58C4-86FC-CC3F-F8B5EAD52E5C} /qn /norestart /passive
start /wait msiexec /x {2DF4CDD9-C5BD-4DBB-3BB8-99E38D36BBBE} /qn /norestart /passive
start /wait msiexec /x {2E1BA46C-A45B-F2C8-1197-0CEB4EB77F70} /qn /norestart /passive
start /wait msiexec /x {2E5C47CE-9025-D797-8912-B3D7AC6AB5A0} /qn /norestart /passive
start /wait msiexec /x {2E85AE1F-7F71-4B34-5002-5B6CF42FEACC} /qn /norestart /passive
start /wait msiexec /x {2F5EB64A-814B-1884-DFEC-B30A212DCF2C} /qn /norestart /passive
start /wait msiexec /x {3042F44D-53BB-5430-64D3-550FE514A4BB} /qn /norestart /passive
start /wait msiexec /x {3088B508-7EE1-EC64-4FFD-C4901378CE7D} /qn /norestart /passive
start /wait msiexec /x {30F8E944-0BC9-9D90-D5DF-C606BAC6BD10} /qn /norestart /passive
start /wait msiexec /x {31DFAE28-8D77-B418-4217-AEB3396EAE82} /qn /norestart /passive
start /wait msiexec /x {31E4C3BB-2E7A-714B-65AF-2F8C711149E9} /qn /norestart /passive
start /wait msiexec /x {322DAA48-8F9B-FF15-2121-44E685B9F69F} /qn /norestart /passive
start /wait msiexec /x {32531CE8-014A-A2A4-C25A-DE9BA5B269F5} /qn /norestart /passive
start /wait msiexec /x {338CD56F-1CDC-CF32-33F6-DED2DF92284E} /qn /norestart /passive
start /wait msiexec /x {33BE1592-4175-7719-4604-5233D7434F92} /qn /norestart /passive
start /wait msiexec /x {33CDC947-0D8B-E2DB-FAED-A0026156F2B2} /qn /norestart /passive
start /wait msiexec /x {33E799D0-A9D7-E79E-1319-3B7EE918F946} /qn /norestart /passive
start /wait msiexec /x {3436866E-2C3A-AC6F-C6CF-1ABFF5FB69A3} /qn /norestart /passive
start /wait msiexec /x {344DE092-12CA-34F6-DD4D-0812340D9EF7} /qn /norestart /passive
start /wait msiexec /x {3528D412-5EEA-AAEA-AF64-9ADEE903D7D5} /qn /norestart /passive
start /wait msiexec /x {35E16D5D-3E57-4D32-47A9-4FFAFFB638BB} /qn /norestart /passive
start /wait msiexec /x {35EFBB88-4757-7F73-CDE7-D8B9E3819103} /qn /norestart /passive
start /wait msiexec /x {367EE587-F92B-E3E4-3816-99297A40751D} /qn /norestart /passive
start /wait msiexec /x {369F62CC-BAE9-CCDF-C4D3-8F2B3A398609} /qn /norestart /passive
start /wait msiexec /x {36A44ED0-1D3F-736D-9F06-D8685A9CFD79} /qn /norestart /passive
start /wait msiexec /x {375444C6-3CF6-B995-CDB0-F625C295E946} /qn /norestart /passive
start /wait msiexec /x {376F223B-0DF0-51E8-C51D-CA36F92914AE} /qn /norestart /passive
start /wait msiexec /x {3778B802-8E2C-04B0-2C1B-7C2A8F981824} /qn /norestart /passive
start /wait msiexec /x {39159BE7-2B24-D59B-18CF-878DFE0D9E32} /qn /norestart /passive
start /wait msiexec /x {3929A50B-9EEB-D8FC-1420-BD29DBD836BF} /qn /norestart /passive
start /wait msiexec /x {395B4CDF-79F3-C9ED-D869-DD4275298BFC} /qn /norestart /passive
start /wait msiexec /x {399D5E57-36C2-0856-77F4-5E06A4DF50EA} /qn /norestart /passive
start /wait msiexec /x {3A4C8B8E-AF20-25E1-35B8-2E8115BFC2B6} /qn /norestart /passive
start /wait msiexec /x {3A577334-7C90-55BC-1878-F5862FA268B2} /qn /norestart /passive
start /wait msiexec /x {3BE2E4AA-C164-FEB5-6C82-BBBC90C88915} /qn /norestart /passive
start /wait msiexec /x {3BF289E3-933B-F421-3B59-F6BB0D285B09} /qn /norestart /passive
start /wait msiexec /x {3C636207-EA73-E114-4FDE-39CA74F229F5} /qn /norestart /passive
start /wait msiexec /x {3C82A584-4651-2CE2-9E2D-F9B1F158CB8D} /qn /norestart /passive
start /wait msiexec /x {3CB6BA0C-6BC5-E543-221A-AA4DEBB6F4B5} /qn /norestart /passive
start /wait msiexec /x {3CBC0CD2-18F0-523D-DA6A-B224C3C4B2CF} /qn /norestart /passive
start /wait msiexec /x {3D06658D-C32D-CEAC-E92C-68CDFA13E21C} /qn /norestart /passive
start /wait msiexec /x {3D5238BD-B6F7-0325-4577-7B1DD3AC539F} /qn /norestart /passive
start /wait msiexec /x {3D8BC028-6977-2124-8314-A480AFD53C20} /qn /norestart /passive
start /wait msiexec /x {3DEDF1B0-B2A5-EDCE-F698-5C38B3717CA1} /qn /norestart /passive
start /wait msiexec /x {3E13E92F-464A-00D3-E497-FB7D4107B696} /qn /norestart /passive
start /wait msiexec /x {3E79966D-59AB-B5F5-19FD-898F4F0B5F32} /qn /norestart /passive
start /wait msiexec /x {3F5AF1A5-68C6-63B6-9550-B0BBDEFCA76F} /qn /norestart /passive
start /wait msiexec /x {40B415DD-63CB-7269-F7F8-BD2A06792785} /qn /norestart /passive
start /wait msiexec /x {41416465-D2EB-9DAC-8539-6339BB5A7436} /qn /norestart /passive
start /wait msiexec /x {4254F42D-4906-9791-A236-5DCC0096A896} /qn /norestart /passive
start /wait msiexec /x {430E2D32-6EA9-E6E4-80A1-84047694A45B} /qn /norestart /passive
start /wait msiexec /x {431EF42B-83EB-CD76-38D4-1DC2E4C044F4} /qn /norestart /passive
start /wait msiexec /x {44BD56AB-0427-EAAD-4E41-73192A7FE778} /qn /norestart /passive
start /wait msiexec /x {44D822AA-DA6D-1915-4B64-60D06AE613CE} /qn /norestart /passive
start /wait msiexec /x {44F7C005-42DF-B48D-5310-EDCCEBCD2CD0} /qn /norestart /passive
start /wait msiexec /x {46458556-5C46-79A9-A6FF-81DF1F8B2729} /qn /norestart /passive
start /wait msiexec /x {4690C2F0-0019-8675-DE47-2A842E44F988} /qn /norestart /passive
start /wait msiexec /x {4707D0D8-B9F3-255B-DD9F-D1C287DE8147} /qn /norestart /passive
start /wait msiexec /x {473B7FDE-3021-C9D2-9DB3-2B09DF840567} /qn /norestart /passive
start /wait msiexec /x {480C3278-56A7-3F05-3829-6DC5D4B0CB06} /qn /norestart /passive
start /wait msiexec /x {48614A34-564D-1F2B-7D2E-8814113BDEA8} /qn /norestart /passive
start /wait msiexec /x {48CA048A-3C5B-391E-7FF0-F36F434CB1B6} /qn /norestart /passive
start /wait msiexec /x {491C731F-F54D-864B-928D-436692D42133} /qn /norestart /passive
start /wait msiexec /x {4958364A-733A-D443-AF75-6880899AC7A4} /qn /norestart /passive
start /wait msiexec /x {49FD3CE5-1839-7EEA-D7D3-17A23826B859} /qn /norestart /passive
start /wait msiexec /x {4A6A8D33-09CD-FD44-4BF0-999E8A6E93C8} /qn /norestart /passive
start /wait msiexec /x {4B055C77-BC0F-623F-5A73-F7D5012987DB} /qn /norestart /passive
start /wait msiexec /x {4B6B8CE2-0E90-9108-1488-F70111AF8D8C} /qn /norestart /passive
start /wait msiexec /x {4CA4D9FC-212C-9F69-E760-DB4BEB34FEB5} /qn /norestart /passive
start /wait msiexec /x {4D7340CA-7D10-C5BC-4DA6-F3F685BAF0FF} /qn /norestart /passive
start /wait msiexec /x {4DE0D937-FEB0-0D89-C8D6-35F600300BD4} /qn /norestart /passive
start /wait msiexec /x {4E0C50EF-85BF-A1C0-307E-99473244B65F} /qn /norestart /passive
start /wait msiexec /x {4E81DBF0-CAB2-3EC7-18A3-0B0E8BA67FB9} /qn /norestart /passive
start /wait msiexec /x {4F01D33E-6FDF-2A63-8AD9-CBDC4735E80D} /qn /norestart /passive
start /wait msiexec /x {5175254C-4F5C-61DF-9647-306994652857} /qn /norestart /passive
start /wait msiexec /x {519D68B8-A768-4CDC-E4C9-B115D49CED93} /qn /norestart /passive
start /wait msiexec /x {51D383BC-D988-8C1E-FAA1-BC5260A32A87} /qn /norestart /passive
start /wait msiexec /x {526B6DD3-0C43-2C13-7DF8-44D20D4E9853} /qn /norestart /passive
start /wait msiexec /x {52FB1497-BBDD-F46F-2ADE-407148D63C65} /qn /norestart /passive
start /wait msiexec /x {5312A73B-4DA5-C48E-D15E-857E582A50E7} /qn /norestart /passive
start /wait msiexec /x {532B7184-DB64-3DB0-0312-611FFC288F7F} /qn /norestart /passive
start /wait msiexec /x {5377D0E6-0B77-5C94-A3F8-2A7C0E5791A1} /qn /norestart /passive
start /wait msiexec /x {5385F887-7F0F-8D37-4D52-677F7C928887} /qn /norestart /passive
start /wait msiexec /x {5402616A-ED3B-8FD4-9E3D-8A409178B524} /qn /norestart /passive
start /wait msiexec /x {54D05374-2428-7BE0-58CD-CE8031163DE6} /qn /norestart /passive
start /wait msiexec /x {54ED5964-9FEF-C9F8-F5D7-2663AFFD0C13} /qn /norestart /passive
start /wait msiexec /x {55B013D5-14E7-C0B1-CE42-9C567AAEE3C9} /qn /norestart /passive
start /wait msiexec /x {564F4D90-C0B0-A0B9-8C36-F19D28D6B861} /qn /norestart /passive
start /wait msiexec /x {571C0874-A931-EEFE-E89D-8F912F633B9F} /qn /norestart /passive
start /wait msiexec /x {58DBB034-F439-9FC4-361C-A990EA8CDA2D} /qn /norestart /passive
start /wait msiexec /x {59718697-4BCF-F43F-3E62-727C9ADE899C} /qn /norestart /passive
start /wait msiexec /x {597CE475-4F62-89EE-A81E-DB509DA0CBB2} /qn /norestart /passive
start /wait msiexec /x {597D764C-00A1-B174-33C2-93C9A4E73E21} /qn /norestart /passive
start /wait msiexec /x {59D0F36A-875A-BC78-2AF6-EC93CD24F6AA} /qn /norestart /passive
start /wait msiexec /x {5AF1BA3B-8B09-6459-4834-840E6B47BCFF} /qn /norestart /passive
start /wait msiexec /x {5BC757F1-5DE7-AD3C-81E8-81CAAC6D5889} /qn /norestart /passive
start /wait msiexec /x {5BF85137-0015-8591-E83C-EC121B2928AF} /qn /norestart /passive
start /wait msiexec /x {5BF8D06C-9B8C-085A-A093-DC5117108CD7} /qn /norestart /passive
start /wait msiexec /x {5C6AFE98-08BF-086A-300D-18F77D284966} /qn /norestart /passive
start /wait msiexec /x {5C757800-27E8-2AE3-889A-8B959AE689F8} /qn /norestart /passive
start /wait msiexec /x {5D3EC645-B957-36A1-068A-FE8450963669} /qn /norestart /passive
start /wait msiexec /x {5E2C8F1A-AC86-FBCD-B3E4-EBF9E747BC4D} /qn /norestart /passive
start /wait msiexec /x {5EE4A17C-DA9D-1A22-6D35-561BB29A38E6} /qn /norestart /passive
start /wait msiexec /x {5FE625A7-E8D6-2E41-4693-F6AC6310C467} /qn /norestart /passive
start /wait msiexec /x {610A0147-10AB-D148-B6E1-503E40A444B9} /qn /norestart /passive
start /wait msiexec /x {615B68AE-FDAF-937F-229C-10B77F039D55} /qn /norestart /passive
start /wait msiexec /x {61B90A4D-8CC9-2FED-2495-AC8C9467C984} /qn /norestart /passive
start /wait msiexec /x {624B2C5A-4343-E681-8BF7-838D792D8561} /qn /norestart /passive
start /wait msiexec /x {640D8EB2-3EBC-AFD7-7BE0-05C267EB39E2} /qn /norestart /passive
start /wait msiexec /x {641A5FC9-9B5C-6D83-AA49-FD2C967EF67F} /qn /norestart /passive
start /wait msiexec /x {6446F083-76CD-553B-8261-0E1297A7214C} /qn /norestart /passive
start /wait msiexec /x {64F18837-72CE-DC38-899C-260AF20F979A} /qn /norestart /passive
start /wait msiexec /x {65A472D0-CACC-38CD-65EE-426815ADC3D9} /qn /norestart /passive
start /wait msiexec /x {662A52A4-FE70-9435-47C6-30079DA87C01} /qn /norestart /passive
start /wait msiexec /x {662CB116-3477-ADD3-2C9D-5BC2806B1294} /qn /norestart /passive
start /wait msiexec /x {667E73A4-61C4-1224-B3A9-8A3B0422151E} /qn /norestart /passive
start /wait msiexec /x {66A42477-F80D-1A4F-08D8-D58697836EE5} /qn /norestart /passive
start /wait msiexec /x {674DAE26-3C3C-2D20-1BB4-82B380142E78} /qn /norestart /passive
start /wait msiexec /x {6756EE57-D98E-1EAD-B246-5AFFE2C6F63E} /qn /norestart /passive
start /wait msiexec /x {67A4760F-9804-CCF6-C319-27840ED77924} /qn /norestart /passive
start /wait msiexec /x {683081FF-DED0-CCB2-01C6-DEB1133DC7B1} /qn /norestart /passive
start /wait msiexec /x {6913316C-BD32-1A90-515F-D7B374FAF0B5} /qn /norestart /passive
start /wait msiexec /x {69850346-A30F-B771-3D3D-2FCB0E074992} /qn /norestart /passive
start /wait msiexec /x {69C82DDB-3FBC-EBEC-AE0A-3ABF1F3BD39B} /qn /norestart /passive
start /wait msiexec /x {6A376E3F-FBA3-6498-3B8D-B8D6169008D2} /qn /norestart /passive
start /wait msiexec /x {6A9EF47E-D49A-2EFC-20A1-A92DE7F826DF} /qn /norestart /passive
start /wait msiexec /x {6B79FF31-157D-14C5-E321-6AB2F7703A1D} /qn /norestart /passive
start /wait msiexec /x {6BE5E4A9-D88B-532D-26E6-883C32BF098A} /qn /norestart /passive
start /wait msiexec /x {6C4AD4F5-8560-4F1E-BC0C-7A883B695F6E} /qn /norestart /passive
start /wait msiexec /x {6CA2BE46-A562-8CA4-1C33-CC2681B2DDA1} /qn /norestart /passive
start /wait msiexec /x {6D6B211B-084E-030D-6160-F7926D3E84FA} /qn /norestart /passive
start /wait msiexec /x {6E2D214F-29AF-8A3F-61E2-531435A40949} /qn /norestart /passive
start /wait msiexec /x {6E2E52A3-DF0A-4EDC-B4F1-267E0FEC691B} /qn /norestart /passive
start /wait msiexec /x {6E594B4E-D394-BDEE-E9FF-4E6EBC30FB3A} /qn /norestart /passive
start /wait msiexec /x {6EBDE2A2-0CFB-9134-A859-68A0002B3FA6} /qn /norestart /passive
start /wait msiexec /x {6F076041-F337-5F67-75E7-6C1324D43EC6} /qn /norestart /passive
start /wait msiexec /x {6F7396CA-B0BA-AD24-83C8-4FF670291F48} /qn /norestart /passive
start /wait msiexec /x {6FB0A543-370D-AF7D-78E6-570FAA9D9AAD} /qn /norestart /passive
start /wait msiexec /x {708AEF44-AC54-8421-69E1-9FED4335FF18} /qn /norestart /passive
start /wait msiexec /x {722D6A37-C815-1945-1EE8-091348F3D388} /qn /norestart /passive
start /wait msiexec /x {72CCBA55-F7D7-C56F-7EB6-0A6EE4D3FDC0} /qn /norestart /passive
start /wait msiexec /x {75B9B936-BB09-B904-FE0F-52954DB68DAA} /qn /norestart /passive
start /wait msiexec /x {768012C6-AB93-3FDE-C3F6-6C0606948568} /qn /norestart /passive
start /wait msiexec /x {768A7F56-650B-F84F-DF95-EB1926AB5A8F} /qn /norestart /passive
start /wait msiexec /x {76B72651-1E7A-27C4-EAC6-81468BB968C2} /qn /norestart /passive
start /wait msiexec /x {780B8B1A-3BE2-CFB3-3B07-4C5938A4FE3F} /qn /norestart /passive
start /wait msiexec /x {78C07322-CA1D-98B6-14CE-476F125081B2} /qn /norestart /passive
start /wait msiexec /x {78E6BC53-F765-2629-C028-9F3CD49F70D4} /qn /norestart /passive
start /wait msiexec /x {796AC831-1AB8-711F-B770-A33DEA183440} /qn /norestart /passive
start /wait msiexec /x {7A9C67EF-05A8-499F-56A2-C467A4FE6DEE} /qn /norestart /passive
start /wait msiexec /x {7B07D38E-4952-A687-F360-4A177374F644} /qn /norestart /passive
start /wait msiexec /x {7C5B13DA-6A68-86C7-ED29-610CA0F49555} /qn /norestart /passive
start /wait msiexec /x {7CBFE744-729C-268F-CDF7-196E580AFF48} /qn /norestart /passive
start /wait msiexec /x {7CEAD718-2DFC-6AD9-E7D6-68D4668BEF60} /qn /norestart /passive
start /wait msiexec /x {7DA0C5CE-9817-CDB2-F061-F72D0CB6EEB3} /qn /norestart /passive
start /wait msiexec /x {7DB63154-92A4-12AE-364F-DE9C7B459720} /qn /norestart /passive
start /wait msiexec /x {7DD62206-7B6C-E32E-BD11-B49B3B089D16} /qn /norestart /passive
start /wait msiexec /x {7DDB0239-17CA-9552-5665-CA4845EB61B0} /qn /norestart /passive
start /wait msiexec /x {7E5568FC-FF2D-372E-2334-BB5079901F8B} /qn /norestart /passive
start /wait msiexec /x {7E56FAC8-B027-45A4-6723-FCE33A4281AE} /qn /norestart /passive
start /wait msiexec /x {7EEC0824-2AFB-570D-643F-3794B283FF3F} /qn /norestart /passive
start /wait msiexec /x {7F3B7E0B-0575-A74A-9F8F-F5B2349B3093} /qn /norestart /passive
start /wait msiexec /x {7F6F4427-27B9-B8D5-7CF7-0F6BFC2ABCE5} /qn /norestart /passive
start /wait msiexec /x {7F9EA30A-2DD4-81B6-8A08-719EB8683C40} /qn /norestart /passive
start /wait msiexec /x {7FA82763-D04B-A656-159B-BD8847176377} /qn /norestart /passive
start /wait msiexec /x {7FBD3794-1BA2-F0CB-57DD-AED6E6221AC6} /qn /norestart /passive
start /wait msiexec /x {8028C06A-E347-1E20-7DC4-8B18ACC7B130} /qn /norestart /passive
start /wait msiexec /x {80B875EF-04C3-9007-BB8E-1D60F32303BE} /qn /norestart /passive
start /wait msiexec /x {8181B50E-0E33-DE07-AAB2-E71BBBDBF288} /qn /norestart /passive
start /wait msiexec /x {81A84F7A-E4F4-84F2-8DB9-48D303F6D509} /qn /norestart /passive
start /wait msiexec /x {81EDA038-2320-B7E2-4D78-E12C2D55CE75} /qn /norestart /passive
start /wait msiexec /x {81F93FA5-BA87-322F-2166-4D1F0FFE196E} /qn /norestart /passive
start /wait msiexec /x {82796189-9C5E-A314-79B1-E8C32FD5EFC4} /qn /norestart /passive
start /wait msiexec /x {82C2F4FF-B768-12D6-E53D-62C8E17E8662} /qn /norestart /passive
start /wait msiexec /x {832C84C3-ADE3-31EF-9206-43EF77B098D6} /qn /norestart /passive
start /wait msiexec /x {83F8B662-32C3-D1B6-8048-35ED4B94DC87} /qn /norestart /passive
start /wait msiexec /x {843ECB1D-05D7-2A0F-38BF-37891DDF4E34} /qn /norestart /passive
start /wait msiexec /x {853A06A7-1FBA-F42A-3DBE-1E06E8B07510} /qn /norestart /passive
start /wait msiexec /x {8603EC92-211C-738F-0E1E-6A1F528728C5} /qn /norestart /passive
start /wait msiexec /x {86557367-811F-4C6D-05D8-9352FB75EA8D} /qn /norestart /passive
start /wait msiexec /x {8676226D-E23E-8701-778F-7DE0E12DA452} /qn /norestart /passive
start /wait msiexec /x {86C01B84-205E-B98D-11E5-94C5BEDC316A} /qn /norestart /passive
start /wait msiexec /x {86FB6880-0EE2-6EF4-7539-C0BCE7E5FA83} /qn /norestart /passive
start /wait msiexec /x {89A6150B-0CE8-AA44-F24B-FD8DCC058ACC} /qn /norestart /passive
start /wait msiexec /x {89A9984B-F134-3EE4-0790-1FBBF5E7CBF7} /qn /norestart /passive
start /wait msiexec /x {89CA8C53-9CE5-B628-AA17-11F232F1E726} /qn /norestart /passive
start /wait msiexec /x {89D8BC7A-7EDB-782A-10F9-49759C3BBC6E} /qn /norestart /passive
start /wait msiexec /x {8A368DA6-3814-A344-BB1E-C8EB69B865B6} /qn /norestart /passive
start /wait msiexec /x {8A4A81D1-9305-8B3D-1DC5-6DDCFE5C3973} /qn /norestart /passive
start /wait msiexec /x {8A640069-9784-701E-AC8E-84F62C42D1A3} /qn /norestart /passive
start /wait msiexec /x {8AA00ADE-A6AA-18A3-054B-A3B990DC41A0} /qn /norestart /passive
start /wait msiexec /x {8AA0FB20-9A21-56FF-8C4E-86732A070808} /qn /norestart /passive
start /wait msiexec /x {8AEE0BF9-A6A9-98E6-56B3-B14D2510B0D3} /qn /norestart /passive
start /wait msiexec /x {8AF6FD93-A657-8178-79B2-F925318CC1D3} /qn /norestart /passive
start /wait msiexec /x {8B619E05-80B3-20A1-5C1C-FDCDEC394344} /qn /norestart /passive
start /wait msiexec /x {8B8EE744-5D73-3AAC-52FB-43517C1CFA0B} /qn /norestart /passive
start /wait msiexec /x {8BC68157-FCCA-8D16-FCF8-9744A4DD8C0F} /qn /norestart /passive
start /wait msiexec /x {8CAD09D7-D021-1A49-E9D4-A3C07EAB06FC} /qn /norestart /passive
start /wait msiexec /x {8D0957A4-8EE7-E273-0BFC-9B235BEAA41A} /qn /norestart /passive
start /wait msiexec /x {8D2A81D8-AABF-673B-08BE-EF7A80295F14} /qn /norestart /passive
start /wait msiexec /x {8EE5C3FC-369F-5980-8F32-EB62771A43DF} /qn /norestart /passive
start /wait msiexec /x {8EFC331E-07A7-B196-7EA7-549A0CFE07CB} /qn /norestart /passive
start /wait msiexec /x {8FBCF2BD-063E-F861-A82D-F09191E9B7B9} /qn /norestart /passive
start /wait msiexec /x {90BA5BAB-4108-5CC7-8421-00EEAD6D51DF} /qn /norestart /passive
start /wait msiexec /x {9162CD39-6DD5-0624-6CC6-14806B5F9B8F} /qn /norestart /passive
start /wait msiexec /x {91D6CD01-358C-B88A-665E-2C0A59BF8FB1} /qn /norestart /passive
start /wait msiexec /x {91E8293B-C357-D092-8CCB-E19DA083D86C} /qn /norestart /passive
start /wait msiexec /x {923AF325-6007-1AAC-EB63-857A9592A9EC} /qn /norestart /passive
start /wait msiexec /x {93098E43-2743-1551-447F-2699E9591E9C} /qn /norestart /passive
start /wait msiexec /x {93870EF8-B00B-E5CD-00D6-301992AADD0A} /qn /norestart /passive
start /wait msiexec /x {949CCACC-A20F-0FB5-8A8E-C64773CBCF74} /qn /norestart /passive
start /wait msiexec /x {94C1F0A5-2DE9-98A6-8EC7-0DC8EAA9471B} /qn /norestart /passive
start /wait msiexec /x {951B0E3B-C10A-CC53-FE74-3B1BD78A843E} /qn /norestart /passive
start /wait msiexec /x {954680D5-B7C6-E5BA-9B62-09A5AB1F8022} /qn /norestart /passive
start /wait msiexec /x {95749C5B-BC37-41E3-8D39-EEF4C21A2825} /qn /norestart /passive
start /wait msiexec /x {9583AB6F-8E8B-C767-2A8F-09063A8F66AD} /qn /norestart /passive
start /wait msiexec /x {95919D2E-A36B-33DF-5F67-0DFB995750A3} /qn /norestart /passive
start /wait msiexec /x {95B8F519-8C35-9010-A63C-51B3E0EE8D4E} /qn /norestart /passive
start /wait msiexec /x {95CEC285-7B63-3D66-0B3F-EF0D9116375C} /qn /norestart /passive
start /wait msiexec /x {96140ACF-01DD-4DA9-4406-195B6A688ED6} /qn /norestart /passive
start /wait msiexec /x {96FC9301-FC68-BA30-4637-326BA0EF9027} /qn /norestart /passive
start /wait msiexec /x {9739158D-EDED-D628-9865-1460B5A7FAE3} /qn /norestart /passive
start /wait msiexec /x {97E33108-2206-087B-9399-29F5201AAC98} /qn /norestart /passive
start /wait msiexec /x {9809124C-0C4C-2367-7889-1E16D8EF1AAF} /qn /norestart /passive
start /wait msiexec /x {9919B071-F93A-8BFD-6A65-01D560121DC5} /qn /norestart /passive
start /wait msiexec /x {999DEF5D-E7F4-2C35-C579-8C77E80FEA47} /qn /norestart /passive
start /wait msiexec /x {99D7CAA1-BFBD-BBF6-A1C2-572FA1E7B439} /qn /norestart /passive
start /wait msiexec /x {99F4774B-2931-11FD-E747-FD8AD1BEA8AB} /qn /norestart /passive
start /wait msiexec /x {9A11B8B8-97EB-2966-21C4-AF9A675CCD0F} /qn /norestart /passive
start /wait msiexec /x {9A7DA27F-7ABA-8734-A966-6C8752929F3A} /qn /norestart /passive
start /wait msiexec /x {9B3CC933-5EF7-A868-7B74-1A227394566E} /qn /norestart /passive
start /wait msiexec /x {9BE678EF-1CDB-8FBE-9DC1-F0289F481C5B} /qn /norestart /passive
start /wait msiexec /x {9D3A232F-57E6-595E-1F77-637AFF16580C} /qn /norestart /passive
start /wait msiexec /x {9D7E098D-5693-D2F9-BBE5-4F5A56032FB4} /qn /norestart /passive
start /wait msiexec /x {9DE88E5C-AA88-FEE6-4D97-55494C5E132B} /qn /norestart /passive
start /wait msiexec /x {9E60B43A-50D6-057F-8EA6-8286CE00A65C} /qn /norestart /passive
start /wait msiexec /x {A15CC4B9-8429-E99D-DCF9-6C7789774D94} /qn /norestart /passive
start /wait msiexec /x {A1BBB15D-7A76-A03F-1593-8237E0BC0F63} /qn /norestart /passive
start /wait msiexec /x {A1F261C8-C63C-346C-C4D9-D497AA425F3C} /qn /norestart /passive
start /wait msiexec /x {A1FB4B86-129B-3C86-8DD8-440B60D50514} /qn /norestart /passive
start /wait msiexec /x {A1FE540C-114E-05D5-3334-1C25C38937C3} /qn /norestart /passive
start /wait msiexec /x {A282AFAB-F862-FF2E-44FB-22AA15E54AAA} /qn /norestart /passive
start /wait msiexec /x {A29C234F-F367-CEA0-1E8E-CB45F11445D8} /qn /norestart /passive
start /wait msiexec /x {A3232358-1FD7-973B-2D09-971C914CA8F8} /qn /norestart /passive
start /wait msiexec /x {A36CBCBC-10B5-EBC0-1219-95830657FF98} /qn /norestart /passive
start /wait msiexec /x {A3703A3B-FDCF-4349-4B2E-A189A2B90B51} /qn /norestart /passive
start /wait msiexec /x {A3806AB7-AB46-7672-A825-F9AE0DE6910A} /qn /norestart /passive
start /wait msiexec /x {A3A79AC5-63B0-F600-73CA-AC66239FA1A5} /qn /norestart /passive
start /wait msiexec /x {A3D1D38D-9C85-7BEB-5AC8-EC2D90E2882A} /qn /norestart /passive
start /wait msiexec /x {A440179F-D169-B9DA-B478-6CE97FDB3D4C} /qn /norestart /passive
start /wait msiexec /x {A60F4402-4CCE-E695-64C6-F0636ACC347F} /qn /norestart /passive
start /wait msiexec /x {A619A488-A4BA-F2A0-72FA-4C484B93DC0F} /qn /norestart /passive
start /wait msiexec /x {A63CF864-8A19-6FB2-2D18-C4AD48D1F161} /qn /norestart /passive
start /wait msiexec /x {A69EAF80-2710-6AD2-8515-2C27CE1B5802} /qn /norestart /passive
start /wait msiexec /x {A6E1EE9D-01DD-82FD-BDBC-193BCEF9FD5C} /qn /norestart /passive
start /wait msiexec /x {A79024ED-1969-334A-1ED6-16753F9DE377} /qn /norestart /passive
start /wait msiexec /x {A7CEA571-43AC-95FE-4F08-22C401FC2824} /qn /norestart /passive
start /wait msiexec /x {A7F248B5-B784-E149-124F-ABE878BC725F} /qn /norestart /passive
start /wait msiexec /x {A826CCC4-C0BA-97B4-F1DB-E68CD45D1133} /qn /norestart /passive
start /wait msiexec /x {A8A759FC-44FD-EBA6-8A18-F2F550DCEC83} /qn /norestart /passive
start /wait msiexec /x {A9F7150E-1426-9043-B97B-BAE039BC32F4} /qn /norestart /passive
start /wait msiexec /x {AB13F192-49FC-A065-F15C-746B10CC43C8} /qn /norestart /passive
start /wait msiexec /x {ABAB6355-CA0E-C46F-A0E6-82F3E19A33A2} /qn /norestart /passive
start /wait msiexec /x {AC53C6FB-C339-42EB-0F2D-746D3FE3B32C} /qn /norestart /passive
start /wait msiexec /x {ACA45C32-8432-2058-BE80-006E7908D804} /qn /norestart /passive
start /wait msiexec /x {ACB0E869-A344-C30E-D0DB-37AE9203917F} /qn /norestart /passive
start /wait msiexec /x {AD3A5061-3579-6600-6171-EEF6460CDDC7} /qn /norestart /passive
start /wait msiexec /x {ADBCAA59-C242-4B31-FF51-354159417118} /qn /norestart /passive
start /wait msiexec /x {ADCFBADB-040C-90AC-A2C5-EB71BAB0738B} /qn /norestart /passive
start /wait msiexec /x {AE548812-D611-608D-61C6-7E40F28573A2} /qn /norestart /passive
start /wait msiexec /x {AE72A9DF-CF98-6D61-841E-32EBD9A2A74E} /qn /norestart /passive
start /wait msiexec /x {AEF3AB2B-0B52-E47E-CA66-55E11D41EA04} /qn /norestart /passive
start /wait msiexec /x {AFA3730E-752C-4961-BE92-6667923C82B3} /qn /norestart /passive
start /wait msiexec /x {B024C404-F156-84BF-621D-629DF71E7456} /qn /norestart /passive
start /wait msiexec /x {B02AF4F2-1B8F-73B2-F097-03F2D0ABE221} /qn /norestart /passive
start /wait msiexec /x {B06A41D0-2F55-3AC0-14E7-2CE108273414} /qn /norestart /passive
start /wait msiexec /x {B079957C-3276-4B9F-DB08-D1CA8C090D9E} /qn /norestart /passive
start /wait msiexec /x {B15E6BBB-6AB4-3B2B-54AE-A1B874FA5469} /qn /norestart /passive
start /wait msiexec /x {B199030E-1082-F3BF-2BB9-0080D72876BD} /qn /norestart /passive
start /wait msiexec /x {B1AEF127-E01A-40D8-3CDC-F4C76BF2A42B} /qn /norestart /passive
start /wait msiexec /x {B32690A6-6C4A-D2E4-B5B7-F5F69241EB9A} /qn /norestart /passive
start /wait msiexec /x {B3A9A482-18D2-431B-EF33-FD62C86D3A86} /qn /norestart /passive
start /wait msiexec /x {B42A8EA7-2A15-2E30-651E-DD47C000301D} /qn /norestart /passive
start /wait msiexec /x {B462A229-4CCA-CD9F-D704-A888D0947DC1} /qn /norestart /passive
start /wait msiexec /x {B51AB07E-912A-B33B-323D-7F87EB15A357} /qn /norestart /passive
start /wait msiexec /x {B68D391C-32C6-798E-C78F-83C1797B162A} /qn /norestart /passive
start /wait msiexec /x {B74F087B-FE65-F00C-A756-538AF2B6B49E} /qn /norestart /passive
start /wait msiexec /x {B7B3C4FA-98FE-FEC7-073E-00677B8F0978} /qn /norestart /passive
start /wait msiexec /x {B7D77E59-3CBF-AEEE-3BB6-73F144CE2FCE} /qn /norestart /passive
start /wait msiexec /x {B898ABBB-4723-84B5-04C4-32A15F9DBD48} /qn /norestart /passive
start /wait msiexec /x {B8B66A0A-F2D1-6C12-28A6-8BE40EF745BA} /qn /norestart /passive
start /wait msiexec /x {B9259945-753D-A9AD-3133-E8900086902A} /qn /norestart /passive
start /wait msiexec /x {B976E52C-93A3-5CD1-FF67-658877850EDD} /qn /norestart /passive
start /wait msiexec /x {BA2A229A-11BB-BC94-A737-A995E56CCA57} /qn /norestart /passive
start /wait msiexec /x {BBB9D421-42DE-4553-0249-6A3E1FD991C8} /qn /norestart /passive
start /wait msiexec /x {BC63AEF9-1367-9F7C-5926-52E56450EDCD} /qn /norestart /passive
start /wait msiexec /x {BDD1D64B-3B7E-8BA4-0197-B307A14DFBA9} /qn /norestart /passive
start /wait msiexec /x {BE2548AA-9E21-F1C2-2FCF-C6F8E7477FAD} /qn /norestart /passive
start /wait msiexec /x {BEDC570A-C947-D0C8-3014-A1EAA042779D} /qn /norestart /passive
start /wait msiexec /x {BF5509A0-250A-25EA-0C19-61505E9EBA13} /qn /norestart /passive
start /wait msiexec /x {BF7B0100-A146-730D-367D-63BE6797BC81} /qn /norestart /passive
start /wait msiexec /x {C118B9C6-BCE5-629D-F9CF-F61BCAD285D9} /qn /norestart /passive
start /wait msiexec /x {C11D9D08-C2CE-942E-4C18-A47A98D41D3B} /qn /norestart /passive
start /wait msiexec /x {C125CF1B-32B7-A63B-4DBE-72555A1D4730} /qn /norestart /passive
start /wait msiexec /x {C1E2D27F-B363-588E-8859-9EF7F4EBF418} /qn /norestart /passive
start /wait msiexec /x {C223DA1D-4DA3-8F26-CAAD-C193A229F25B} /qn /norestart /passive
start /wait msiexec /x {C2E21D9B-8AD7-588F-9BE9-70054C864D20} /qn /norestart /passive
start /wait msiexec /x {C2EE0EA6-826F-63EA-8751-E2F3714DBA40} /qn /norestart /passive
start /wait msiexec /x {C313DD4D-3961-89F9-7457-443B1F6F28DF} /qn /norestart /passive
start /wait msiexec /x {C317E681-9114-153B-D8C5-F82F74DD33CA} /qn /norestart /passive
start /wait msiexec /x {C38F2DCF-CAA7-3C4C-680B-0DA98E638805} /qn /norestart /passive
start /wait msiexec /x {C39DBC22-001D-46B3-9B19-A181BBA6430D} /qn /norestart /passive
start /wait msiexec /x {C4464620-2BEC-AAE0-9462-7E97362EBC06} /qn /norestart /passive
start /wait msiexec /x {C45FB733-E259-A7FF-5C9F-4FC68CC69365} /qn /norestart /passive
start /wait msiexec /x {C4799AAA-CE52-D2F1-63C8-E6D5106C78E0} /qn /norestart /passive
start /wait msiexec /x {C4EE2BA3-EEA5-9650-86E0-0405ECA5C22C} /qn /norestart /passive
start /wait msiexec /x {C6113C72-D134-F23D-748B-B48C47C9C351} /qn /norestart /passive
start /wait msiexec /x {C6182116-5F2D-9949-B42B-06073E86A98A} /qn /norestart /passive
start /wait msiexec /x {C69EA753-0D3F-E48B-8C98-7F6310DC29B8} /qn /norestart /passive
start /wait msiexec /x {C6A344E9-6D72-560C-4A5E-93E6CA0EDDF7} /qn /norestart /passive
start /wait msiexec /x {C6B40F8E-7785-7585-A166-2D6C10A6ED6E} /qn /norestart /passive
start /wait msiexec /x {C740E6DF-2131-F63F-190D-C47791107254} /qn /norestart /passive
start /wait msiexec /x {C806408C-EFE8-22E3-0E3C-2680B4A31CDF} /qn /norestart /passive
start /wait msiexec /x {C94AAA8B-4152-3F32-E94E-E23503D21EAC} /qn /norestart /passive
start /wait msiexec /x {CB8F9326-774F-8800-DADE-51160D0C5B6F} /qn /norestart /passive
start /wait msiexec /x {CC6BAF1B-A73F-293B-802C-E221044C85BB} /qn /norestart /passive
start /wait msiexec /x {CC6C7F05-AF23-65BD-702D-705EAB723578} /qn /norestart /passive
start /wait msiexec /x {CDC8A707-DD65-E68B-6C0F-1C1F748DC4A8} /qn /norestart /passive
start /wait msiexec /x {CE8CEDD1-FCE6-F13D-D5BE-95D0EEDBC230} /qn /norestart /passive
start /wait msiexec /x {CF78008E-D6BC-399F-0FDB-AF94A39E427A} /qn /norestart /passive
start /wait msiexec /x {D10D4895-3630-B0A7-B575-7D1735E588A7} /qn /norestart /passive
start /wait msiexec /x {D298995C-4824-F44B-3EB7-035BD22B5190} /qn /norestart /passive
start /wait msiexec /x {D42498FB-9561-9575-C2AC-766F737F4ACF} /qn /norestart /passive
start /wait msiexec /x {D5B7F1A3-2CA6-4C5C-EFB6-4AA5772F5310} /qn /norestart /passive
start /wait msiexec /x {D6399FF6-7BDF-F604-E493-76B47CF59C15} /qn /norestart /passive
start /wait msiexec /x {D639E1C4-98AE-E960-5405-09614753781B} /qn /norestart /passive
start /wait msiexec /x {D64B1BF5-0057-BA0E-0A0F-38AE12520BD8} /qn /norestart /passive
start /wait msiexec /x {D69AF3B0-C06C-5F96-D855-DEB079847230} /qn /norestart /passive
start /wait msiexec /x {D6F32A43-1081-717E-1BD6-6168F5CA5035} /qn /norestart /passive
start /wait msiexec /x {D6F71904-5D85-4C9F-2131-B676459618D0} /qn /norestart /passive
start /wait msiexec /x {D7500D20-78EF-EBEE-C1EF-A9FA57297BDB} /qn /norestart /passive
start /wait msiexec /x {D76AC809-CCC1-6198-4970-A63FA5CF7DCB} /qn /norestart /passive
start /wait msiexec /x {D76F5B21-4C2C-9A2B-99ED-D018534C54A4} /qn /norestart /passive
start /wait msiexec /x {D814C606-0199-4A7D-D517-79DC2B3EB7F0} /qn /norestart /passive
start /wait msiexec /x {D889ECAE-D516-363D-0CEC-17F1D2E1AA81} /qn /norestart /passive
start /wait msiexec /x {D8F9F4CB-41A1-CF15-39A2-75F28E0B9991} /qn /norestart /passive
start /wait msiexec /x {D9199DDB-B5EE-BF67-7C85-31790A8B5D85} /qn /norestart /passive
start /wait msiexec /x {D95F9D89-65EF-CD20-4CB3-28293335CAE8} /qn /norestart /passive
start /wait msiexec /x {D963788E-2A2E-0673-A874-1F516B3861B1} /qn /norestart /passive
start /wait msiexec /x {DA05AADA-6407-9E45-7843-45F7393F7A15} /qn /norestart /passive
start /wait msiexec /x {DA675EE2-4C04-9699-0EE2-7EF9FE7AB870} /qn /norestart /passive
start /wait msiexec /x {DAE053AB-7E01-1F2B-F6A2-8BF124CF5266} /qn /norestart /passive
start /wait msiexec /x {DB4BD1F4-C444-3253-F1DC-CD9A11679960} /qn /norestart /passive
start /wait msiexec /x {DC0B9AC0-506D-C0C1-B22F-A2B16FED3D51} /qn /norestart /passive
start /wait msiexec /x {DC47D46D-8874-D83A-6612-9DA3175861B2} /qn /norestart /passive
start /wait msiexec /x {DCD2FE91-FFE7-7F08-F9E1-2CA4BDA00DF4} /qn /norestart /passive
start /wait msiexec /x {DD631F08-F0C4-B2EB-5620-D69E406B0391} /qn /norestart /passive
start /wait msiexec /x {DE6846F8-22E3-A581-E29A-61280F94B333} /qn /norestart /passive
start /wait msiexec /x {DF09BCD9-3556-77A6-8984-1CA95F8E1078} /qn /norestart /passive
start /wait msiexec /x {DF169640-259F-94BA-D667-44DAD367A57B} /qn /norestart /passive
start /wait msiexec /x {DF2567E1-8185-C90C-46EA-45069CB478FF} /qn /norestart /passive
start /wait msiexec /x {DF73BEDD-8A09-A6E2-462B-3BDF398BAFB2} /qn /norestart /passive
start /wait msiexec /x {E06F7C95-4D68-63D9-2231-AA5F8E186FCB} /qn /norestart /passive
start /wait msiexec /x {E0835E27-F4CE-6A1C-7B51-2BCF637F8C23} /qn /norestart /passive
start /wait msiexec /x {E0DE2996-A443-5FEA-30B7-9395E0F3A7CC} /qn /norestart /passive
start /wait msiexec /x {E277DDEB-9395-77FA-E273-A2BD084CEE0C} /qn /norestart /passive
start /wait msiexec /x {E2F52AC2-B925-C18F-E1AE-42FBD46ECAC7} /qn /norestart /passive
start /wait msiexec /x {E3E97F8C-1949-1FE1-D3A2-E2E61172A69B} /qn /norestart /passive
start /wait msiexec /x {E42C0921-20D7-24FA-D61D-8628BD44E551} /qn /norestart /passive
start /wait msiexec /x {E6041920-6D08-2466-E672-A15B040B5004} /qn /norestart /passive
start /wait msiexec /x {E7117563-58FF-5A50-664D-619DA8B5E3BF} /qn /norestart /passive
start /wait msiexec /x {E7284035-606E-00E1-155E-5B9A973C8CFA} /qn /norestart /passive
start /wait msiexec /x {E7535CDD-6B74-9268-C538-88B17FEEF6C0} /qn /norestart /passive
start /wait msiexec /x {E86271D2-CA95-3F92-6E6C-5037008B6006} /qn /norestart /passive
start /wait msiexec /x {E87A8D96-5795-A788-18A2-3BCC20B09E7C} /qn /norestart /passive
start /wait msiexec /x {E8EE10CF-31E4-CA63-BD94-B0157BBB2444} /qn /norestart /passive
start /wait msiexec /x {E9463114-898C-7C2A-2C47-E9ABC63F5D43} /qn /norestart /passive
start /wait msiexec /x {E9E50689-AE67-DAB4-310E-36A5BD2599D3} /qn /norestart /passive
start /wait msiexec /x {EA8CC2F2-BC30-141C-92B6-CC870B4B2977} /qn /norestart /passive
start /wait msiexec /x {EB295AF7-C2D1-D911-9E62-F288874B96F4} /qn /norestart /passive
start /wait msiexec /x {EB766D4A-C56C-946D-F74D-43C78FE4521E} /qn /norestart /passive
start /wait msiexec /x {EB9993A8-F5C4-C77A-2426-7AACB5D6946C} /qn /norestart /passive
start /wait msiexec /x {EBC36A11-EEC7-D07B-2A6A-B463057E2956} /qn /norestart /passive
start /wait msiexec /x {EBCD5E4C-F14A-B147-39FE-906F75AC4ACE} /qn /norestart /passive
start /wait msiexec /x {ECBA87BC-CF4F-9ECA-177C-B709BA6D524C} /qn /norestart /passive
start /wait msiexec /x {ECBBBDE9-E3B1-7C26-63C1-6D87309D2644} /qn /norestart /passive
start /wait msiexec /x {ED0D7699-1943-0C29-7465-6530F8DE2DA2} /qn /norestart /passive
start /wait msiexec /x {EDA37E8F-9CB3-6F5F-9E3B-63FF08C18792} /qn /norestart /passive
start /wait msiexec /x {EDA5BB56-AAF4-6889-AD8E-E25A17BD140B} /qn /norestart /passive
start /wait msiexec /x {EDEA3747-D395-AB89-7D3B-E497ACAA6FF3} /qn /norestart /passive
start /wait msiexec /x {EDFA892D-594D-C921-35FF-B6E5CFD2487C} /qn /norestart /passive
start /wait msiexec /x {EE590EC6-FC5D-A092-CD69-05F4FB38AD99} /qn /norestart /passive
start /wait msiexec /x {EE7DF38A-750E-FF7E-44FB-6335009442CB} /qn /norestart /passive
start /wait msiexec /x {EEF14371-2D24-5A2D-0EF2-22010DB4CFA6} /qn /norestart /passive
start /wait msiexec /x {EF1AB451-B478-78E3-F1D0-E3BCB5095C92} /qn /norestart /passive
start /wait msiexec /x {EF317D09-93BA-ABE1-AAF0-25BC2CC6AE5C} /qn /norestart /passive
start /wait msiexec /x {F127DA21-9A8D-1752-588E-12929E6C0F47} /qn /norestart /passive
start /wait msiexec /x {F15D95BE-2F78-9E92-2520-37DB0F685475} /qn /norestart /passive
start /wait msiexec /x {F1DD6B42-08C8-8491-C0F0-2296B6200EBE} /qn /norestart /passive
start /wait msiexec /x {F3688EEB-7274-6C61-E8A6-A91E163B5E04} /qn /norestart /passive
start /wait msiexec /x {F36D6137-FD4C-1F67-7B2A-815BB05BB825} /qn /norestart /passive
start /wait msiexec /x {F3C7FDC9-0B49-A5EC-7987-3C17D7045462} /qn /norestart /passive
start /wait msiexec /x {F421C17C-73AC-CB44-698F-6C125393E863} /qn /norestart /passive
start /wait msiexec /x {F4A6308C-55E6-57DF-95BB-AEEF374B469A} /qn /norestart /passive
start /wait msiexec /x {F4AFE9FD-82C1-AC56-63CA-5667CFF5353F} /qn /norestart /passive
start /wait msiexec /x {F56BBEB1-E982-0A07-0004-1CBC8E5B534E} /qn /norestart /passive
start /wait msiexec /x {F579CC33-014A-C84F-DD0F-C3157B7307DB} /qn /norestart /passive
start /wait msiexec /x {F600ED39-BA0C-A127-EAB7-057DF0A327E0} /qn /norestart /passive
start /wait msiexec /x {F62C60A3-2E8A-8108-2F87-5CDD5A4E3162} /qn /norestart /passive
start /wait msiexec /x {F69A7711-61C3-E5DB-EAFD-10C3216BF237} /qn /norestart /passive
start /wait msiexec /x {F6A55E40-3B9D-8024-EB0A-798E4AA9C744} /qn /norestart /passive
start /wait msiexec /x {F7175D1D-E905-B9C7-93E1-81F57AD160E7} /qn /norestart /passive
start /wait msiexec /x {F726BEEB-A0A7-778A-F55B-51C779C7848E} /qn /norestart /passive
start /wait msiexec /x {F7904AF8-BA7C-CF33-538F-CFB4B012FB3A} /qn /norestart /passive
start /wait msiexec /x {F7C43A36-54DF-4B6A-8198-B616B32AAFB1} /qn /norestart /passive
start /wait msiexec /x {F84C1DC6-4B39-1A34-AD6E-A6EE49A3DD78} /qn /norestart /passive
start /wait msiexec /x {F8FBF4C7-5ADA-66B1-6509-09E05C257963} /qn /norestart /passive
start /wait msiexec /x {F9048FF8-45E1-8BD4-0161-468F777BA2B4} /qn /norestart /passive
start /wait msiexec /x {F92E6F47-C50C-7115-4040-EDBEB34023BD} /qn /norestart /passive
start /wait msiexec /x {F93C6125-3F24-0EBA-4CC6-378AE2560861} /qn /norestart /passive
start /wait msiexec /x {F955A735-0DD7-8808-7881-B2ADAD0203DA} /qn /norestart /passive
start /wait msiexec /x {FA957EDD-031D-D6EF-BEC5-EA7544D4AD0B} /qn /norestart /passive
start /wait msiexec /x {FB3F7ACE-1633-5A41-250A-FA00E95EE402} /qn /norestart /passive
start /wait msiexec /x {FBE81DAC-D8EA-1B8B-C521-7FA39E83B515} /qn /norestart /passive
start /wait msiexec /x {FC00DD7E-8EBD-DAF9-B345-6643818AC242} /qn /norestart /passive
start /wait msiexec /x {FC18709C-C93F-6BF7-904A-43B0125725ED} /qn /norestart /passive
start /wait msiexec /x {FC1DCE80-2E83-A938-1450-A846B851E264} /qn /norestart /passive
start /wait msiexec /x {FD9C3389-A508-8F73-3B26-BDEB63671A3C} /qn /norestart /passive
start /wait msiexec /x {FDD69799-37B2-9ACE-F70C-ABD1F96FD04C} /qn /norestart /passive
start /wait msiexec /x {FDF2FE33-426D-45C2-4E70-76C162F1B790} /qn /norestart /passive
start /wait msiexec /x {FE1A4EA6-D680-DB6D-62CC-8C88CF85C1C5} /qn /norestart /passive
start /wait msiexec /x {FE59DF1D-F3DC-2B06-DF69-257890B220E3} /qn /norestart /passive
start /wait msiexec /x {FEFF81BF-B911-6755-FBDE-09547BDFD0A2} /qn /norestart /passive
start /wait msiexec /x {FF10AC4D-3349-99DA-3E58-5197CEA1D833} /qn /norestart /passive
start /wait msiexec /x {FFCF34B9-A0B1-2E2B-7D7E-8FAB4A781CC9} /qn /norestart /passive


:: CITIZEN bloatware (printer)
start /wait msiexec /x {546D97C7-9DF6-4A2D-BE02-2C0B25FFE1E3} /qn /norestart /passive
start /wait msiexec /x {39688AE1-0398-4133-942C-EECA9BBD64CC} /qn /norestart /passive

:: CLEART WiMAX Tutorial 1.5.0.10
start /wait msiexec /x {E289B7DD-6732-4333-A47A-75A145D23EE3} /qn /norestart /passive

:: Clickfree
start /wait msiexec /x {1EB9B986-CECA-4E05-B454-C9343EE9DDE7} /qn /norestart /passive

:: Comcast Desktop Software (v1.2.0.9) 23
start /wait msiexec /x {CEF7211D-CE3A-44C4-B321-D84A2099AE94} /qn /norestart /passive

:: Connect To Tech-Support (malware)
start /wait msiexec /x {A22B8513-EA8C-46A1-9735-F5BE971C368D} /qn /norestart /passive

:: Consumer In-Home Service Agreement
start /wait msiexec /x {F7DA7A20-8EC4-4960-95E5-5531D518B97E} /qn /norestart /passive

:: Corel DVD MovieFactory // Photo Album // WinDVD // Direct DiscRecorder
start /wait msiexec /x {1DF03ECE-6AF4-414E-B118-C316F151A9A2} /qn /norestart /passive
start /wait msiexec /x {5C1F18D2-F6B7-4242-B803-B5A78648185D} /qn /norestart /passive
start /wait msiexec /x {50F68032-B5B7-4513-9116-C978DBD8F27A} /qn /norestart /passive
start /wait msiexec /x {FC09380E-74BE-41F5-8353-E97113969040} /qn /norestart /passive

:: Coupon Network 12.10.2.4058
start /wait msiexec /x {6B66E18F-BC5C-47AC-A66C-9F0814A8A0EB} /qn /norestart /passive

:: Create Recovery Media 1.20.0.00
start /wait msiexec /x {C15914CB-2F62-4A58-86C1-69F90A2AA5EE} /qn /norestart /passive

:: CyberLink Blu-ray Disc Suite; CyberLink MediaEspresso shares this GUID
start /wait msiexec /x {1FBF6C24-C1FD-4101-A42B-0C564F9E8E79} /qn /norestart /passive

:: CyberLink MakeDisc
start /wait msiexec /x {0456ebd7-5f67-4ab6-852e-63781e3f389c} /qn /norestart /passive

:: CyberLink Media Suite 10
start /wait msiexec /x {8DE5BF1E-6857-47C9-84FC-3DADF459493F} /qn /norestart /passive

:: CyberLink MediaShow, MediaSmart DVD/Photo/Video
start /wait msiexec /x {E3739848-5329-48E3-8D28-5BBD6E8BE384} /qn /norestart /passive
start /wait msiexec /x {D12E3E7F-1B13-4933-A915-16C7DD37A095} /qn /norestart /passive
start /wait msiexec /x {80E158EA-7181-40FE-A701-301CE6BE64AB} /qn /norestart /passive
start /wait msiexec /x {6DAF8CDC-9B04-413B-A0F2-BCC13CF8A5BF} /qn /norestart /passive

:: CyberLink Power2Go
start /wait msiexec /x {2A87D48D-3FDF-41fd-97CD-A1E370EFFFE2} /qn /norestart /passive
start /wait msiexec /x {40BF1E83-20EB-11D8-97C5-0009C5020658} /qn /norestart /passive
start /wait msiexec /x {34D95765-2D5A-470F-A39F-BC9DEAAAF04F} /qn /norestart /passive

:: CyberLink PowerDVD
start /wait msiexec /x {D6E853EC-8960-4D44-AF03-7361BB93227C} /qn /norestart /passive
start /wait msiexec /x {DEC235ED-58A4-4517-A278-C41E8DAEAB3B} /qn /norestart /passive
start /wait msiexec /x {A8516AC9-AAF1-47F9-9766-03E2D4CDBCF8} /qn /norestart /passive
start /wait msiexec /x {CB099890-1D5F-11D5-9EA9-0050BAE317E1} /qn /norestart /passive
start /wait msiexec /x {2BF2E31F-B8BB-40A7-B650-98D28E0F7D47} /qn /norestart /passive
start /wait msiexec /x {B46BEA36-0B71-4A4E-AE41-87241643FA0A} /qn /norestart /passive

:: CyberLink PowerDirector // PowerProducer // PowerRecover
start /wait msiexec /x {607679B0-485D-45B0-A5FA-7464130FE570} /qn /norestart /passive
start /wait msiexec /x {B0B4F6D2-F2AE-451A-9496-6F2F6A897B32} /qn /norestart /passive
start /wait msiexec /x {F232C87C-6E92-4775-8210-DFE90B7777D9} /qn /norestart /passive
start /wait msiexec /x {B7A0CE06-068E-11D6-97FD-0050BACBF861} /qn /norestart /passive

:: CyberLink PhotoDirector // PhotoNow // PhotoShowExpress // PictureMover
start /wait msiexec /x {5A454EC5-217A-42a5-8CE1-2DDEC4E70E01} /qn /norestart /passive
start /wait msiexec /x {39337565-330E-4ab6-A9AE-AC81E0720B10} /qn /norestart /passive
start /wait msiexec /x {FC6C7107-7D72-41A1-A031-3CE751159BAB} /qn /norestart /passive
start /wait msiexec /x {4862344A-A39C-4897-ACD4-A1BED5163C5A} /qn /norestart /passive
start /wait msiexec /x {D36DD326-7280-11D8-97C8-000129760CBE} /qn /norestart /passive
start /wait msiexec /x {3250260C-7A95-4632-893B-89657EB5545B} /qn /norestart /passive
start /wait msiexec /x {1896E712-2B3D-45eb-BCE9-542742A51032} /qn /norestart /passive

:: CyberLink DX
start /wait msiexec /x {6811CAA0-BF12-11D4-9EA1-0050BAE317E1} /qn /norestart /passive

:: CyberLink PowerDirector 12
start /wait msiexec /x {E1646825-D391-42A0-93AA-27FA810DA093} /qn /norestart /passive

:: CyberLink Power Media Player 14
start /wait msiexec /x {32C8E300-BDB4-4398-92C2-E9B7D8A233DB} /qn /norestart /passive

:: CyberLink LabelPrint
start /wait msiexec /x {C59C179C-668D-49A9-B6EA-0121CCFC1243} /qn /norestart /passive

:: CyberLink YouCam
start /wait msiexec /x {A9CEDD6E-4792-493e-BB35-D86D2E188A5A} /qn /norestart /passive
start /wait msiexec /x {A81EB5BC-F764-308A-B979-0F8F078DAB29} /qn /norestart /passive
start /wait msiexec /x {01FB4998-33C4-4431-85ED-079E3EEFE75D} /qn /norestart /passive

:: Dell Access
start /wait msiexec /x {F839C6BD-E92E-48FA-9CE6-7BFAF94F7096} /qn /norestart /passive

:: Dell Backup and Recovery Manager
start /wait msiexec /x {975DFE7C-8E56-45BC-A329-401E6B1F8102} /qn /norestart /passive
start /wait msiexec /x {50B4B603-A4C6-4739-AE96-6C76A0F8A388} /qn /norestart /passive
start /wait msiexec /x {731B0E4D-F4C7-450C-95B0-E1A3176B1C75} /qn /norestart /passive
start /wait msiexec /x {AB2FDE4F-6BED-4E9E-B676-3DCCEBB1FBFE} /qn /norestart /passive
start /wait msiexec /x {43CAC9A1-1993-4F65-9096-7C9AFC2BBF54} /qn /norestart /passive
start /wait msiexec /x {97308CC9-FAED-4A1C-9593-64B2F1FD852D} /qn /norestart /passive
start /wait msiexec /x {4DEF2722-7EB8-4C5F-8F0A-0295A310002A} /qn /norestart /passive
start /wait msiexec /x {AE9EB677-66F4-40C0-9269-35067D8C555B} /qn /norestart /passive
rd /s /q %SystemDrive%\dell\dbrm 2>NUL

:: Dell Best of Web 1.00.0000
start /wait msiexec /x {BC8233D8-59BA-4D40-92B9-4FDE7452AA8B} /qn /norestart /passive

:: Dell CinePlayer 3
start /wait msiexec /x {39A6407B-DD99-410D-8EA2-280788F8423B} /qn /norestart /passive

:: Dell Client System Update (various versions)
start /wait msiexec /x {2B25AEE3-D191-4735-870E-28743D727ED8} /qn /norestart /passive
start /wait msiexec /x {03A9F528-A754-460F-B2C1-AC125A147114} /qn /norestart /passive

:: Dell Command | Power Manager 2.0.0
start /wait msiexec /x {DB82968B-57A4-4397-81A5-ECAB21B5DFCD} /qn /norestart /passive

:: Dell Command | Update 2.0.0
start /wait msiexec /x {E45D7941-F3F0-4E8E-AD55-DCE2FE0AE6D8} /qn /norestart /passive

:: Dell Control Point (various versions)
start /wait msiexec /x {0DB0EA38-E806-44ED-A892-489F2E305080} /qn /norestart /passive
start /wait msiexec /x {2E55EEFD-2162-4A7D-9158-EDB0305603A6} /qn /norestart /passive
start /wait msiexec /x {74F7662C-B1DB-489E-A8AC-07A06B24978B} /qn /norestart /passive
start /wait msiexec /x {24F2AD94-CC1B-4294-B184-D4D31A3186A7} /qn /norestart /passive
start /wait msiexec /x {4B3230C5-F069-416B-9169-1B84A216ED6A} /qn /norestart /passive

:: Dell ControlVault (various versions and components); this is Dell-branded biometric software
start /wait msiexec /x {693A23FB-F28B-4F7A-A720-4C1263F97F43} /qn /norestart /passive
start /wait msiexec /x {5905F42D-3F5F-4916-ADA6-94A3646AEE76} /qn /norestart /passive
start /wait msiexec /x {54C04D53-C3C3-46EA-A75F-7AFF4BEB727C} /qn /norestart /passive
start /wait msiexec /x {FEFDCDCF-C49C-45D0-AAF8-5345858ADEC7} /qn /norestart /passive
start /wait msiexec /x {6A7F4379-B2EE-444F-AC4A-C5379B1CF95E} /qn /norestart /passive
start /wait msiexec /x {815D96BA-2FC6-4F61-9BE3-2CFE446E8ECF} /qn /norestart /passive
start /wait msiexec /x {90B2EE35-59D0-4A1F-B125-9F678D46A955} /qn /norestart /passive
start /wait msiexec /x {8B5D0146-5187-40F5-9DD8-15DAF2D11902} /qn /norestart /passive

:: Dell Customer Connect 1.2.1.0
start /wait msiexec /x {FCD9CD52-7222-4672-94A0-A722BA702FD0} /qn /norestart /passive

:: Dell Data Protection (various versions and components)
start /wait msiexec /x {CCDF8E78-6102-470A-BBE4-9AF13694C716} /qn /norestart /passive
start /wait msiexec /x {04566294-A6B6-4462-9721-031073EB3694} /qn /norestart /passive
start /wait msiexec /x {7FA89EC8-023D-4AEA-94E2-32820FBBDC44} /qn /norestart /passive
start /wait msiexec /x {AC474F86-9A17-4BCB-8B15-11ABFD5B7F95} /qn /norestart /passive
start /wait msiexec /x {05FDD00D-1C45-44D1-AB3F-C24D45C39457} /qn /norestart /passive

:: Dell Data Services 1.2.7.0
start /wait msiexec /x {812AA6D3-5BEB-4577-88B1-00998B91AB41} /qn /norestart /passive

:: Dell Data Vault 1.1.0.6
start /wait msiexec /x {2B2B45B1-3CA0-4F8D-BBB3-AC77ED46A0FE} /qn /norestart /passive

:: Dell DataSafe Online (various versions)
start /wait msiexec /x {11F1920A-56A2-4642-B6E0-3B31A12C9288} /qn /norestart /passive

:: Dell Digital Content Portal
start /wait msiexec /x {C7FB1A71-D808-4CD2-997D-837B39EA7EB0} /qn /norestart /passive

:: Dell Digital Delivery (various versions)
start /wait msiexec /x {2A0F2CC5-3065-492C-8380-B03AA7106B1A} /qn /norestart /passive
start /wait msiexec /x {4688EB75-28E2-4731-9BCB-55E624F7CD45} /qn /norestart /passive
start /wait msiexec /x {B7FB9195-E9FC-4316-930E-D799D5D712F7} /qn /norestart /passive
start /wait msiexec /x {D605CD24-103D-4DB6-B572-653851213C46} /qn /norestart /passive
start /wait msiexec /x {B9CD9EC9-2566-4064-8599-4A3B742946F4} /qn /norestart /passive

:: Dell Dock 1.0.0
start /wait msiexec /x {F336F89D-8C5A-432C-8EA9-DA19377AD591} /qn /norestart /passive

:: Dell Dock 2
start /wait msiexec /x {C39A4E1F-9AF1-4FE1-A80E-A5B867FABB42} /qn /norestart /passive

:: Dell Driver Reset Tool 1.02.0000
start /wait msiexec /x {55E79447-F6B0-46CB-9F58-F82DAC9C2286} /qn /norestart /passive

:: Dell Feature Enhancement Pack 2.2.1
start /wait msiexec /x {98CB551E-EDB1-4535-82A6-E3258597F64E} /qn /norestart /passive

:: Dell Foundation Services (various versions)
start /wait msiexec /x {8E80AF23-17B4-4611-B28E-68A114B23488} /qn /norestart /passive
start /wait msiexec /x {CF5E8D60-A1FD-4BF2-9EDD-EA8C05F784A9} /qn /norestart /passive

:: Dell Getting Started Guide 1.00.0000
start /wait msiexec /x {7B7D73E7-79D5-4133-AB7A-E27BB5F64725} /qn /norestart /passive

:: Dell Help and Support Customization (hidden)
start /wait msiexec /x {4E5563B6-DE0A-4F3B-A5D6-15789FD12D9B} /qn /norestart /passive

:: Dell Home Systems Service Agreement 2.0.0
start /wait msiexec /x {AB2CED80-0F16-476F-8769-30A363562F16} /qn /norestart /passive

:: Dell mDrWifi
start /wait msiexec /x {90CC4231-94AC-45CD-991A-0253BFAC0650} /qn /norestart /passive
start /wait msiexec /x {A0F925BF-5C55-44C2-A4E7-5A4C59791C29} /qn /norestart /passive

:: Dell Mobile Broadband Utility 3.00.23.003
start /wait msiexec /x {C8B8C745-D288-41B4-9512-01E397F77449} /qn /norestart /passive

:: Dell Mobile Broadband Utility 3.00.96.007
start /wait msiexec /x {AA2AFD30-F80C-401C-9B85-03A05A2F7EFD} /qn /norestart /passive

:: Dell MusicStage 1.4.162.0
start /wait msiexec /x {EC542D5D-B608-4145-A8F7-749C02BE6D94} /qn /norestart /passive

:: Dell Music, Photos & Videos Launcher
start /wait msiexec /x {E4761915-C73A-4ef4-BB14-E380AB1D1CFB} /qn /norestart /passive

:: Dell My Dell Client Framework
start /wait msiexec /x {9CC89556-3578-48DD-8408-04E66EBEF401} /qn /norestart /passive

:: Dell Open Print Driver 1.31.7527.0
start /wait msiexec /x {B96348BD-6B0D-42E3-80B1-FA6718067BFE} /qn /norestart /passive

:: Dell PhotoStage 1.5.0.30
start /wait msiexec /x {E3BFEE55-39E2-4BE0-B966-89FE583822C1} /qn /norestart /passive

:: Dell Power Manager 1.1.0
start /wait msiexec /x {E4335E82-17B3-460F-9E70-39D9BC269DB3} /qn /norestart /passive

:: Dell Product Registration
start /wait msiexec /x {287348C8-8B47-4C36-AF28-441A3B7D8722} /qn /norestart /passive
start /wait msiexec /x {236F9DDF-B9BA-420A-9775-FBBA7B06475B} /qn /norestart /passive

:: Dell Protected Workspace 2.3.15835
start /wait msiexec /x {DDDAF4A7-8B7D-4088-AECC-6F50E594B4F5} /qn /norestart /passive

:: Dell Repository Manager v1.9.0 1.9.0
start /wait msiexec /x {2117290E-B7AD-4ACF-AEA4-3DE91A1063AF} /qn /norestart /passive

:: Dell Resource CD 1.00.0000
start /wait msiexec /x {F6CB42B9-F033-4152-8813-FF11DA8E6A78} /qn /norestart /passive

:: Dell Security Innovation TSS 2.1.42
start /wait msiexec /x {524C544D-2D53-5000-76A7-A758B70C2201} /qn /norestart /passive

:: Dell Solution Center 1.00.0000
start /wait msiexec /x {11DB380B-48CF-46EA-8B03-51874E2733C9} /qn /norestart /passive

:: Dell Support Center (various versions)
start /wait msiexec /x {E2CAA395-66B3-4772-85E3-6134DBAB244E} /qn /norestart /passive
start /wait msiexec /x {644B991F-B109-4360-9DA3-40CDAD13961C} /qn /norestart /passive

:: Dell SupportAssistAgent 1.1.0.47
start /wait msiexec /x {284D3B99-E8F5-4411-A7DD-7072EFCF3A46} /qn /norestart /passive

:: Dell System E-support Tool 2.2
start /wait msiexec /x {13766F76-6C8C-4E57-A9F3-3212D1C6E0D1} /qn /norestart /passive

:: Dell System Manager (various versions)
start /wait msiexec /x {0B72160B-9F67-47C0-858F-5A0074162148} /qn /norestart /passive
start /wait msiexec /x {C73A3942-84C8-4597-9F9B-EE227DCBA758} /qn /norestart /passive

:: Dell System Restore 2.00.0000
start /wait msiexec /x {7358D71A-DEFE-47DB-910A-B1CAC9C9D7C1} /qn /norestart /passive

:: Dell Trusted Drive Manager
start /wait msiexec /x {6AC87FB3-ACFC-4416-890C-8976D5A9B371} /qn /norestart /passive
start /wait msiexec /x {A093D83F-429A-4AB2-A0CD-1F7E9C7B764A} /qn /norestart /passive
start /wait msiexec /x {236EBEF4-8DE5-4E0E-8FD0-27D94F772FF0} /qn /norestart /passive
start /wait msiexec /x {98E68EAC-A3B3-4ECA-8110-84CBCFFF2878} /qn /norestart /passive
start /wait msiexec /x {DDD6BE8C-9AFA-48F1-A6AE-3BD596E2EB0B} /qn /norestart /passive

:: Dell Unified Wireless Suite 1.0.158
start /wait msiexec /x {D850CB7E-72BC-4510-BA4F-48932BFAB295} /qn /norestart /passive

:: Dell Update 1.7.1015.0
start /wait msiexec /x {DA24AEC5-5BD8-4248-AADE-16BB620E4E62} /qn /norestart /passive

:: Dell_DTM_X64 1.0.0.6
start /wait msiexec /x {FF79C05D-1E19-4FE5-BDD4-AAAFC28DDDDD} /qn /norestart /passive

:: Dell_SWEQ 1.0.0.4
start /wait msiexec /x {E95696A0-D7C9-4BEC-971E-FC2995DA2055} /qn /norestart /passive

:: DellAccess (various versions)
start /wait msiexec /x {20A4AA32-B3FF-4A0B-853C-ACDDCD6CB344} /qn /norestart /passive
start /wait msiexec /x {DC14FF2A-EB53-4093-847D-9314E9555BB6} /qn /norestart /passive

:: Dell Client System Update
start /wait msiexec /x {69093D49-3DD1-4FB5-A378-0D4DB4CF86EA} /qn /norestart /passive

:: Dell ControlPoint
start /wait msiexec /x {A9C61491-EF2F-4ED8-8E10-FB33E3C6B55A} /qn /norestart /passive

:: Dell ControlVault Host Components Installer
start /wait msiexec /x {5A26B7C0-55B1-4DA8-A693-E51380497A5E} /qn /norestart /passive

:: Dell Datasafe Online
start /wait msiexec /x {7EC66A95-AC2D-4127-940B-0445A526AB2F} /qn /norestart /passive

:: Dell Digital Delivery
echo Searching for Dell Digital Delivery
WMIC product where name="Dell Digital Delivery" call uninstall /nointeractive 2>NUL

:: Dell Dock
start /wait msiexec /x {E60B7350-EA5F-41E0-9D6F-E508781E36D2} /qn /norestart /passive

:: Dell DVDSentry
start /wait msiexec /x {5B54DDC3-0ACC-4722-9C23-C3F07AF4825D} /qn /norestart /passive

:: Dell Embassy Suite
start /wait msiexec /x {53333479-6A52-4816-8497-5C52B67ED339} /qn /norestart /passive
start /wait msiexec /x {5F5CBF39-BD29-43C8-B63A-B9758F0FD090} /qn /norestart /passive
start /wait msiexec /x {7EC46A4C-E659-418E-A65A-BD7FC82D4C48} /qn /norestart /passive
start /wait msiexec /x {8055B6B2-4BF1-4A0B-849C-941EA5A16044} /qn /norestart /passive
start /wait msiexec /x {131A2659-99A9-4A89-B012-22A898EAE9DA} /qn /norestart /passive

:: Dell Feature Enhancement Pack
start /wait msiexec /x {992D1CE7-A20F-4AB0-9D9D-AFC3418844DA} /qn /norestart /passive

:: Dell Getting Started Guide
start /wait msiexec /x {7DB9F1E5-9ACB-410D-A7DC-7A3D023CE045} /qn /norestart /passive

:: Dell misc help and support GUIDs
start /wait msiexec /x {9EDA3DD1-130D-4EE1-A3D2-5A3D795CC8C9} /qn /norestart /passive

:: Dell Power Manager
start /wait msiexec /x {CAC1E444-ECC4-4FF8-B328-5E547FD608F8} /qn /norestart /passive

:: Dell Protected Workspace
echo Searching for Dell Protected Workspace
wmic product where name="Dell Protected Workspace" call uninstall /nointeractive 2>NUL

:: Dell QuickSet32 and QuickSet64
start /wait msiexec /x {ED2A3C11-3EA8-4380-B59C-F2C1832731B0} /qn /norestart /passive
start /wait msiexec /x {C4972073-2BFE-475D-8441-564EA97DA161} /qn /norestart /passive

:: Dell Resource CD
start /wait msiexec /x {42929F0F-CE14-47AF-9FC7-FF297A603021} /qn /norestart /passive

:: Dell Support Center
start /wait msiexec /x {0090A87C-3E0E-43D4-AA71-A71B06563A4A} /qn /norestart /passive

:: Dell Wave Crypto Runtime // Infrastructure Installer // Support Software Installer // ESC Home Page Plugin // Preboot Manager // Private Information Manager
start /wait msiexec /x {8A2EF9A3-F1A8-4160-8C7D-4CADA7883BD1} /qn /norestart /passive
start /wait msiexec /x {30C2392C-C7D6-4FE2-9617-05D2C6E9D3EE} /qn /norestart /passive
start /wait msiexec /x {14CFC674-CD4F-4BE5-8B68-07BA3FE941FF} /qn /norestart /passive
start /wait msiexec /x {777FF553-493D-4068-BAC7-EE2D73DB7434} /qn /norestart /passive
start /wait msiexec /x {07D618CD-B016-438A-ADC9-A75BD23F85CE} /qn /norestart /passive
start /wait msiexec /x {5F160A36-29D0-4AE0-986C-671A564BC0D4} /qn /norestart /passive
start /wait msiexec /x {90DB5C39-360F-4187-9D56-E3B013CEEF73} /qn /norestart /passive
start /wait msiexec /x {86A9BBDF-9B6D-4E3D-810E-23C9079C6217} /qn /norestart /passive
start /wait msiexec /x {5FDA8F6A-E87C-484B-BDE2-12C1BE199149} /qn /norestart /passive
start /wait msiexec /x {67154CF5-2C33-41C2-A9F2-A4FBC29482AD} /qn /norestart /passive
start /wait msiexec /x {29D07FB4-A026-4E1F-B9A2-8C9EC0E2FEBB} /qn /norestart /passive
start /wait msiexec /x {083CE5FA-E750-4594-B8D1-13994B297A02} /qn /norestart /passive
start /wait msiexec /x {8C0600A3-E772-4FC8-A67D-ED110E69665C} /qn /norestart /passive
start /wait msiexec /x {A8991BF1-A3DC-4110-836A-C467AF9B71E8} /qn /norestart /passive
start /wait msiexec /x {79B520D5-CE72-4661-A054-804BC3412516} /qn /norestart /passive
start /wait msiexec /x {3C19BFFB-0393-43E7-A48D-6B8374D7E54E} /qn /norestart /passive
start /wait msiexec /x {B330548B-1EBE-429C-AA47-FC12748FA18F} /qn /norestart /passive
start /wait msiexec /x {3A6BE9F4-5FC8-44BB-BE7B-32A29607FEF6} /qn /norestart /passive
start /wait msiexec /x {0149ECF0-D825-4892-A468-065F2009328A} /qn /norestart /passive
start /wait msiexec /x {CA2F6FAD-D8CD-42C1-B04D-6E5B1B1CFDCC} /qn /norestart /passive
start /wait msiexec /x {0B0A2153-58A6-4244-B458-25EDF5FCD809} /qn /norestart /passive

:: Desktop Doctor 2.5.5
start /wait msiexec /x {D87149B3-7A1D-4548-9CBF-032B791E5908} /qn /norestart /passive

:: DIBS 1.7.0
start /wait msiexec /x {2EA870FA-585F-4187-903D-CB9FFD21E2E0} /qn /norestart /passive

:: Dolby Advanced Audio // Home Theater
start /wait msiexec /x {B26438B4-BF51-49C3-9567-7F14A5E40CB9} /qn /norestart /passive
start /wait msiexec /x {936CFA73-585F-4F5E-AB62-1350FE16E5FC} /qn /norestart /passive

:: Download Windows Universal Tools 14.0.22823
start /wait msiexec /x {7C361160-7ADC-46CE-AFDC-D10C6EADD032} /qn /norestart /passive

:: Driver Detective 8.0.1
start /wait msiexec /x {177CD779-4EEC-43C5-8DEA-4E0EC103624B} /qn /norestart /passive

:: Driver Manager 8.1
start /wait msiexec /x {27F1E086-5691-4EB8-8BA1-5CBA87D67EB5} /qn /norestart /passive

:: Dropbox Setup // shared with Dropbox Update Helper
start /wait msiexec /x {099218A5-A723-43DC-8DB5-6173656A1E94} /qn /norestart /passive

:: Dropbox Update Helper 1.3.27.33
start /wait msiexec /x {4640FDE1-B83A-4376-84ED-86F86BEE2D41} /qn /norestart /passive

:: DTS Sound
start /wait msiexec /x {793B70D2-41E9-46AB-9DDC-B34C99D07DB5} /qn /norestart /passive
start /wait msiexec /x {F8EB8FFC-C535-49A1-A84D-CC75CB2D6ADA} /qn /norestart /passive
start /wait msiexec /x {1BDEB6E2-6706-4132-A5D3-99190C6BECD8} /qn /norestart /passive
start /wait msiexec /x {2DFA9084-CEB3-4A48-B9F7-9038FEF1B8F4} /qn /norestart /passive

:: EA Download Manager
start /wait msiexec /x {EF7E931D-DC84-471B-8DB6-A83358095474} /qn /norestart /passive

:: eBay Worldwide
start /wait msiexec /x {8549CF08-D327-4B73-9036-75564C0BBCFC} /qn /norestart /passive

:: Energy Star // Energy Star Digital Logo
start /wait msiexec /x {465CA2B6-98AF-4E77-BE22-A908C34BB9EC} /qn /norestart /passive
start /wait msiexec /x {51CB3204-2129-4D74-8AF8-3AEB52793969} /qn /norestart /passive
start /wait msiexec /x {AC768037-7079-4658-AC24-2897650E0ABE} /qn /norestart /passive
start /wait msiexec /x {BD1A34C9-4764-4F79-AE1F-112F8C89D3D4} /qn /norestart /passive

:: Epson Customer Participation
start /wait msiexec /x {814FA673-A085-403C-9545-747FC1495069} /qn /norestart /passive
start /wait msiexec /x {4BB82AD9-0CF6-4E14-BD75-C1AB657C2914} /qn /norestart /passive

:: Epson Event Manager
start /wait msiexec /x {3F29268A-F53A-4387-9F2B-E9368A823178} /qn /norestart /passive
start /wait msiexec /x {2970697F-2A11-4588-8B7F-97322D1CCF3C} /qn /norestart /passive
start /wait msiexec /x {03B8AA32-F23C-4178-B8E6-09ECD07EAA47} /qn /norestart /passive
start /wait msiexec /x {10144CFE-D76C-4CFA-81A1-37A1642349A3} /qn /norestart /passive

:: ESC Home Page Plugin
start /wait msiexec /x {E738A392-F690-4A9D-808E-7BAF80E0B398} /qn /norestart /passive

:: Facebook Messenger 2.1.4814.0
start /wait msiexec /x {7204BDEE-1A48-4D95-A964-44A9250B439E} /qn /norestart /passive

:: Facebook Video Calling 3.1.0.521
start /wait msiexec /x {2091F234-EB58-4B80-8C96-8EB78C808CF7} /qn /norestart /passive

:: File Association Helper
start /wait msiexec /x {6D6ADF03-B257-4EA5-BBC1-1D145AF8D514} /qn /norestart /passive

:: Find Junk Files 1.51
start /wait msiexec /x {9FE8D71A-BEBC-48F3-9479-E5E25AE2A4F0} /qn /norestart /passive

:: FlashCatch browser plugin
start /wait msiexec /x {A0AB2980-1FDD-4b6c-940C-FC87C84F05B7} /qn /norestart /passive

:: Fujitsu Button Utilities 7.04.1209.2010
start /wait msiexec /x {EC314CDF-3521-482B-A21C-65AC95664814} /qn /norestart /passive

:: Fujitsu Display Manager 7.00.20.212
start /wait msiexec /x {191C41F6-4BA8-4D3D-BBC5-AAC8F3077E3F} /qn /norestart /passive

:: Fujitsu Driver Update 1.3.0012
start /wait msiexec /x {32782FFE-4BAC-48A4-A4FA-532560515E48} /qn /norestart /passive

:: Fujitsu Fingerprint Authentication Library 1.00.49.0
start /wait msiexec /x {C8E4B31D-337C-483D-822D-16F11441669B} /qn /norestart /passive

:: Fujitsu Hotkey Utility
start /wait msiexec /x {9FC6AD75-5B07-46E2-B80D-E9C13BBF45E0} /qn /norestart /passive
start /wait msiexec /x {C32028B6-E056-429C-B839-0DCF21528E71} /qn /norestart /passive

:: Fujitsu MobilityCenter Extension Utility
start /wait msiexec /x {0C216C82-F950-4C79-A63E-322C7280AC30} /qn /norestart /passive
start /wait msiexec /x {E8A5B78F-4456-4511-AB3D-E7BFFB974A7A} /qn /norestart /passive

:: Fujitsu Security Panel // Security Panel for Supervisor
start /wait msiexec /x {17F82182-0E3D-4A14-8843-5ECBFAF4F12F} /qn /norestart /passive
start /wait msiexec /x {0EFDF2F9-836D-4EB7-A32D-038BD3F1FB2A} /qn /norestart /passive

:: Fujitsu System Extension Utility 2.1.1.0
start /wait msiexec /x {DED08875-D1AE-4E66-BE84-BB746019B9F9} /qn /norestart /passive

:: GamingHarbor Toolbar
start /wait msiexec /x {F4D99A13-F63A-4FC1-8799-CFFDB78DDFB3} /qn /norestart /passive

:: Garmin Elevated Installer; known to cause popups and crash frequently
start /wait msiexec /x {D4D065E1-3ABF-41D0-B385-FC6F027F4D00} /qn /norestart /passive
start /wait msiexec /x {4694981D-8031-4526-90BE-E5F7FB80CBB8} /qn /norestart /passive

:: Garmin WebUpdater
start /wait msiexec /x {338ADB80-9C9E-4C71-9403-798057D7FFA6} /qn /norestart /passive

:: Get Dropbox (also called "Dropbox 25 GB" or "Dropbox 15 GB")
start /wait msiexec /x {597A58EC-42D6-4940-8739-FB94491B013C} /qn /norestart /passive

:: GeekBuddy
start /wait msiexec /x {17004FB0-9CFD-43DC-BB2D-E2BA612D98D0} /qn /norestart /passive

:: GlobalUpdate Helper
start /wait msiexec /x {A92DAB39-4E2C-4304-9AB6-BC44E68B55E2} /qn /norestart /passive

:: Google Toolbar for Internet Explorer
start /wait msiexec /x {18455581-E099-4BA8-BC6B-F34B2F06600C} /qn /norestart /passive
start /wait msiexec /x {2318C2B1-4965-11d4-9B18-009027A5CD4F} /qn /norestart /passive
start /wait msiexec /x {12ADFB82-D5A3-43E4-B2F4-FCD9B690315B} /qn /norestart /passive

:: Google Update Helper
start /wait msiexec /x {60EC980A-BDA2-4CB6-A427-B07A5498B4CA} /qn /norestart /passive
start /wait msiexec /x {A92DAB39-4E2C-4304-9AB6-BC44E68B55E2} /qn /norestart /passive
start /wait msiexec /x {A4DE5CD7-96D6-3979-8C39-E864396AFFC0} /qn /norestart /passive
start /wait msiexec /x {5BAA8884-F661-464B-B5B2-5C6C632BFC21} /qn /norestart /passive
start /wait msiexec /x {A92DAB39-4E2C-4304-9AB6-BC44E68B55E2} /qn /norestart /passive

:: Hewlett-Packard ACLM.NET
start /wait msiexec /x {6F340107-F9AA-47C6-B54C-C3A19F11553F} /qn /norestart /passive
start /wait msiexec /x {06FCC605-92A1-4A1C-B7D1-85E5778290A4} /qn /norestart /passive

:: HP 3.00.xxxx (various versions)
start /wait msiexec /x {2F518061-89DB-4AF0-9A7A-2BF73B60E6F0} /qn /norestart /passive
start /wait msiexec /x {912D30CF-F39E-4B31-AD9A-123C6B794EE2} /qn /norestart /passive
start /wait msiexec /x {F9569D00-4576-46C8-B6C7-207A4FD39745} /qn /norestart /passive

:: HP 3D DriveGuard
start /wait msiexec /x {E8D0E2B8-B64B-44BC-8E01-00DDACBDF78A} /qn /norestart /passive
start /wait msiexec /x {E5823036-6F09-4D0A-B05C-E2BAA129288A} /qn /norestart /passive
start /wait msiexec /x {0C57987A-A03A-4B95-A309-D23F78F406CA} /qn /norestart /passive
start /wait msiexec /x {55CA337D-2BE3-4AA4-BA1E-652F4C02E893} /qn /norestart /passive
start /wait msiexec /x {675D093B-815D-47FD-AB2C-192EC751E8E2} /qn /norestart /passive
start /wait msiexec /x {5B08AF35-B699-4A44-BB89-3E51E70611E8} /qn /norestart /passive
start /wait msiexec /x {C05002F1-06F8-4A15-B6F8-E4DC655C28AA} /qn /norestart /passive
start /wait msiexec /x {6BA7C52E-4071-47CC-9060-ABB143862DB0} /qn /norestart /passive
start /wait msiexec /x {ADE2F6A7-E7BD-4955-BD66-30903B223DDF} /qn /norestart /passive
start /wait msiexec /x {07E79F52-1D78-4081-814E-BF093FF7A1BF} /qn /norestart /passive
start /wait msiexec /x {F792E5B0-11C4-4C68-8A63-FB5F52749180} /qn /norestart /passive
start /wait msiexec /x {130E5108-547F-4482-91EE-F45C784E08C7} /qn /norestart /passive
start /wait msiexec /x {D79A02E9-6713-4335-9668-AAC7474C0C0E} /qn /norestart /passive

:: HP 64 Bit HP CIO Components Installer
start /wait msiexec /x {FF21C3E6-97FD-474F-9518-8DCBE94C2854} /qn /norestart /passive
start /wait msiexec /x {BC741628-0AFC-405C-8946-DD46D1005A0A} /qn /norestart /passive

:: HP ActiveCheck component for HP Active Support Libary
start /wait msiexec /x {254C37AA-6B72-4300-84F6-98A82419187E} /qn /norestart /passive
start /wait msiexec /x {CBB639E0-B534-4827-97B5-CA1A4CA985B5} /qn /norestart /passive

:: HP Advisor 3.4.10262.3295
start /wait msiexec /x {403996EB-2DCE-4C43-A2B8-2B956880772D} /qn /norestart /passive

:: HP Auto 1.0.12935.3667
start /wait msiexec /x {CB7D766C-879F-4800-BB09-3D29E306EF63} /qn /norestart /passive

:: HP BufferChm
start /wait msiexec /x {FA0FF682-CC70-4C57-93CD-E276F3E7537E} /qn /norestart /passive
start /wait msiexec /x {2EEA7AA4-C203-4b90-A34F-19FB7EF1C81C} /qn /norestart /passive
start /wait msiexec /x {62230596-37E5-4618-A329-0D21F529A86F} /qn /norestart /passive
start /wait msiexec /x {687FEF8A-8597-40b4-832C-297EA3F35817} /qn /norestart /passive

:: HP BPDSoftware (various versions); known to create annoying error messages and popups at system boot
start /wait msiexec /x {20D48DD8-06BA-4d5a-9796-6C7582F07947} /qn /norestart /passive
start /wait msiexec /x {38DAE5F5-EC70-4aa5-801B-D11CA0A33B41} /qn /norestart /passive
start /wait msiexec /x {508CE680-CAF5-4d0a-86E5-84E7B0701F26} /qn /norestart /passive
start /wait msiexec /x {268C2D6E-CDE9-47CD-87D9-A87710966709} /qn /norestart /passive
start /wait msiexec /x {671B4BAD-D681-4d29-9498-D8BF3F1A389D} /qn /norestart /passive
start /wait msiexec /x {6CC080F1-2E00-41D5-BE47-A3BC784E9DFB} /qn /norestart /passive
start /wait msiexec /x {AFB69549-3AAE-4433-A99B-673B8A513379} /qn /norestart /passive

:: HP C4400_Help
start /wait msiexec /x {4F923F90-46D1-4492-9CC6-13FBBA00E7EC} /qn /norestart /passive

:: HP Cards_Calendar_OrderGift_DoMorePlugout 1.00.0000
start /wait msiexec /x {C918E3D8-208F-43DB-B346-6299D59336D7} /qn /norestart /passive

:: HP CinemaNow Media Manager
start /wait msiexec /x {A5E65B95-F016-474D-BC0D-6AF64412BBDF} /qn /norestart /passive

:: HP Client Security Manager (various versions)
start /wait msiexec /x {3AF15EEA-8EDF-4393-BB6C-CF8A9986486A} /qn /norestart /passive
start /wait msiexec /x {CA19DC3C-DA9E-40B1-B501-710F437604C0} /qn /norestart /passive
start /wait msiexec /x {D5510D28-D0E4-433E-A0F3-EE3FCECA60D2} /qn /norestart /passive
start /wait msiexec /x {167AA1D5-8412-44BC-A003-B7A3662D1CE2} /qn /norestart /passive
start /wait msiexec /x {82E616DB-8BE9-46B7-AE42-60200985AD78} /qn /norestart /passive

:: HP Client Services 1.1.12938.3539
start /wait msiexec /x {28074A47-851D-4599-A270-87609F58EB57} /qn /norestart /passive

:: HP Color LaserJet Pro MFP M476 Scan Shortcuts 32.0.74.0
start /wait msiexec /x {B411AD10-1BC9-4939-8848-BC5E66F662B7} /qn /norestart /passive

:: HP Connected Remote 1.0.1218
start /wait msiexec /x {F1DD6CD2-6734-4089-9EF5-441F51E083B6} /qn /norestart /passive

:: HP Connection Manager (various versions)
start /wait msiexec /x {7940DAB9-AC72-4422-8908-DCF58C2C1D21} /qn /norestart /passive
start /wait msiexec /x {226837D8-0BF8-4CBE-BAB2-8F07E2C2B4DD} /qn /norestart /passive
start /wait msiexec /x {40FB8D7C-6FF8-4AF2-BC8B-0B1DB32AF04B} /qn /norestart /passive
start /wait msiexec /x {EB58480C-0721-483C-B354-9D35A147999F} /qn /norestart /passive
start /wait msiexec /x {7B7FF4D0-D4E2-4E8E-908D-90AB01BC4568} /qn /norestart /passive

:: HP CoolSense
start /wait msiexec /x {85DF2EED-08BC-46FB-90DA-28B0D0A8E8A8} /qn /norestart /passive
start /wait msiexec /x {DFD6EBE3-F0DA-4E24-9202-37AF8D20888B} /qn /norestart /passive
start /wait msiexec /x {ADDF4B84-5D28-4EAE-8511-EF808C8BC81C} /qn /norestart /passive
start /wait msiexec /x {1504CF6F-8139-497F-86FC-46174B67CF7F} /qn /norestart /passive
start /wait msiexec /x {59F8C5AA-91BD-423D-BF05-09A80F39898F} /qn /norestart /passive

:: HP Copy (various versions)
start /wait msiexec /x {3C92B2E6-380D-4fef-B4DF-4A3B4B669771} /qn /norestart /passive
start /wait msiexec /x {55D003F4-9599-44BF-BA9E-95D060730DD3} /qn /norestart /passive

:: HP CUE Status (various versions)
start /wait msiexec /x {5B025634-7D5B-4B8D-BE2A-7943C1CF2D5D} /qn /norestart /passive
start /wait msiexec /x {CE938F96-2EDD-4377-942A-1B877616E523} /qn /norestart /passive
start /wait msiexec /x {A0B9F8DF-C949-45ed-9808-7DC5C0C19C81} /qn /norestart /passive
start /wait msiexec /x {03A7C57A-B2C8-409b-92E5-524A0DFD0DD3} /qn /norestart /passive
start /wait msiexec /x {0EF5BEA9-B9D3-46d7-8958-FB69A0BAEACC} /qn /norestart /passive

:: HP Customer Experience Enhancements
start /wait msiexec /x {07FA4960-B038-49EB-891B-9F95930AA544} /qn /norestart /passive
start /wait msiexec /x {C9EF1AAF-B542-41C8-A537-1142DA5D4AEC} /qn /norestart /passive
start /wait msiexec /x {07F6DC37-0857-4B68-A675-4E35989E85E3} /qn /norestart /passive

:: HP CustomerResearchQFolder
start /wait msiexec /x {7206B668-FEE0-455B-BB1F-9B5A2E0EC94A} /qn /norestart /passive

:: HP Connected Music
start /wait msiexec /x {8126E380-F9C6-4317-9CEE-9BBDDAB676E5} /qn /norestart /passive

:: HP D2400_Help
start /wait msiexec /x {7EF7CCB0-52BF-4947-BE6E-E47D586E8842} /qn /norestart /passive

:: HP Deskjet 2510 series Setup Guide 
start /wait msiexec /x {216C7F38-4BBC-4E9A-8392-C9FA21B54386} /qn /norestart /passive

:: HP Deskjet 3050 J610 series Help 140.0.63.63
start /wait msiexec /x {F7632A9B-661E-4FD9-B1A4-3B86BC99847F} /qn /norestart /passive

:: HP Destinations
start /wait msiexec /x {5E487136-B52E-4856-8F5F-FCDF5E5FC5EE} /qn /norestart /passive
start /wait msiexec /x {D99A8E3A-AE5A-4692-8B19-6F16D454E240} /qn /norestart /passive
start /wait msiexec /x {EF9E56EE-0243-4BAD-88F4-5E7508AA7D96} /qn /norestart /passive

:: HP Device Access Manager
start /wait msiexec /x {2642BE09-1F9F-4E18-AAD4-0258B9BCE611} /qn /norestart /passive
start /wait msiexec /x {9EC0BE64-2C6C-428A-A4C2-E7EDF831B29A} /qn /norestart /passive
start /wait msiexec /x {DBCD5E64-7379-4648-9444-8A6558DCB614} /qn /norestart /passive
start /wait msiexec /x {BD7204BA-DD64-499E-9B55-6A282CDF4FA4} /qn /norestart /passive

:: HP DeviceManagementQFolder
start /wait msiexec /x {AB5D51AE-EBC3-438D-872C-705C7C2084B0} /qn /norestart /passive
start /wait msiexec /x {F769B78E-FF0E-4db5-95E2-9F4C8D6352FE} /qn /norestart /passive

:: HP Discover hp Touchpoint Manager
start /wait msiexec /x {37EC8980-A8E5-411D-8CDD-CB1CCA95057F} /qn /norestart /passive

:: HP DisplayLink Core Software and DisplayLink Graphics
start /wait msiexec /x {796E076A-82F7-4D49-98C8-DEC0C3BC733A} /qn /norestart /passive
start /wait msiexec /x {33023FE8-9028-416A-8A5C-C115B59DD538} /qn /norestart /passive
start /wait msiexec /x {0DE76F90-E993-47C7-BF6A-2B385492D490} /qn /norestart /passive
start /wait msiexec /x {2021896F-CECA-463C-A7A8-9949A13910F7} /qn /norestart /passive
start /wait msiexec /x {7BB949B9-EB47-47E4-814D-88F8CD301543} /qn /norestart /passive
start /wait msiexec /x {D21BDA13-5E4C-401D-8353-2543251B40E2} /qn /norestart /passive
start /wait msiexec /x {A4D282D0-1B48-481B-9E52-5F0B001A2BAB} /qn /norestart /passive
start /wait msiexec /x {34412EC4-6A3C-454F-AF8B-75B0A0DF00AB} /qn /norestart /passive
start /wait msiexec /x {861C4DFA-E691-4BA6-BE6B-D5BA211990B6} /qn /norestart /passive
start /wait msiexec /x {3B1040BE-8AB0-4D80-A68E-029D70A0868B} /qn /norestart /passive
start /wait msiexec /x {70E2B27F-0B7F-41B2-8145-E7377BC9F75A} /qn /norestart /passive
start /wait msiexec /x {8C2259F3-35F4-4663-87BF-9F5F6AE6C4F7} /qn /norestart /passive
start /wait msiexec /x {12F5A080-A6EE-4FCC-B355-80CBBF33FAA0} /qn /norestart /passive
start /wait msiexec /x {89E40591-0404-4769-88E7-F649C95AE151} /qn /norestart /passive
start /wait msiexec /x {65B2569D-303B-41EC-B38C-0934963BC3AD} /qn /norestart /passive
start /wait msiexec /x {D9D8900B-CFEB-44C6-B417-D6308B5B145D} /qn /norestart /passive
start /wait msiexec /x {29E6A126-BB06-41CF-B12D-E6A56261328D} /qn /norestart /passive

:: HP Documentation
start /wait msiexec /x {C8D60CF4-BE7A-487E-BD36-535111BDB0FE} /qn /norestart /passive
start /wait msiexec /x {06600E94-1C34-40E2-AB09-D30AECF78172} /qn /norestart /passive
start /wait msiexec /x {025D3904-FA39-4AA2-A05B-9EFAAF36B1F2} /qn /norestart /passive
start /wait msiexec /x {1F0493F6-311D-44E5-A9E6-F0D4C63FB8FD} /qn /norestart /passive
start /wait msiexec /x {5340A3C6-4169-484A-ADA7-63BCF5C557A0} /qn /norestart /passive
start /wait msiexec /x {7573D7E5-02BB-4903-80EB-36073A99BC8D} /qn /norestart /passive
start /wait msiexec /x {791A06E2-340F-43B0-8FAB-62D151339362} /qn /norestart /passive
start /wait msiexec /x {8327F6D2-C8CC-49B5-B8D1-46C83909650E} /qn /norestart /passive
start /wait msiexec /x {84F0C8C0-263A-4B3A-888D-2A5FDEA15401} /qn /norestart /passive
start /wait msiexec /x {8ABB6A99-E2D5-47E4-905A-2FD4657D235E} /qn /norestart /passive
start /wait msiexec /x {9867A917-5D17-40DE-83BA-BEA5293194B1} /qn /norestart /passive
start /wait msiexec /x {A6365256-0FBA-4DCD-88CE-D92A4DC9328E} /qn /norestart /passive
start /wait msiexec /x {A1CFA587-90D4-4DE6-B200-68CC0F92252F} /qn /norestart /passive
start /wait msiexec /x {53AE55F3-8E99-4776-A347-06222894ECD3} /qn /norestart /passive
start /wait msiexec /x {95CC589C-8D98-4539-9878-4E6A342304F2} /qn /norestart /passive
start /wait msiexec /x {9D20F550-4222-49A7-A7A7-7CAAB2E16C9C} /qn /norestart /passive
start /wait msiexec /x {89A12FD9-8FA0-4EB9-AE9A-34C7EB25C25B} /qn /norestart /passive

:: HP DocProc
start /wait msiexec /x {676981B7-A2D9-49D0-9F4C-03018F131DA9} /qn /norestart /passive
start /wait msiexec /x {C29C1940-CB85-4F3B-906C-33FEE0E67103} /qn /norestart /passive
start /wait msiexec /x {679EC478-3FF9-4987-B2FF-C2C2B27532A2} /qn /norestart /passive
start /wait msiexec /x {9B362566-EC1B-4700-BB9C-EC661BDE2175} /qn /norestart /passive

:: HPDiagnosticAlert
start /wait msiexec /x {B6465A32-8BE9-4B38-ADC5-4B4BDDC10B0D} /qn /norestart /passive
start /wait msiexec /x {846B5DED-DC8C-4E1A-B5B4-9F5B39A0CACE} /qn /norestart /passive

:: HP DisableMSDefender (disables Microsoft Defender...wtf?)
start /wait msiexec /x {74FE39A0-FB76-47CD-84BA-91E2BBB17EF2} /qn /norestart /passive
start /wait msiexec /x {AF9E97C1-7431-426D-A8D5-ABE40995C0B1} /qn /norestart /passive

:: HP ENVY 4500 series Help
start /wait msiexec /x {95BECC50-22B4-4FCA-8A2E-BF77713E6D3A} /qn /norestart /passive

:: HP ESU for Microsoft Windows (Windows update hijacker)
start /wait msiexec /x {A5F1C701-E150-4A86-A7F8-9E9225C2AE52} /qn /norestart /passive
start /wait msiexec /x {6349342F-9CEF-4A70-995A-2CF3704C2603} /qn /norestart /passive
start /wait msiexec /x {22706ADC-74A1-43A0-ABAE-47F84966B909} /qn /norestart /passive
start /wait msiexec /x {2BF5E9CC-C55D-4B0F-ACAF-FFE77F333CD8} /qn /norestart /passive
start /wait msiexec /x {A351CC1B-C92C-4F37-8109-9F6D33ACF5EF} /qn /norestart /passive

:: HP eSupportQFolder
start /wait msiexec /x {66E6CE0C-5A1E-430C-B40A-0C90FF1804A8} /qn /norestart /passive
start /wait msiexec /x {8894A6A7-547D-4326-B4BC-FB62B9075CE2} /qn /norestart /passive

:: HP File Sanitizer
start /wait msiexec /x {53D3E126-699A-4D92-AA66-6560D573553E} /qn /norestart /passive
start /wait msiexec /x {60F90886-FAEE-4768-9817-093AB0F30540} /qn /norestart /passive

:: HP FWUpdateEDO2
start /wait msiexec /x {415FA9AD-DA10-4ABE-97B6-5051D4795C90} /qn /norestart /passive

:: HP GPBaseService2 (popups)
start /wait msiexec /x {BB3447F6-9553-4AA9-960E-0DB5310C5779} /qn /norestart /passive

:: HP misc Help, eDocs and User Guide GUIDs (various versions for various products; most of these should be caught in the wildcard scan)
start /wait msiexec /x {11C9A461-DD9D-4C71-85A4-6DCE7F99CC44} /qn /norestart /passive
start /wait msiexec /x {B6B9006D-5A0A-4F17-B69A-42F48C1FC30C} /qn /norestart /passive
start /wait msiexec /x {445CC807-9384-47FA-A2B6-FFE970352B88} /qn /norestart /passive
start /wait msiexec /x {F90A86C9-7779-47DD-AC06-8EE832C55F55} /qn /norestart /passive
start /wait msiexec /x {1575F408-60AC-4a37-904A-931117272926} /qn /norestart /passive
start /wait msiexec /x {4B322C8E-8775-4f20-8978-ED63DB4770C4} /qn /norestart /passive
start /wait msiexec /x {7E60EE8D-0914-444E-A682-7703BDDEB5EB} /qn /norestart /passive
start /wait msiexec /x {DE13432E-F0C1-4842-A5BA-CC997DA72A70} /qn /norestart /passive
start /wait msiexec /x {A4966638-798C-45B9-B5BF-07D3E63B58C2} /qn /norestart /passive
start /wait msiexec /x {7F94FB03-6617-4442-9817-CDDB36EAE529} /qn /norestart /passive
start /wait msiexec /x {86BC184E-CFCD-48D5-829A-666A36C6ACC9} /qn /norestart /passive
start /wait msiexec /x {B8454F30-79EC-4959-BCF1-3776DEC406AB} /qn /norestart /passive
start /wait msiexec /x {BCFAA37D-A6DB-43BF-A351-43F183E52D07} /qn /norestart /passive
start /wait msiexec /x {5C76ED0D-0F6F-4985-8B34-F9AE7834848F} /qn /norestart /passive
start /wait msiexec /x {74038F40-03AE-4785-865B-07EC7F6A5E97} /qn /norestart /passive
start /wait msiexec /x {04D66C1E-E5E2-483C-8715-916C42703924} /qn /norestart /passive
start /wait msiexec /x {5D3E11CE-2C9A-44E3-A561-ED9BAC439E83} /qn /norestart /passive
start /wait msiexec /x {83A375B6-6FC2-4F8A-948E-E506DB9DCDF0} /qn /norestart /passive
start /wait msiexec /x {D2A2E5CD-801A-4B8D-8119-F79449A09B67} /qn /norestart /passive
start /wait msiexec /x {F6D61EC9-347B-4019-9F8E-E24169F7C330} /qn /norestart /passive
start /wait msiexec /x {2A186F69-BCC4-4529-9F24-A8FFB7F4E1C9} /qn /norestart /passive
start /wait msiexec /x {6357258D-2BF9-49E7-A9EF-0C609D52C46D} /qn /norestart /passive
start /wait msiexec /x {563ADFC1-38E6-4EF0-8763-7CDA8289944B} /qn /norestart /passive
start /wait msiexec /x {C1223A79-3983-4877-B162-75031E7CE322} /qn /norestart /passive
start /wait msiexec /x {DDEBEA89-2B5A-4E5B-8702-369882BB3F52} /qn /norestart /passive
start /wait msiexec /x {BD019D8F-25B9-49D6-B301-07AFF65E35DD} /qn /norestart /passive
start /wait msiexec /x {4989DD05-86FB-4CA2-96C5-923DFAD89DA3} /qn /norestart /passive
start /wait msiexec /x {55D8D1AB-94C2-498F-A165-608B834A30EA} /qn /norestart /passive
start /wait msiexec /x {274E6D9A-7CCD-4D67-9660-639486F466B2} /qn /norestart /passive
start /wait msiexec /x {92AB9371-D327-4D56-9BDD-B38A671A631D} /qn /norestart /passive
start /wait msiexec /x {32A4CF00-9FAC-47c8-9B37-91CC23815D64} /qn /norestart /passive
start /wait msiexec /x {6357D25F-A9C9-4CC7-A1FB-0DCF344E7C40} /qn /norestart /passive

:: HP Insight Diagnostics Online Edition for Windows 9.3.0
start /wait msiexec /x {DBE16A07-DDFF-4453-807A-212EF93916E0} /qn /norestart /passive

:: HP MarketResearch
start /wait msiexec /x {95D08F4E-DFC2-4ce3-ACB7-8C8E206217E9} /qn /norestart /passive
start /wait msiexec /x {D360FA88-17C8-4F14-B67F-13AAF9607B12} /qn /norestart /passive

:: HP MediaSmart SmartMenu
start /wait msiexec /x {5A5F45AE-0250-4C34-9D89-F10BDDEE665F} /qn /norestart /passive
start /wait msiexec /x {A3B64280-DE4C-40F0-86BB-CCB2A6056BA2} /qn /norestart /passive

:: HP MediaSmart/TouchSmart Netflix (various versions)
start /wait msiexec /x {34FF930E-DBF9-4858-BAB5-BAC957BF616E} /qn /norestart /passive
start /wait msiexec /x {2D5E3D2B-919F-407C-8757-E64827518BB6} /qn /norestart /passive
start /wait msiexec /x {BB1C717E-376C-4AA1-8940-81BFC38D9778} /qn /norestart /passive

:: HP MyRoom 10.0.0274
start /wait msiexec /x {BB760C1D-98F4-4E38-8CC4-3B67329AA981} /qn /norestart /passive
start /wait msiexec /x {9B9B8EE4-2EDB-41C2-AF2E-63E75D37CDDF} /qn /norestart /passive

:: HPProductAssistant (shows up as Network, hidden)
start /wait msiexec /x {7910018D-02CF-4410-A7E5-CF5C10D05B7F} /qn /norestart /passive
start /wait msiexec /x {8A27C0FE-87C7-4169-BF5A-05BF94F70A54} /qn /norestart /passive
start /wait msiexec /x {21706D5B-A09C-42F1-95B5-CBDFE20F9852} /qn /norestart /passive

:: HP Odometer 2.10.0000
start /wait msiexec /x {B899AE89-9B09-4F11-B299-A1209CAB8D00} /qn /norestart /passive

:: HP On Screen Display (various versions)
start /wait msiexec /x {9ADABDDE-9644-461B-9E73-83FA3EFCAB50} /qn /norestart /passive
start /wait msiexec /x {D734D743-2385-46ED-9B3E-168A24A9E1A9} /qn /norestart /passive
start /wait msiexec /x {EC8D12E4-A73C-4C27-B1C7-E9683052E556} /qn /norestart /passive

:: HP PageLift
start /wait msiexec /x {7059BDA7-E1DB-442C-B7A1-6144596720A4} /qn /norestart /passive
start /wait msiexec /x {274A948D-DD41-4B8F-B66F-0F4AD233200F} /qn /norestart /passive

:: HPPhotoGadget
start /wait msiexec /x {CAE4213F-F797-439D-BD9E-79B71D115BE3} /qn /norestart /passive

:: HPPhotoSmartDiscLabelContent1, DiscLabel_PrintOnDisc, disclabelplugin, DiscLabel_PaperLabel
start /wait msiexec /x {681B698F-C997-42C3-B184-B489C6CA24C9} /qn /norestart /passive
start /wait msiexec /x {20EFC9AA-BBC1-4DFD-81FF-99654F71CBF8} /qn /norestart /passive
start /wait msiexec /x {B28635AB-1DF3-4F07-BFEA-975D911B549B} /qn /norestart /passive
start /wait msiexec /x {D9D8F2CF-FE2D-4644-9762-01F916FE90A9} /qn /norestart /passive

:: HP Photosmart Essential
start /wait msiexec /x {EB21A812-671B-4D08-B974-2A347F0D8F70} /qn /norestart /passive
start /wait msiexec /x {D79113E7-274C-470B-BD46-01B10219DF6A} /qn /norestart /passive
start /wait msiexec /x {BAC712C6-4061-4C9F-AB58-A5C53E76704A} /qn /norestart /passive

:: HP Product Assistant
start /wait msiexec /x {150B6201-E9E6-4DFB-960E-CCBD53FBDDED} /qn /norestart /passive
start /wait msiexec /x {67D3F1A0-A1F2-49b7-B9EE-011277B170CD} /qn /norestart /passive
start /wait msiexec /x {36FDBE6E-6684-462b-AE98-9A39A1B200CC} /qn /norestart /passive
start /wait msiexec /x {9D1B99B7-DAD8-440d-B4FB-1915332FBCC2} /qn /norestart /passive
start /wait msiexec /x {C75CDBA2-3C86-481e-BD10-BDDA758F9DFF} /qn /norestart /passive
start /wait msiexec /x {83F51BBA-48BE-4BB6-B96A-F4AAE4C462F9} /qn /norestart /passive

:: HP Product Detection
start /wait msiexec /x {A436F67F-687E-4736-BD2B-537121A804CF} /qn /norestart /passive

:: HP Product Documentation Launcher // Product_SF_Min_QFolder // ProductContext
start /wait msiexec /x {710F7B0F-A679-4314-8E69-E868B660FAEA} /qn /norestart /passive
start /wait msiexec /x {89CEAE14-DD0F-448E-9554-15781EC9DB24} /qn /norestart /passive
start /wait msiexec /x {414C803A-6115-4DB6-BD4E-FD81EA6BC71C} /qn /norestart /passive
start /wait msiexec /x {5962ABC1-427C-4651-B6FC-187A9F653AEF} /qn /norestart /passive
start /wait msiexec /x {6E4EE9B5-F69D-4455-B430-40FA5F0DC988} /qn /norestart /passive

:: HP Product Improvement Study (various versions)
start /wait msiexec /x {E3D43596-7E26-479E-B718-77CB3D9270F6} /qn /norestart /passive
start /wait msiexec /x {A90F92B7-3C3F-4AEF-B281-31DD17BB73CA} /qn /norestart /passive
start /wait msiexec /x {37839D69-6DA4-4125-B33A-30DE86345DF4} /qn /norestart /passive
start /wait msiexec /x {FEB2C4AA-661E-483F-9626-21A8ACFD10F2} /qn /norestart /passive
start /wait msiexec /x {D2064264-3162-4DB1-AFE0-167BEFBBCD9C} /qn /norestart /passive

:: HP PostScript Converter
start /wait msiexec /x {6E14E6D6-3175-4E1A-B934-CAB5A86367CD} /qn /norestart /passive

:: HP Power Manager
start /wait msiexec /x {8704FEEF-A6A8-4E7E-B124-BD6122C66E2C} /qn /norestart /passive
start /wait msiexec /x {E35A3B13-78CD-4967-8AC8-AA9FDA693EDE} /qn /norestart /passive

:: HP Product Detection 11.14.0006
start /wait msiexec /x {424CECC6-CEB1-4A5F-9A42-ADE64F035DEB} /qn /norestart /passive

:: HP ProtectTools GUIDs. Too many to list, Google each GUID for more information
start /wait msiexec /x {A40F60B1-F1E1-452E-96A5-FF97F9A2D102} /qn /norestart /passive
start /wait msiexec /x {EEAFE1E5-076B-430A-96D9-B567792AFA88} /qn /norestart /passive
start /wait msiexec /x {EEEB604C-C1A7-4f8c-B03F-56F9C1C9C45F} /qn /norestart /passive
start /wait msiexec /x {6F8071B2-5ECA-4A71-8E5D-7E2FE8174559} /qn /norestart /passive
start /wait msiexec /x {1868D30B-72C7-41E8-9657-69C5DFE1C768} /qn /norestart /passive
start /wait msiexec /x {9D380C34-58B7-4FF9-9DB8-05685AAD93D4} /qn /norestart /passive
start /wait msiexec /x {3E9BC837-E48E-4964-AFFD-7AB40EBA5C50} /qn /norestart /passive
start /wait msiexec /x {71EE298A-7B6D-4303-8438-C3E50567DA1F} /qn /norestart /passive
start /wait msiexec /x {3F728815-C7E8-40EA-8D1A-F7B8E2382325} /qn /norestart /passive
start /wait msiexec /x {D5D422B9-6976-4E98-8DDF-9632CB515D7E} /qn /norestart /passive
start /wait msiexec /x {6D4839CB-28B4-4070-8CA7-612CA92CA3D0} /qn /norestart /passive
start /wait msiexec /x {29AB47F0-C5A3-401F-8A84-3324F2DC8E46} /qn /norestart /passive
start /wait msiexec /x {B0781FBD-8AD6-4658-A031-9815E1AC5047} /qn /norestart /passive
start /wait msiexec /x {55B30AF2-7331-4436-9318-D9EA45A42F79} /qn /norestart /passive

:: hp psc 1200 series 1.10.0000
start /wait msiexec /x {C88F84E5-AE23-44BD-922C-2ABEACACAF7A} /qn /norestart /passive

:: HP Quick Launch and Quick Start (various versions)
start /wait msiexec /x {E92D47A1-D27D-430A-8368-0BAFD956507D} /qn /norestart /passive
start /wait msiexec /x {BAD0FA60-09CF-4411-AE6A-C2844C8812FA} /qn /norestart /passive
start /wait msiexec /x {2856A1C2-70C5-4EC3-AFF7-E5B51E5530A2} /qn /norestart /passive
start /wait msiexec /x {E4A80DC6-8475-4AD9-9952-5E4437889563} /qn /norestart /passive
start /wait msiexec /x {6B7AB1ED-B64E-4545-A8E7-F9E071E12B6F} /qn /norestart /passive
start /wait msiexec /x {566BB063-0E28-4273-A748-690BE86A7E26} /qn /norestart /passive

:: HP QuickTransfer
start /wait msiexec /x {E7004147-2CCA-431C-AA05-2AB166B9785D} /qn /norestart /passive

:: HP Recovery Manager
start /wait msiexec /x {64BAA990-F1FC-4145-A7B1-E41FBBC9DA47} /qn /norestart /passive
start /wait msiexec /x {D817481A-193E-4332-A4F3-E19132F744F0} /qn /norestart /passive
start /wait msiexec /x {6369FC9E-FC8D-493F-AD87-D51FAB492705} /qn /norestart /passive
start /wait msiexec /x {DB97D0DE-0AA1-413C-8398-92C7FA3F4A67} /qn /norestart /passive
start /wait msiexec /x {4F46FDB9-B906-47BF-B3D5-C62E01B3C5EE} /qn /norestart /passive
start /wait msiexec /x {98C4DE92-27C8-482C-8431-514828756E80} /qn /norestart /passive

:: HP Registration Service
start /wait msiexec /x {D1E8F2D7-7794-4245-B286-87ED86C1893C} /qn /norestart /passive
start /wait msiexec /x {C0C9A493-51CB-4F3F-A296-5B5E410C338E} /qn /norestart /passive
start /wait msiexec /x {D1E7D876-6B86-4B35-A93D-15B0D6C43EAF} /qn /norestart /passive

:: HP Rescue and Recovery
start /wait msiexec /x {C81D8576-F1B1-4E3A-9DC3-DF1B664962F0} /qn /norestart /passive

:: HP Setup
start /wait msiexec /x {438363A8-F486-4C37-834C-4955773CB3D3} /qn /norestart /passive

:: HP SimplePass
start /wait msiexec /x {314FAD12-F785-4471-BCE8-AB506642B9A1} /qn /norestart /passive
start /wait msiexec /x {F1390872-2500-4408-A46C-CD16C960C661} /qn /norestart /passive
start /wait msiexec /x {BBEB46E1-810D-449F-A9C5-4D60F3BF187D} /qn /norestart /passive
start /wait msiexec /x {30E20E5D-5E4E-4874-A35A-952DB3582C29} /qn /norestart /passive

:: HP Security Assistant 3.0.4
start /wait msiexec /x {ED1BD69A-07E3-418C-91F1-D856582581BF} /qn /norestart /passive

:: HP Setup 9.1.15453.4066
start /wait msiexec /x {42D10994-A566-495D-A5E7-D0C6B5C6B35C} /qn /norestart /passive

:: HP Setup Manager 1.1.13253.3682
start /wait msiexec /x {AE2F1669-5B1F-47C5-B639-78D74DD0BCE4} /qn /norestart /passive

:: HP SmartWebPrinting
start /wait msiexec /x {8FF6F5CA-4E30-4E3B-B951-204CAAA2716A} /qn /norestart /passive
start /wait msiexec /x {DC635845-46D3-404B-BCB1-FC4A91091AFA} /qn /norestart /passive

:: HP Status Alerts
start /wait msiexec /x {9D1DE902-8058-4555-A16A-FBFAA49587DB} /qn /norestart /passive

:: HP SoftPaq Download Manager
start /wait msiexec /x {3F019647-AC80-4859-B023-42D9DA71953F} /qn /norestart /passive
start /wait msiexec /x {5B4F3B85-83F0-4BBF-9052-7A38B6B09634} /qn /norestart /passive
start /wait msiexec /x {46235FF7-2CBE-4A84-BEDA-87348D1F7850} /qn /norestart /passive
start /wait msiexec /x {20D6301E-0A14-4238-841D-45ECA567DB69} /qn /norestart /passive
start /wait msiexec /x {FC3C2B77-6800-48C6-A15D-9D1031130C16} /qn /norestart /passive
start /wait msiexec /x {34C821CA-6B55-44A0-8A9B-2EF471D6019E} /qn /norestart /passive
start /wait msiexec /x {6821D775-9303-46DD-977A-2D97CA18B054} /qn /norestart /passive

:: HP Software Framework
start /wait msiexec /x {B6F5C6D8-C443-4B55-932F-AE11B5743FC4} /qn /norestart /passive
start /wait msiexec /x {285F722C-0E45-47DE-B38E-5B3B10FA4A7C} /qn /norestart /passive
start /wait msiexec /x {95EEB814-D454-4176-A6B5-D708CB48064F} /qn /norestart /passive
start /wait msiexec /x {6663B59B-E9CE-44CA-8654-7BE9060D653D} /qn /norestart /passive
start /wait msiexec /x {DAE3B13B-5097-4EAE-BC26-C463377BD80E} /qn /norestart /passive

:: HP Software Setup
start /wait msiexec /x {65514800-1E09-48D6-B520-3DC70572E891} /qn /norestart /passive
start /wait msiexec /x {D160035A-CFF0-49C6-BE19-B9EFDE4AEBF2} /qn /norestart /passive
start /wait msiexec /x {7ED7BF91-D145-480A-B206-6891576F6935} /qn /norestart /passive
start /wait msiexec /x {B1A4A13D-4665-4ED3-9DFE-F845725FBBD8} /qn /norestart /passive
start /wait msiexec /x {741CFE3A-1C0B-4A7D-8E08-5D78C911C09D} /qn /norestart /passive
start /wait msiexec /x {F4D304D9-7647-4253-957E-44286B8631F4} /qn /norestart /passive

:: HP Solution Center
start /wait msiexec /x {BC5DD87B-0143-4D14-AAE6-97109614DC6B} /qn /norestart /passive
start /wait msiexec /x {A36CD345-625C-4d6c-B3E2-76E1248CB451} /qn /norestart /passive

:: HP Support Assistant (various versions)
start /wait msiexec /x {8C696B4B-6AB1-44BC-9416-96EAC474CABE} /qn /norestart /passive
start /wait msiexec /x {61EB474B-67A6-47F4-B1B7-386851BAB3D0} /qn /norestart /passive
start /wait msiexec /x {4EDD5F10-3961-48C2-ACD9-63D5C125EA8F} /qn /norestart /passive
start /wait msiexec /x {7414C891-720D-4E86-85E5-C3AA898DA9EC} /qn /norestart /passive
start /wait msiexec /x {49524B48-4FE9-4A62-A9FD-1F2258DF5489} /qn /norestart /passive
start /wait msiexec /x {B18EF1BB-63C5-489A-8367-D1A253DFD5DD} /qn /norestart /passive
start /wait msiexec /x {E5C1C126-1687-4868-A3DD-B807176E4970} /qn /norestart /passive
start /wait msiexec /x {6F1C00D2-25C2-4CBA-8126-AE9A6E2E9CD5} /qn /norestart /passive
start /wait msiexec /x {ED84321F-D2C5-46F0-8CAA-DAB8496E9070} /qn /norestart /passive
start /wait msiexec /x {C807BEFB-0F17-41AC-B307-D7B5E1553040} /qn /norestart /passive
start /wait msiexec /x {A3876D50-4A88-4A34-92E1-5D7BC8F886E1} /qn /norestart /passive
start /wait msiexec /x {3A61A282-4F08-4D43-920C-DC30ECE528E8} /qn /norestart /passive
start /wait msiexec /x {E2C8D0C2-1C97-4C05-939A-5B13A0FE655C} /qn /norestart /passive
start /wait msiexec /x {8B2A1CFD-8F88-4081-9E18-99395CC27EE6} /qn /norestart /passive
start /wait msiexec /x {7F2A11F4-EAE8-4325-83EC-E3E99F85169E} /qn /norestart /passive
start /wait msiexec /x {8F2FC505-65FC-41B6-AAA7-55E266418E30} /qn /norestart /passive
start /wait msiexec /x {B8AC1A89-FFD1-4F97-8051-E505A160F562} /qn /norestart /passive
start /wait msiexec /x {7EF08127-4C30-4C05-8CEB-544F8A71C080} /qn /norestart /passive
start /wait msiexec /x {B1E569B6-A5EB-4C97-9F93-9ED2AA99AF0E} /qn /norestart /passive
start /wait msiexec /x {FB4BB287-37F9-4E27-9C4D-2D3882E08EFF} /qn /norestart /passive

:: HP Support Information
start /wait msiexec /x {B2B7B1C8-7C8B-476C-BE2C-049731C55992} /qn /norestart /passive

:: HP Support Solutions Framework
start /wait msiexec /x {D7D5F438-26EF-45AB-AB89-C476FBCF8584} /qn /norestart /passive

:: HP System Default Settings
start /wait msiexec /x {5C90D8CF-F12A-41C6-9007-3B651A1F0D78} /qn /norestart /passive
start /wait msiexec /x {28FE073B-1230-4BF6-830C-7434FD0C0069} /qn /norestart /passive
start /wait msiexec /x {C422BF2C-E570-4D3E-8718-7C641B190DB2} /qn /norestart /passive
start /wait msiexec /x {39011DEC-8956-401E-8369-421D402FFF52} /qn /norestart /passive

:: HP System Event Utility
start /wait msiexec /x {8B4EE87E-6D40-4C91-B5E8-0DC77DC412F1} /qn /norestart /passive

:: hpStatusAlerts
start /wait msiexec /x {7504A7B0-003E-4875-A454-B627E127E9D9} /qn /norestart /passive
start /wait msiexec /x {06CE2B24-EC8C-4847-AF33-098255B5D32D} /qn /norestart /passive
start /wait msiexec /x {44EB02F5-16E5-42BD-9183-C23EF7620CF3} /qn /norestart /passive
start /wait msiexec /x {46A99EAE-98DA-4BE5-94C3-D41BA4C266DA} /qn /norestart /passive
start /wait msiexec /x {B8DBED1E-8BC3-4d08-B94A-F9D7D88E9BBF} /qn /norestart /passive
start /wait msiexec /x {6470E292-3B55-41DC-B5EB-91C34C5ACB5D} /qn /norestart /passive
start /wait msiexec /x {7C960641-0A27-45C6-96F8-BE4E04A4CC2C} /qn /norestart /passive
start /wait msiexec /x {092FCD1C-5203-4BD1-B4F4-0F0C6B237A6A} /qn /norestart /passive
start /wait msiexec /x {0CCFF6E8-B4D1-416F-8198-B223BA8B1991} /qn /norestart /passive
start /wait msiexec /x {25E11B5A-4817-4296-A260-235AE77B1708} /qn /norestart /passive
start /wait msiexec /x {A1EF28FB-74A8-4157-91E9-9C164CAB10F8} /qn /norestart /passive
start /wait msiexec /x {FDEA674C-478D-455F-9894-D6D4CD4BB304} /qn /norestart /passive
start /wait msiexec /x {71677768-D5DA-4785-8A44-2DFFE33CF70A} /qn /norestart /passive
start /wait msiexec /x {9652051B-BC94-4588-A84B-B9B34660FB5E} /qn /norestart /passive
start /wait msiexec /x {456E4C16-227D-48E4-BA3B-52D1B15CB196} /qn /norestart /passive

:: HP Theft Recovery
start /wait msiexec /x {B9A03B7B-E0FF-4FB3-BA83-762E58A1B0AA} /qn /norestart /passive
start /wait msiexec /x {B1CB7E99-4685-45CB-867E-2FB58EDA0A39} /qn /norestart /passive

:: HP "Toolbox" (hidden)
start /wait msiexec /x {A7D99092-CFCA-AF69-9B61-B4A8784B5F8C} /qn /norestart /passive
start /wait msiexec /x {6BBA26E9-AB03-4FE7-831A-3535584CA002} /qn /norestart /passive
start /wait msiexec /x {292F0F52-B62D-4E71-921B-89A682402201} /qn /norestart /passive
start /wait msiexec /x {0F7C2E47-089E-4d23-B9F7-39BE00100776} /qn /norestart /passive
start /wait msiexec /x {AC13BA3A-336B-45a4-B3FE-2D3058A7B533} /qn /norestart /passive

:: HP TouchSmart Browser, Calendar, Canvas, Clock, Notes, RSS, Tutorials, Twitter and Weather
start /wait msiexec /x {4127C2C0-0AC7-4947-9CC1-AACBEFC6EC02} /qn /norestart /passive
start /wait msiexec /x {DE77FE3F-A33D-499A-87AD-5FC406617B40} /qn /norestart /passive
start /wait msiexec /x {03D15668-8F54-47C0-BFF2-6F966E4DF052} /qn /norestart /passive
start /wait msiexec /x {84814E6B-2581-46EC-926A-823BD1C670F6} /qn /norestart /passive
start /wait msiexec /x {4EDBB1CC-C418-443B-A0B0-A94DEA1ED8B2} /qn /norestart /passive
start /wait msiexec /x {55C48613-A2DF-4286-9467-E3BCB23CD8F4} /qn /norestart /passive
start /wait msiexec /x {872B1C80-38EC-4A31-A25C-980820593900} /qn /norestart /passive
start /wait msiexec /x {70F9BF10-3729-4333-BCBE-5218F69582FA} /qn /norestart /passive
start /wait msiexec /x {A535F266-291E-447F-ABE6-0BE17D0CB036} /qn /norestart /passive
start /wait msiexec /x {19484EF1-E27A-43D1-9EEB-685D41888AC8} /qn /norestart /passive

:: HP Trust Circles
start /wait msiexec /x {C4E9E8A4-EEC4-4F9E-B140-520A8B75F430} /qn /norestart /passive
start /wait msiexec /x {0DF3F266-B52E-4309-B3CC-233607DF4E50} /qn /norestart /passive

:: HP SolutionCenter
start /wait msiexec /x {9603DE6D-4567-4b78-B941-849322373DE2} /qn /norestart /passive
start /wait msiexec /x {4A70EF07-7F88-4434-BB61-D1DE8AE93DD4} /qn /norestart /passive
start /wait msiexec /x {3C023AD6-4740-479A-8B7A-B5718F240268} /qn /norestart /passive
start /wait msiexec /x {A5AB9D5E-52E2-440e-A3ED-9512E253C81A} /qn /norestart /passive

:: HP UnloadSupport (hidden)
start /wait msiexec /x {E06F04B9-45E6-4AC0-8083-85F7515F40F7} /qn /norestart /passive

:: HP Update
start /wait msiexec /x {787D1A33-A97B-4245-87C0-7174609A540C} /qn /norestart /passive
start /wait msiexec /x {97486FBE-A3FC-4783-8D55-EA37E9D171CC} /qn /norestart /passive
start /wait msiexec /x {117BBDE7-472E-4DCD-BAAE-410A0794A335} /qn /norestart /passive
start /wait msiexec /x {6FE8E073-D159-4419-93E2-CE2C5B078562} /qn /norestart /passive
start /wait msiexec /x {DCEA910B-3269-4F5B-A915-D59293004751} /qn /norestart /passive
start /wait msiexec /x {AE856388-AFAD-4753-81DF-D96B19D0A17C} /qn /norestart /passive
start /wait msiexec /x {85D645CF-0F3B-477A-A9C9-194917F1A75B} /qn /norestart /passive
start /wait msiexec /x {2EA3D6B2-157E-4112-A3AB-BF17E16661C3} /qn /norestart /passive
start /wait msiexec /x {6ECB39BD-73C2-44DD-B1A0-898207C58D8B} /qn /norestart /passive
start /wait msiexec /x {962CB079-85E6-405F-8704-1C62365AE46F} /qn /norestart /passive
start /wait msiexec /x {904822F1-6C7D-4B91-B936-6A1C0810544C} /qn /norestart /passive

:: HP USB Docking Video (wtf?)
start /wait msiexec /x {B0069CFA-5BB9-4C03-B1C6-89CE290E5AFE} /qn /norestart /passive

:: HP UserGuide, UserProfileManager SDK Snap-in
start /wait msiexec /x {C23415D8-FE94-4F52-B5C4-0FFA2202C6D9} /qn /norestart /passive
start /wait msiexec /x {F07C2CF8-4C53-4EC3-8162-A6221E36EB88} /qn /norestart /passive

:: HP Utility Center
start /wait msiexec /x {B7B82520-8ECE-4743-BFD7-93B16C64B277} /qn /norestart /passive
start /wait msiexec /x {35021DFB-F9CA-402A-89A2-47F91E506465} /qn /norestart /passive

:: HP Vision Hardware Diagnostics
start /wait msiexec /x {D7670221-BF9B-4DFF-B26B-5BE55A87329F} /qn /norestart /passive

:: HP Wallpaper 3.0.0.1
start /wait msiexec /x {11B83AD3-7A46-4C2E-A568-9505981D4C6F} /qn /norestart /passive

:: HP Web Camera 1.0.0
start /wait msiexec /x {C6363DC5-17A4-4E36-B701-9EC719390D48} /qn /norestart /passive

:: HP WebReg
start /wait msiexec /x {179C56A4-F57F-4561-8BBF-F911D26EB435} /qn /norestart /passive
start /wait msiexec /x {8EE94FD8-5F52-4463-A340-185D16328158} /qn /norestart /passive
start /wait msiexec /x {350C97B0-3D7C-4EE8-BAA9-00BCB3D54227} /qn /norestart /passive
start /wait msiexec /x {29FA38B4-0AE4-4D0D-8A51-6165BB990BB0} /qn /norestart /passive
start /wait msiexec /x {43CDF946-F5D9-4292-B006-BA0D92013021} /qn /norestart /passive
start /wait msiexec /x {087A66B8-1F0F-4a8d-A649-0CFE276AA7C0} /qn /norestart /passive
start /wait msiexec /x {06C4BA69-5210-4707-B5BE-E26D487E1854} /qn /norestart /passive
start /wait msiexec /x {14CF9AF8-10A6-4FA7-9E57-D22DBD644C77} /qn /norestart /passive

:: HP Wireless Assistant // Wireless Button Driver // Wireless Hotspot
start /wait msiexec /x {9AB1B6EC-AEA4-4D78-ADDB-0291BF7230F4} /qn /norestart /passive
start /wait msiexec /x {547607B0-3294-4ECA-8F5E-921404676CBB} /qn /norestart /passive
start /wait msiexec /x {13133E99-B0D5-4143-B832-AAD55C62A41C} /qn /norestart /passive
start /wait msiexec /x {92F7E378-0F27-4D1E-ACAE-2AA7E546D082} /qn /norestart /passive
start /wait msiexec /x {3082CB96-66E8-456D-8326-118A4F5DC0C6} /qn /norestart /passive
start /wait msiexec /x {CFD917BE-F1F6-410E-ABEC-9EC819507D0D} /qn /norestart /passive
start /wait msiexec /x {5601F151-A69F-4E30-8C60-37928124CD07} /qn /norestart /passive

:: Instant Housecall Specialist Sign-in
start /wait msiexec /x {4A89B7B3-EB5B-4B33-B7B4-99E69792C081} /qn /norestart /passive

:: Intel IdentityMine Air Hockey
start /wait msiexec /x {DF5DB383-DEEF-4649-8691-58353C928CCA} /qn /norestart /passive

:: Intel(R) Identity Protection Technology
start /wait msiexec /x {C01A86F5-56E7-101F-9BC9-E3F1025EB779} /qn /norestart /passive
start /wait msiexec /x {BE77874C-0353-49DF-A5BC-36A8FE51D95E} /qn /norestart /passive
start /wait msiexec /x {EAF826C0-245E-4D02-9D51-BA4C98717EAE} /qn /norestart /passive

:: Intel (R) Pro Alerting Agent
start /wait msiexec /x {FCDDBA94-7389-49E5-B287-2661460BAF18} /qn /norestart /passive

:: Intel(R) Rapid Storage Technology
start /wait msiexec /x {96714280-14E6-4DF7-BACD-F797C0F17C3D} /qn /norestart /passive

:: Intel(R) Smart Connect Technology
start /wait msiexec /x {9B5FD763-5074-474C-B898-24567E6450C8} /qn /norestart /passive

:: Intel(R) Technology Access
start /wait msiexec /x {413fe921-b226-41c8-bc3c-574074ceec4d} /qn /norestart /passive
start /wait msiexec /x {583882E7-EA75-4BF0-94FA-7DD5A3731C76} /qn /norestart /passive

:: Intel(R) Trusted Connect Service Client
start /wait msiexec /x {1B444AF9-1DBE-4884-8F35-969BEFCF69A8} /qn /norestart /passive
start /wait msiexec /x {7D84E343-A23D-451C-B123-0195B2D903A6} /qn /norestart /passive
start /wait msiexec /x {457D6189-416A-44CD-A0A6-D6D75AD25CCF} /qn /norestart /passive
start /wait msiexec /x {EB5FF09B-F44E-416D-ACEC-3AE0BE72C900} /qn /norestart /passive
start /wait msiexec /x {09536BA1-E498-4CC3-B834-D884A67D7E34} /qn /norestart /passive
start /wait msiexec /x {F27A944C-C95A-4DB7-BC8A-AEFD9B1B5E40} /qn /norestart /passive
start /wait msiexec /x {89AFB053-A343-46EF-97E4-D593AD7184E6} /qn /norestart /passive
start /wait msiexec /x {B5E49E64-0C1B-49AD-AE21-119CE68750E9} /qn /norestart /passive
start /wait msiexec /x {6548B189-BEA4-4041-80E0-AEB60548E046} /qn /norestart /passive
start /wait msiexec /x {F4404AFD-2EF3-40C1-8C09-29E5F3B6972B} /qn /norestart /passive
start /wait msiexec /x {3DE97849-544D-4D68-9255-11DF6F9F10D8} /qn /norestart /passive
start /wait msiexec /x {7AB8C73F-03FE-48AE-990C-CCB8D6C4FAB8} /qn /norestart /passive
start /wait msiexec /x {977D1ABF-4089-4CA7-BA33-CC75808B7ACE} /qn /norestart /passive
start /wait msiexec /x {A61059F4-F902-4417-8ED2-20A29972EC40} /qn /norestart /passive
start /wait msiexec /x {3181229B-05DA-46F9-B8D4-4966BDA99A74} /qn /norestart /passive
start /wait msiexec /x {181BBF43-CA17-4E1A-A78D-81E67A57B8A4} /qn /norestart /passive
start /wait msiexec /x {51A66ED3-200E-4147-8D1E-E8D30936FD26} /qn /norestart /passive
start /wait msiexec /x {44B72151-611E-429D-9765-9BA093D7E48A} /qn /norestart /passive

:: Intel(R) Wake on Voice 1.0.6
start /wait msiexec /x {A39CDDD2-3FB3-4C98-BDE9-E3032443417C} /qn /norestart /passive

:: Intel(R) Trusted Execution Engine
start /wait msiexec /x {E14B99BA-3282-4990-8BD7-20FD584A217F} /qn /norestart /passive

:: Intel(R) Trusted Execution Engine Driver
start /wait msiexec /x {4021582A-4C27-4482-A287-5D49B80DB48F} /qn /norestart /passive

:: Intel(R) Turbo Boost Technology
start /wait msiexec /x {D6C630BF-8DBB-4042-8562-DC9A52CB6E7E} /qn /norestart /passive
start /wait msiexec /x {B7368FC9-A295-4A95-A9EB-AFD659BA7B71} /qn /norestart /passive

:: Intel Update
start /wait msiexec /x {78091D68-706D-4893-B287-9F1DFB24F7AF} /qn /norestart /passive

:: Intel Update Manager
start /wait msiexec /x {608E1B9B-A2E8-4A1F-8BAB-874EB0DD25E3} /qn /norestart /passive
start /wait msiexec /x {43FA4AC8-46F8-423F-96FD-9A7D67048F1C} /qn /norestart /passive
start /wait msiexec /x {75060E95-A018-47BD-BCC5-06DE7DB2744D} /qn /norestart /passive
start /wait msiexec /x {0D01BDA8-C995-40AD-95F8-26B7EA4DCF9F} /qn /norestart /passive
start /wait msiexec /x {83F793B5-8BBF-42FD-A8A6-868CB3E2AAEA} /qn /norestart /passive
start /wait msiexec /x {43A76F9B-48F1-4E0D-A9B4-8E4F6C42E28C} /qn /norestart /passive

:: Intel Viiv(TM) various software GUIDs
start /wait msiexec /x {A6C48A9F-694A-4234-B3AA-62590B668927} /qn /norestart /passive
start /wait msiexec /x {F007CBCE-D714-4C0B-8CE9-9B0D78116468} /qn /norestart /passive

:: Intel WiMAX Tutorial
start /wait msiexec /x {4F26C164-9373-4974-8F43-E0F2176AF937} /qn /norestart /passive

:: _is1 iolo technologies' System Mechanic Professional and UniBlue DriverScanner
start /wait msiexec /x {BBD3F66B-1180-4785-B679-3F91572CD3B4} /qn /norestart /passive
start /wait msiexec /x {C2F8CA82-2BD9-4513-B2D1-08A47914C1DA} /qn /norestart /passive

:: iSEEK AnswerWorks English Runtime
start /wait msiexec /x {18A8E78B-9EF2-496E-B310-BCD8E4C1DAB3} /qn /norestart /passive
start /wait msiexec /x {DBCC73BA-C69A-4BF5-B4BF-F07501EE7039} /qn /norestart /passive
start /wait msiexec /x {FE0133FE-9AEE-4A36-9F46-749E069540D3} /qn /norestart /passive

:: Java Auto Updater
start /wait msiexec /x {4A03706F-666A-4037-7777-5F2748764D10} /qn /norestart /passive
start /wait msiexec /x {CCB6114E-9DB9-BD54-5AA0-BC5123329C9D} /qn /norestart /passive
start /wait msiexec /x {32A3A4F4-B792-11D6-A78A-00B0D0170550} /qn /norestart /passive

:: Kaspersky Lab Network Agent
start /wait msiexec /x {786A9F7E-CFEC-451F-B3C4-22EB11550FD8} /qn /norestart /passive

:: KODAK Share Button App
start /wait msiexec /x {DE9B51D7-C575-4587-A848-DE95CD7F7684} /qn /norestart /passive

:: Lenovo Idea Notes
start /wait msiexec /x {BF601122-9F0A-41A9-BA06-3158D9FB4B80} /qn /norestart /passive

:: Lenovo Message Center Plus
start /wait msiexec /x {3849486C-FF09-4F5D-B491-3E179D58EE15} /qn /norestart /passive
start /wait msiexec /x {7F8205DE-DDFA-4156-ADA2-766E9CB4FABC} /qn /norestart /passive
start /wait msiexec /x {8C6D6116-B724-4810-8F2D-D047E6B7D68E} /qn /norestart /passive

:: Lenovo Metric Collection SDK
start /wait msiexec /x {DDAA788F-52E6-44EA-ADB8-92837B11BF26} /qn /norestart /passive
start /wait msiexec /x {C2B5B5B0-2545-4E94-B4BA-548D4BF0B196} /qn /norestart /passive
start /wait msiexec /x {50816F92-1652-4A7C-B9BC-48F682742C4B} /qn /norestart /passive

:: Lenovo Patch Utility
start /wait msiexec /x {C6FB6B4A-1378-4CD3-9CD3-42BA69FCBD43} /qn /norestart /passive

:: Lenovo Reach and REACHit
start /wait msiexec /x {3245D8C8-7FE0-4FD4-B04B-2720A333D592} /qn /norestart /passive
start /wait msiexec /x {0B5E0E89-4BCA-4035-BBA1-D1439724B6E2} /qn /norestart /passive
start /wait msiexec /x {4532E4C5-C84D-4040-A044-ECFCC5C6995B} /qn /norestart /passive

:: Lenovo Registration
start /wait msiexec /x {6707C034-ED6B-4B6A-B21F-969B3606FBDE} /qn /norestart /passive

:: Lenovo SimpleTap
start /wait msiexec /x {C0C17EF3-83ED-4956-8638-7354EBE7FFFF} /qn /norestart /passive
start /wait msiexec /x {792920BD-8D8D-4868-AE2F-16F4B05D3AE9} /qn /norestart /passive

:: Lenovo Slim USB Keyboard
start /wait msiexec /x {2DC26D10-CC6A-494F-BEA3-B5BC21126D5E} /qn /norestart /passive

:: Lenovo SMB Customizations
start /wait msiexec /x {AFD7B869-3B70-40C7-8983-769256BA3BD2} /qn /norestart /passive

:: Lenovo System Update
start /wait msiexec /x {25097770-2B1F-49F6-AB9D-1C708B96262A} /qn /norestart /passive

:: Lenovo Solution Center
start /wait msiexec /x {63942F7E-3646-45EC-B8A9-EAC40FEB66DB} /qn /norestart /passive
start /wait msiexec /x {13BD494D-9ACD-420B-A291-E145DED92EF6} /qn /norestart /passive
start /wait msiexec /x {4C2B6F96-3AED-4E3F-8DCE-917863D1E6B1} /qn /norestart /passive
start /wait msiexec /x {494D80C4-3557-4D73-A153-65FE4B3ECDC3} /qn /norestart /passive

:: Lenovo System Update
start /wait msiexec /x {25C64847-B900-48AD-A164-1B4F9B774650} /qn /norestart /passive
start /wait msiexec /x {8675339C-128C-44DD-83BF-0A5D6ABD8297} /qn /norestart /passive
start /wait msiexec /x {C9335768-C821-DD44-38FB-A0D5A6DB2879} /qn /norestart /passive

:: Lenovo ThinkVantage: Active Protection System // Fingerprint Software // System Update
start /wait msiexec /x {10F5A72A-1E07-4FAE-A7E7-14B10CC66B17} /qn /norestart /passive
start /wait msiexec /x {46A84694-59EC-48F0-964C-7E76E9F8A2ED} /qn /norestart /passive
start /wait msiexec /x {479016BF-5B8D-445F-BE15-A187F25D81C8} /qn /norestart /passive

:: Lenovo User Guide
start /wait msiexec /x {13F59938-C595-479C-B479-F171AB9AF64F} /qn /norestart /passive
start /wait msiexec /x {A923CF0A-44D9-4357-B2E8-0A2352151A3C} /qn /norestart /passive

:: Lenovo Warranty Info
start /wait msiexec /x {FD4EC278-C1B1-4496-99ED-C0BE1B0AA521} /qn /norestart /passive
start /wait msiexec /x {EFC9FE7C-ECE8-4282-8F77-FEDCAD374C77} /qn /norestart /passive

:: Lenovo Web Start
if exist "%LOCALAPPDATA%\Pokki\Engine\HostAppService.exe" "%LOCALAPPDATA%\Pokki\Engine\HostAppService.exe" /UNINSTALL04bb6df446330549a2cb8d67fbd1a745025b7bd1 2>NUL

:: Lenovo Welcome
start /wait msiexec /x {1CA74803-5CB2-4C03-BDBE-061EDC81CC7F} /qn /norestart /passive

:: LightScribe
start /wait msiexec /x {6226477E-444F-4DFE-BA19-9F4F7D4565BC} /qn /norestart /passive
start /wait msiexec /x {A87B11AC-4344-4E5D-8B12-8F471A87DAD9} /qn /norestart /passive
start /wait msiexec /x {D755C7A3-C03E-4460-8C00-AC6E55505FB5} /qn /norestart /passive
start /wait msiexec /x {FA8BFB25-BF48-4F8B-8859-B30810745190} /qn /norestart /passive

:: Logitech eReg // Harmony Remote Software // Updater
start /wait msiexec /x {3EE9BCAE-E9A9-45E5-9B1C-83A4D357E05C} /qn /norestart /passive
start /wait msiexec /x {53735ECE-E461-4FD0-B742-23A352436D3A} /qn /norestart /passive
start /wait msiexec /x {B5DA9D49-9BD8-0F2F-52FC-C7E66BC8D944} /qn /norestart /passive

:: LWS Facebook // Gallery // Help_main // Launcher // Motion Detection // Pictures And Video // Twitter // Webcam Software // WLM Plugin // YouTube Plugin
start /wait msiexec /x {9DAEA76B-E50F-4272-A595-0124E826553D} /qn /norestart /passive
start /wait msiexec /x {21DF0294-6B9D-4741-AB6F-B2ABFBD2387E} /qn /norestart /passive
start /wait msiexec /x {08610298-29AE-445B-B37D-EFBE05802967} /qn /norestart /passive
start /wait msiexec /x {71E66D3F-A009-44AB-8784-75E2819BA4BA} /qn /norestart /passive
start /wait msiexec /x {6F76EC3C-34B1-436E-97FB-48C58D7BEDCD} /qn /norestart /passive
start /wait msiexec /x {B38E9B55-7136-4E66-A084-320512FF3F6F} /qn /norestart /passive
start /wait msiexec /x {1651216E-E7AD-4250-92A1-FB8ED61391C9} /qn /norestart /passive
start /wait msiexec /x {83C8FA3C-F4EA-46C4-8392-D3CE353738D6} /qn /norestart /passive
start /wait msiexec /x {8937D274-C281-42E4-8CDB-A0B2DF979189} /qn /norestart /passive
start /wait msiexec /x {174A3B31-4C43-43DD-866F-73C9DB887B48} /qn /norestart /passive

:: Setup1 (??)
start /wait msiexec /x {86091EC1-DD17-4814-A54B-0A634CB8D82C} /qn /norestart /passive

:: Snap.Do (browser hijacker)
start /wait msiexec /x {CC6F61A9-A55E-4D04-A674-7A498CD8B809} /qn /norestart /passive

:: SSN Librarian (some sketchy Russian program)
start /wait msiexec /x {1D425886-3FE1-41AA-8D7A-E432CE29A4AE} /qn /norestart /passive

:: Steam 1.0.0.0 (malware; not Valve's Steam)
start /wait msiexec /x {AE8705FB-E13C-40A9-8A2D-68D6733FBFC2} /qn /norestart /passive

:: SupportSoft Assisted Service 15 // SupportUtility (various versions)
start /wait msiexec /x {3002C8EB-2A7E-419B-B77F-5AD7E9F54A5A} /qn /norestart /passive
start /wait msiexec /x {31AF8802-BF43-4C43-984B-EC597CF51505} /qn /norestart /passive
start /wait msiexec /x {5A3F6A80-7913-475E-8B96-477A952CFA43} /qn /norestart /passive

:: Macromedia Flash Player 7 (!!)
start /wait msiexec /x {DA7F7862-AB37-4464-B4CF-1256EC5E4B65} /qn /norestart /passive

:: MarketResearch
start /wait msiexec /x {175F0111-2968-4935-8F70-33108C6A4DE3} /qn /norestart /passive
start /wait msiexec /x {13F00518-807A-4B3A-83B0-A7CD90F3A398} /qn /norestart /passive
start /wait msiexec /x {D2E0F0CC-6BE0-490b-B08B-9267083E34C9} /qn /norestart /passive
start /wait msiexec /x {b145ec69-66f5-11d8-9d75-000129760d75} /qn /norestart /passive

:: Maxx Audio Installer (x64)
start /wait msiexec /x {D9428275-602F-4D4B-A921-9CC642B76995} /qn /norestart /passive

:: McAfee LiveSafe - Internet Security
if exist "%ProgramFiles(x86)%\McAfee\MSC\mcuihost.exe" "%ProgramFiles(x86)%\McAfee\MSC\mcuihost.exe" /body:misp://MSCJsRes.dll::uninstall.html /id:uninstall 2>NUL
if exist "%ProgramFiles%\McAfee\MSC\mcuihost.exe" "%ProgramFiles%\McAfee\MSC\mcuihost.exe" /body:misp://MSCJsRes.dll::uninstall.html /id:uninstall 2>NUL

:: Media Gallery
start /wait msiexec /x {115B60D5-BBDB-490E-AF2E-064D37A3CE01} /qn /norestart /passive

:: Microsoft Application Error Reporting
start /wait msiexec /x {95120000-00B9-0409-1000-0000000FF1CE} /qn /norestart /passive

:: Microsoft DVD App Installation for Microsoft.WindowsDVDPlayer_2019.6.11761.0_neutral_~_8wekyb3d8bbwe (x64)
start /wait msiexec /x {986E003C-E56D-5A47-110E-D3C81F0E8535} /qn /norestart /passive

:: Microsoft Mouse and Keyboard Center (various versions)
start /wait msiexec /x {91150000-0051-0000-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {7A56D81D-6406-40E7-9184-8AC1769C4D69} /qn /norestart /passive
start /wait msiexec /x {B8A9EB6B-E41A-4B69-B996-3BFCFA743E5C} /qn /norestart /passive
start /wait msiexec /x {E20B2752-0909-4B28-B8A9-A9BE519CA1A1} /qn /norestart /passive
start /wait msiexec /x {22F9A831-CA56-4406-85FE-47FFB0472804} /qn /norestart /passive

:: Microsoft Office 15 Click-to-Run Extensibility Component (various versions)
start /wait msiexec /x {90150000-008C-0000-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90150000-007E-0000-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {D535FC73-1F63-4347-896A-C97A45F11E9C} /qn /norestart /passive
start /wait msiexec /x {90150000-007E-0000-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90150000-008C-0409-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90150000-008C-0000-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90150000-008C-0409-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90150000-008F-0000-1000-0000000FF1CE} /qn /norestart /passive

:: Microsoft Office 2007 "Get Started Tab" for PowerPoint, Excel, and Word
start /wait msiexec /x {5AE5DB70-5CE6-4876-A83E-8246CC36FC28} /qn /norestart /passive
start /wait msiexec /x {AB706D91-2242-4E1D-B4D0-1ED35387F5A7} /qn /norestart /passive
start /wait msiexec /x {68B52EFD-86CC-486E-A8D0-A3A1554CB5BC} /qn /norestart /passive

:: Microsoft Office Click-to-Run 2010 14.0.4763.1000
start /wait msiexec /x {90140000-006D-0409-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90140000-0054-0409-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90140000-006D-0409-0000-0000000FF1CE} /qn /norestart /passive

:: Microsoft Office File Validation Add-In (frequently causes Excel to hang)
start /wait msiexec /x {90140000-2005-0000-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90140000-1138-0000-1000-0000000FF1CE} /qn /norestart /passive

:: Microsoft Office Groove (various versions); I've NEVER seen anyone use this; if you encounter a user actually using it in the wild let me know and we'll remove it from this list
start /wait msiexec /x {91120000-00A1-0000-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90140000-00A1-0409-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {91140000-0057-0000-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90120000-00B4-0409-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90140000-00BA-0000-1000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90140000-00BA-0409-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x {90120000-00D1-0409-0000-0000000FF1CE} /qn /norestart /passive

:: Microsoft OGA Notifier (Windows "Genuine Advantage" popup nagger)
start /wait msiexec /x {90150000-008F-0000-1000-0000000FF1CE} /qn /norestart /passive

:: Microsoft Search Enhancement Pack
start /wait msiexec /x {4CBA3D4C-8F51-4D60-B27E-F6B641C571E7} /qn /norestart /passive

:: Microsoft Tablet PC Tutorials for Microsoft Windows XP SP2 1.7
start /wait msiexec /x {F2BF3E35-8AF4-4DFF-8C07-C3B05B8E2126} /qn /norestart /passive

:: Modem Diagnostic Tool
start /wait msiexec /x {779DECD7-E072-4B56-9B6B-BEB5973EEEB5} /qn /norestart /passive

:: MobileME Control Panel (deprecated Apple service)
start /wait msiexec /x {AC2BA148-EE9C-4F1A-AFCE-F38C2C71D29B} /qn /norestart /passive
start /wait msiexec /x {3AC54383-31D1-4907-961B-B12CBB1D0AE8} /qn /norestart /passive

:: MSN Explorer Repair Tool
start /wait msiexec /x {3D36105D-D6C2-413A-9355-7370E8D9125B} /qn /norestart /passive

:: MSN Toolbar Platform
start /wait msiexec /x {C9D43B38-34AD-4EC2-B696-46F42D49D174} /qn /norestart /passive

:: My Way Search Assistant
start /wait msiexec /x {05F1B866-2372-4E82-9AA8-C64FB11CEF8B} /qn /norestart /passive

:: NetTALK DUO Wifi Management Tool
start /wait msiexec /x {15D27BA3-6CCD-4848-8925-07EF083492AD} /qn /norestart /passive

:: Network64, HP? malware?
start /wait msiexec /x {6BFAB6C1-6D46-46DB-A538-A269907C9F2F} /qn /norestart /passive
start /wait msiexec /x {48C0866E-57EB-444C-8371-8E4321066BC3} /qn /norestart /passive

:: NETGEAR A6100 Genie 1.0.0.12
start /wait msiexec /x {56C049BE-79E9-4502-BEA7-9754A3E60F9B} /qn /norestart /passive

:: Norton 360 // Internet Security // Online Backup
start /wait msiexec /x {E4FC1ED9-E20C-4621-B834-03C388278DD8} /qn /norestart /passive
start /wait msiexec /x {63A6E9A9-A190-46D4-9430-2DB28654AFD8} /qn /norestart /passive
start /wait msiexec /x {7B15D70E-9449-4CFB-B9BC-798465B2BD5C} /qn /norestart /passive
start /wait msiexec /x {40A66DF6-22D3-44B5-A7D3-83B118A2C0DC} /qn /norestart /passive

:: Nuance Cloud Connector
start /wait msiexec /x {EEE31B2B-F517-4BD2-8F92-57E4AE938BA3} /qn /norestart /passive

:: Nuance PDF Viewer Plus
start /wait msiexec /x {042A6F10-F770-4886-A502-B795DCF2D3B5} /qn /norestart /passive

:: NVIDIA HD Audio Driver
start /wait msiexec /x {B2FE1952-0186-46C3-BAEC-A80AA35AC5B8} /qn /norestart /passive

:: Office 2013 C2R Suite
start /wait msiexec /x {90150000-0138-0409-0000-0000000FF1CE} /qn /norestart /passive
start /wait msiexec /x "C:\ProgramData\Microsoft\OEMOffice15\OOBE\x86\oemoobe.msi" /qn /norestart

:: opensource
start /wait msiexec /x {3677D4D8-E5E0-49FC-B86E-06541CF00BBE} /qn /norestart /passive
start /wait msiexec /x {E6B87DC4-2B3D-4483-ADFF-E483BF718991} /qn /norestart /passive

:: P@H-Protocol (coupon nagware/bloatware)
start /wait msiexec /x {14F936AB-5D31-410E-A4E2-70AE504712F2} /qn /norestart /passive
start /wait msiexec /x {2D91C34E-12CC-4B1B-90D5-31DAD47B6F48} /qn /norestart /passive

:: Panasonic Common Components for Panasonic PC 3.0.1400.100
start /wait msiexec /x {7804E86D-6DA1-1014-8C88-F05533644796} /qn /norestart /passive

:: PaperVision Web Assistant
start /wait msiexec /x {739843A9-A2D0-4994-8DE0-AF9FF1BB1A27} /qn /norestart /passive

:: Perion Networks Photo Notifier and Animation Creator
start /wait msiexec /x {722CD95C-98C7-4E73-925A-68D2D4F651A6} /qn /norestart /passive

:: Plantronics MyHeadset Updater
start /wait msiexec /x {24116AB5-8147-42F6-9A09-6B26DBBCE584} /qn /norestart /passive
start /wait msiexec /x {7D7B61A3-22AC-4141-B88E-5F695128DAD0} /qn /norestart /passive
start /wait msiexec /x {3728D9BC-8267-4546-B359-E7855CA3BEA0} /qn /norestart /passive
start /wait msiexec /x {35806341-97A1-464A-A809-BC5F62E08439} /qn /norestart /passive
start /wait msiexec /x {9F94F9AC-CFFF-477A-AF0A-FF443FEF0261} /qn /norestart /passive
start /wait msiexec /x {15B1D4C6-A245-41CD-96E8-5C63E37DDBFF} /qn /norestart /passive
start /wait msiexec /x {26A67848-1222-4691-B5BA-7E026585886B} /qn /norestart /passive

:: PlayReady PC Runtime amd64 // x86
start /wait msiexec /x {BCA9334F-B6C9-4F65-9A73-AC5A329A4D04} /qn /norestart /passive
start /wait msiexec /x {20D4A895-748C-4D88-871C-FDB1695B0169} /qn /norestart /passive

:: PlayStation(R)Network Downloader (hidden)
start /wait msiexec /x {B6659DD8-00A7-4A24-BBFB-C1F6982E5D66} /qn /norestart /passive

:: PlayStation(R)Store (hidden)
start /wait msiexec /x {0E532C84-4275-41B3-9D81-D4A1A20D8EE7} /qn /norestart /passive

:: PSE10 STI Installer
start /wait msiexec /x {11D08055-939C-432b-98C3-E072478A0CD7} /qn /norestart /passive

:: QualxServ Service Agreement
start /wait msiexec /x {18401E1E-1E44-461A-A4B2-E48B1A727818} /qn /norestart /passive
start /wait msiexec /x {A84A4FB1-D703-48DB-89E0-68B6499D2801} /qn /norestart /passive
start /wait msiexec /x {903679E8-44C8-4C07-9600-05C92654FC50} /qn /norestart /passive

:: QuickTime 7
start /wait msiexec /x {3D2CBC2C-65D4-4463-87AB-BB2C859C1F3E} /qn /norestart /passive
start /wait msiexec /x {AF0CE7C0-A3E4-4D73-988B-B29187EC6E9A} /qn /norestart /passive
start /wait msiexec /x {627FFC10-CE0A-497F-BA2B-208CAC638010} /qn /norestart /passive
start /wait msiexec /x {87CF757E-C1F1-4D22-865C-00C6950B5258} /qn /norestart /passive
start /wait msiexec /x {28BE306E-5DA6-4F9C-BDB0-DBA3C8C6FFFD} /qn /norestart /passive
start /wait msiexec /x {57752979-A1C9-4C02-856B-FBB27AC4E02C} /qn /norestart /passive
start /wait msiexec /x {7BE15435-2D3E-4B58-867F-9C75BED0208C} /qn /norestart /passive
start /wait msiexec /x {80CEEB1E-0A6C-45B9-A312-37A1D25FDEBC} /qn /norestart /passive
start /wait msiexec /x {111EE7DF-FC45-40C7-98A7-753AC46B12FB} /qn /norestart /passive
start /wait msiexec /x {1451DE6B-ABE1-4F62-BE9A-B363A17588A2} /qn /norestart /passive
start /wait msiexec /x {B67BAFBA-4C9F-48FA-9496-933E3B255044} /qn /norestart /passive
start /wait msiexec /x {A429C2AE-EBF1-4F81-A221-1C115CAADDAD} /qn /norestart /passive

:: RapidBoot Shield
start /wait msiexec /x {D446E416-1045-4C70-9341-F73333DCB149} /qn /norestart /passive

:: Recovery Manager
start /wait msiexec /x {44B2A0AB-412E-4F8C-B058-D1E8AECCDFF5} /qn /norestart /passive
start /wait msiexec /x {C7231F7C-6530-4E65-ADA6-5B392CF5BEB1} /qn /norestart /passive

:: RealDownloader
start /wait msiexec /x {C8E8D2E3-EF6A-4B1D-A09E-7B27EBE2F3CE} /qn /norestart /passive
start /wait msiexec /x {2259DBC1-EFFB-42B5-BA35-DFC0AAB2B3FB} /qn /norestart /passive
start /wait msiexec /x {B0235718-21E0-4A90-A42F-9C64C1B531CD} /qn /norestart /passive
start /wait msiexec /x {3DC873BB-FFE3-46BF-9701-26B9AE371F9F} /qn /norestart /passive
start /wait msiexec /x {F1D90260-417F-4EB3-9F7B-1D8C86D910A2} /qn /norestart /passive
start /wait msiexec /x {F8D2BE6A-B725-47CD-A931-639A24B8EF10} /qn /norestart /passive
start /wait msiexec /x {6FCD4D5A-20B9-4D79-ABA5-4E7048944025} /qn /norestart /passive
start /wait msiexec /x {EA1FAE0F-2354-4E32-B423-ABAE8E358F91} /qn /norestart /passive

:: RealNetworks - Microsoft Visual C++ 2008/2010 runtime 9/10
start /wait msiexec /x {21E47F47-C9A7-4454-BA48-388327B0EA00} /qn /norestart /passive
start /wait msiexec /x {7770E71B-2D43-4800-9CB3-5B6CAAEBEBEA} /qn /norestart /passive
start /wait msiexec /x {F82B6DA3-73AC-4563-8BF8-4A24551CF64C} /qn /norestart /passive

:: Roxio GUIDs; too many to list, Google individual GUID if a Roxio program you want to keep is getting removed
start /wait msiexec /x {098122AB-C605-4853-B441-C0A4EB359B75} /qn /norestart /passive
start /wait msiexec /x {537BF16E-7412-448C-95D8-846E85A1D817} /qn /norestart /passive
start /wait msiexec /x {60B2315F-680F-4EB3-B8DD-CCDC86A7CCAB} /qn /norestart /passive
start /wait msiexec /x {0394CDC8-FABD-4ed8-B104-03393876DFDF} /qn /norestart /passive
start /wait msiexec /x {33FE019D-01E1-4B0F-8D7A-BE2D54B9FA22} /qn /norestart /passive
start /wait msiexec /x {9569E6BC-326A-432F-97AB-35263A327BF1} /qn /norestart /passive
start /wait msiexec /x {CCEAD6DE-A863-497A-A5C0-464AB06B47FD} /qn /norestart /passive
start /wait msiexec /x {48A669A9-76FA-4CA8-BFD5-00C125AC4166} /qn /norestart /passive
start /wait msiexec /x {A121EEDE-C68F-461D-91AA-D48BA226AF1C} /qn /norestart /passive
start /wait msiexec /x {938B1CD7-7C60-491E-AA90-1F1888168240} /qn /norestart /passive
start /wait msiexec /x {74DC8A26-4E05-40B6-AD11-C9428A1AE150} /qn /norestart /passive
start /wait msiexec /x {67CA389E-E759-4181-99FA-CD8B63853FB1} /qn /norestart /passive
start /wait msiexec /x {B05B22B8-72AE-4DC3-8D6F-FBC2233CAF41} /qn /norestart /passive
start /wait msiexec /x {EC877639-07AB-495C-BFD1-D63AF9140810} /qn /norestart /passive
start /wait msiexec /x {07159635-9DFE-4105-BFC0-2817DB540C68} /qn /norestart /passive
start /wait msiexec /x {120262A6-7A4B-4889-AE85-F5E5688D3683} /qn /norestart /passive
start /wait msiexec /x {0D397393-9B50-4c52-84D5-77E344289F87} /qn /norestart /passive
start /wait msiexec /x {C8B0680B-CDAE-4809-9F91-387B6DE00F7C} /qn /norestart /passive
start /wait msiexec /x {7746BFAA-2B5D-4FFD-A0E8-4558F4668105} /qn /norestart /passive
start /wait msiexec /x {BACE8BFA-8F39-421D-BEF1-6E78632BDC90} /qn /norestart /passive
start /wait msiexec /x {83FFCFC7-88C6-41c6-8752-958A45325C82} /qn /norestart /passive
start /wait msiexec /x {A33E7B0C-B99C-4EC9-B702-8A328B161AF9} /qn /norestart /passive
start /wait msiexec /x {08E81ABD-79F7-49C2-881F-FD6CB0975693} /qn /norestart /passive
start /wait msiexec /x {F6377647-81AF-41C0-BC7E-06CF37E204AB} /qn /norestart /passive
start /wait msiexec /x {30465B6C-B53F-49A1-9EBA-A3F187AD502E} /qn /norestart /passive
start /wait msiexec /x {73A4F29F-31AC-4EBD-AA1B-0CC5F18C8F83} /qn /norestart /passive
start /wait msiexec /x {ED439A64-F018-4DD4-8BA5-328D85AB09AB} /qn /norestart /passive
start /wait msiexec /x {EF56258E-0326-48C5-A86C-3BAC26FC15DF} /qn /norestart /passive
start /wait msiexec /x {386C29BB-2CEA-3511-89A0-D78306B139AA} /qn /norestart /passive
start /wait msiexec /x {66D171AA-670F-4309-9C74-5BA7F7DBA0B3} /qn /norestart /passive
start /wait msiexec /x {1F54DAFA-9261-4A62-B59D-6C9F26B48FE4} /qn /norestart /passive
start /wait msiexec /x {F06B5C4C-8D2E-4B24-9D43-7A45EEC6C878} /qn /norestart /passive
start /wait msiexec /x {619CDD8A-14B6-43a1-AB6C-0F4EE48CE048} /qn /norestart /passive
start /wait msiexec /x {5A06423A-210C-49FB-950E-CB0EB8C5CEC7} /qn /norestart /passive
start /wait msiexec /x {6675CA7F-E51B-4F6A-99D4-F8F0124C6EAA} /qn /norestart /passive
start /wait msiexec /x {F4862B43-A087-4826-8C50-D41646EC7728} /qn /norestart /passive
start /wait msiexec /x {8FE60B86-0B99-426D-8DBE-BEC526FDED71} /qn /norestart /passive
start /wait msiexec /x {B6A26DE5-F2B5-4D58-9570-4FC760E00FCD} /qn /norestart /passive
start /wait msiexec /x {880AF49C-34F7-4285-A8AD-8F7A3D1C33DC} /qn /norestart /passive
start /wait msiexec /x {2F4C24E6-CBD4-4AAC-B56F-C9FD44DE5668} /qn /norestart /passive
start /wait msiexec /x {FE51662F-D8F6-43B5-99D9-D4894AF00F83} /qn /norestart /passive

:: Samsung MagicTunePremium (monitor selection app)
start /wait msiexec /x {79E9C7C5-4FCC-4DFF-B79E-17319E9522F3} /qn /norestart /passive

:: Samsung RAPID Mode
start /wait msiexec /x {2806889C-B2E7-4B91-898B-4C3198BD258F} /qn /norestart /passive
start /wait msiexec /x {ED818A3C-3DF5-CDCF-3DB2-A646D7B31A16} /qn /norestart /passive

:: Samsung Story Album Viewer
start /wait msiexec /x {698BBAD8-B116-495D-B879-0F07A533E57F} /qn /norestart /passive

:: Samsung SW Update (disables Windows Update; wtf Samsung??)
start /wait msiexec /x {AAFEFB05-CF98-48FC-985E-F04CD8AD620D} /qn /norestart /passive

:: ShufflePlusVLOI
start /wait msiexec /x {0A80329D-1B59-4F10-8D1D-924C59B2840B} /qn /norestart /passive

:: Skins 2007/2008/2009/2010
start /wait msiexec /x {BECEB1AC-BFFC-443F-9457-359127BD2DE1} /qn /norestart /passive
start /wait msiexec /x {8573BE35-DA4F-D73F-0BC7-01199875F61C} /qn /norestart /passive
start /wait msiexec /x {06F2B3DC-74F4-300D-D41A-B21B46101CA2} /qn /norestart /passive
start /wait msiexec /x {0C7FDF6A-C463-173A-7957-74042481E593} /qn /norestart /passive

:: SkyFontsT 4.3.0.0
start /wait msiexec /x {E11D4FE9-718A-D54C-9C19-A13CA89B9E18} /qn /norestart /passive

:: Skype Click 2 Call
start /wait msiexec /x {981029E0-7FC9-4CF3-AB39-6F133621921A} /qn /norestart /passive
start /wait msiexec /x {5EE47864-CF84-4629-86A6-50BEFF406BE5} /qn /norestart /passive

:: Skype Toolbars (various versions)
start /wait msiexec /x {6D1221A9-17BF-4EC0-81F2-27D30EC30701} /qn /norestart /passive

:: SlimCleaner Plus  //  SlimDrivers
start /wait msiexec /x {0C0F368E-17C4-4F28-9F1B-B1DA1D96CF7A} /qn /norestart /passive
start /wait msiexec /x {7A3C7E05-EE37-47D6-99E1-2EB05A3DA3F7} /qn /norestart /passive
start /wait msiexec /x {F09879E9-7CA4-460F-B14A-6E55FEFB34F7} /qn /norestart /passive
start /wait msiexec /x {5F5EF771-2B0B-401C-969C-38399DF75D35} /qn /norestart /passive
start /wait msiexec /x {746AB259-6474-4111-8966-1C62F9A6E063} /qn /norestart /passive
start /wait msiexec /x {FC7386E4-B71D-42AA-B6B3-0925D0361069} /qn /norestart /passive
start /wait msiexec /x {5AD12E7A-D739-4451-9BD1-3610EC56D8F5} /qn /norestart /passive

:: Software Updater (various versions)
start /wait msiexec /x {B307472F-7BD9-4040-9255-CE6D6A1196A3} /qn /norestart /passive
start /wait msiexec /x {6623AA80-69BE-4D39-852B-329DDE843FB5} /qn /norestart /passive

:: Sonic products // Activation Module 1 // CinePlayer Decoder Pack (various versions) // DLA
::                // Icons for Lenovo // myDVD LE // RecordNow variations
start /wait msiexec /x {8D337F77-BE7F-41A2-A7CB-D5A63FD7049B} /qn /norestart /passive
start /wait msiexec /x {21657574-BD54-48A2-9450-EB03B2C7FC29} /qn /norestart /passive
start /wait msiexec /x {35E1EC43-D4FC-4E4A-AAB3-20DDA27E8BB0} /qn /norestart /passive
start /wait msiexec /x {5B6BE547-21E2-49CA-B2E2-6A5F470593B1} /qn /norestart /passive
start /wait msiexec /x {9541FED0-327F-4DF0-8B96-EF57EF622F19} /qn /norestart /passive
start /wait msiexec /x {075473F5-846A-448B-BCB3-104AA1760205} /qn /norestart /passive
start /wait msiexec /x {B12665F4-4E93-4AB4-B7FC-37053B524629} /qn /norestart /passive
start /wait msiexec /x {1206EF92-2E83-4859-ACCB-2048C3CB7DA6} /qn /norestart /passive
start /wait msiexec /x {9A00EC4E-27E1-42C4-98DD-662F32AC8870} /qn /norestart /passive
start /wait msiexec /x {AB708C9B-97C8-4AC9-899B-DBF226AC9382} /qn /norestart /passive

:: Sony Keyboard_Shortcuts
start /wait msiexec /x {FE8974B4-479C-4DBA-8544-9E5342ABB26A} /qn /norestart /passive

:: Sony Media Go
start /wait msiexec /x {167A1F6A-9BF2-4B24-83DB-C6D659F680EA} /qn /norestart /passive

:: Sony Messenger (Oasis2Service)
start /wait msiexec /x {E50FC5DB-7CBD-407D-A46E-0C13E45BC386} /qn /norestart /passive

:: Sony OOBE
start /wait msiexec /x {18894D16-5448-4BF9-A128-F7E937322F91} /qn /norestart /passive

:: Sony PlayMemories Home
start /wait msiexec /x {E03CD71A-F595-49DF-9ADC-0CFC93B1B211} /qn /norestart /passive
start /wait msiexec /x {886C0C18-F905-49B2-90BA-EFC0FEDF27C6} /qn /norestart /passive

:: Sony Quick Web Access
start /wait msiexec /x {13EC74A6-4707-4D26-B9B9-E173403F3B08} /qn /norestart /passive

:: Sony Reader for PC
start /wait msiexec /x {CF5B430D-C563-4EE6-803D-A8A133DFCE5E} /qn /norestart /passive

:: Sony Remote Play with Playstation(R)3
start /wait msiexec /x {D56DA747-5FDB-4AD5-9A6A-3481C0ED44BD} /qn /norestart /passive

:: Sony TrackID(TM) with BRAVIA (poor Shazzam clone)
start /wait msiexec /x {858B32BD-121C-4AC8-BD87-CE37C51C03E2} /qn /norestart /passive
start /wait msiexec /x {2F41EF61-A066-4EBF-84F8-21C1B317A780} /qn /norestart /passive

:: Sony VAIO Data Restore Tool
start /wait msiexec /x {5156C9BF-1C27-430B-96D8-7129F11699A8} /qn /norestart /passive

:: Sony VAIO - Media Gallery
start /wait msiexec /x {7C7BC722-BB95-4A6E-9373-DA706D83430B} /qn /norestart /passive
start /wait msiexec /x {0EB7792D-EFA2-42AB-9A22-F33D9458E974} /qn /norestart /passive

:: Sony VAIO - Microsoft Visual C++ 2010 SP1 RUntime 10.0.40219.325
start /wait msiexec /x {34EB42BE-F4D3-44C1-B28E-9740115DB72C} /qn /norestart /passive

:: Sony VAIO - PMB
start /wait msiexec /x {B6A98E5F-D6A7-46FB-9E9D-1F7BF443491C} /qn /norestart /passive

:: Sony VAIO - PMB VAIO Edition Guide (and associated "Plugin" GUIDs)
start /wait msiexec /x {339F9B4D-00CB-4C1C-BED8-EC86A9AB602A} /qn /norestart /passive
start /wait msiexec /x {133D3F07-D558-46CE-80E8-F4D75DBBAD63} /qn /norestart /passive
start /wait msiexec /x {270380EB-8812-42E1-8289-53700DB840D2} /qn /norestart /passive
start /wait msiexec /x {8356CB97-A48F-44CB-837A-A12838DC4669} /qn /norestart /passive

:: Sony VAIO - Remote Keyboard, Remote Keyboard with PlayStation(R)3, Remote Play with Playstation(R)3
start /wait msiexec /x {7396FB15-9AB4-4B78-BDD8-24A9C15D2C65} /qn /norestart /passive
start /wait msiexec /x {6466EF6E-700E-470F-94CB-D0050302C84E} /qn /norestart /passive
start /wait msiexec /x {E682702C-609C-4017-99E7-3129C163955F} /qn /norestart /passive
start /wait msiexec /x {07441A52-E208-478A-92B7-5C337CA8C131} /qn /norestart /passive

:: Sony VAIO Care // VAIO Care Recovery // VAIO Help and Support
start /wait msiexec /x {D9FFE40D-1A85-4541-992C-5EF505F391A4} /qn /norestart /passive
start /wait msiexec /x {55A60C1D-BEBF-4249-BFB2-F4E5C2E77988} /qn /norestart /passive
start /wait msiexec /x {471F7C0A-CA3A-4F4C-8346-DE36AD5E23D1} /qn /norestart /passive
start /wait msiexec /x {6ED1750E-F44F-4635-8F0D-B76B9262B7FB} /qn /norestart /passive
start /wait msiexec /x {AD3E7141-A22E-40F1-A7A4-55E898AE35E3} /qn /norestart /passive

:: Sony VAIO Control Center // CPU Fan Diagnostic // Data Restore Tool // Easy Connect
start /wait msiexec /x {8E797841-A110-41FD-B17A-3ABC0641187A} /qn /norestart /passive
start /wait msiexec /x {BCE6E3D7-B565-4E1B-AC77-F780666A35FB} /qn /norestart /passive
start /wait msiexec /x {3267B2E9-9DF5-4251-87C8-33412234C77F} /qn /norestart /passive
start /wait msiexec /x {57B955CE-B5D3-495D-AF1B-FAEE0540BFEF} /qn /norestart /passive
start /wait msiexec /x {7C80D30A-AC02-4E3F-B95D-29F0E4FF937B} /qn /norestart /passive

:: Sony VAIO Gate // Gate Default // Help and Support // Improvement // Manual // Gesture Control
start /wait msiexec /x {A7C30414-2382-4086-B0D6-01A88ABA21C3} /qn /norestart /passive
start /wait msiexec /x {AE5F3379-8B81-457E-8E09-7E61D941AFA4} /qn /norestart /passive
start /wait msiexec /x {B7546697-2A80-4256-A24B-1C33163F535B} /qn /norestart /passive
start /wait msiexec /x {0164FA3B-182D-4237-B22A-081C0B55E0D3} /qn /norestart /passive
start /wait msiexec /x {3A26D9BD-0F73-432D-B522-2BA18138F7EF} /qn /norestart /passive
start /wait msiexec /x {C6E893E7-E5EA-4CD5-917C-5443E753FCBD} /qn /norestart /passive
start /wait msiexec /x {C8544A9A-76BE-4F82-811E-979799AE493B} /qn /norestart /passive

:: Sony VAIOCareLearnContents
start /wait msiexec /x {05959BC8-751E-43B1-A427-233DA743E179} /qn /norestart /passive

:: Sony VAIO OOB (out of box experience)
start /wait msiexec /x {D9777637-33B7-47A9-800C-F6A2CD4EB0FE} /qn /norestart /passive

:: Sony VAIO Sample Contents // Satisfaction Survey // Transfer Support VAIO Update
start /wait msiexec /x {547C9EB4-4CA6-402F-9D1B-8BD30DC71E44} /qn /norestart /passive
start /wait msiexec /x {5DDAFB4B-C52E-468A-9E23-3B0CEEB671BF} /qn /norestart /passive
start /wait msiexec /x {0899D75A-C2FC-42EA-A702-5B9A5F24EAD5} /qn /norestart /passive
start /wait msiexec /x {9FF95DA2-7DA1-4228-93B7-DED7EC02B6B2} /qn /norestart /passive

:: Sony VCCx64, VCCx86, VIx64, and VIx86
start /wait msiexec /x {549AD5FB-F52D-4307-864A-C0008FB35D96} /qn /norestart /passive
start /wait msiexec /x {DF184496-1CA2-4D07-92E7-0BD251D7DEF0} /qn /norestart /passive
start /wait msiexec /x {D55EAC07-7207-44BD-B524-0F063F327743} /qn /norestart /passive
start /wait msiexec /x {D17C2A58-E0EA-4DD7-A2D6-C448FD25B6F6} /qn /norestart /passive

:: Sony VMLx86, VPMx64, VSNx64, VSNx86, VSSTx64, VSSTx86, VU5x64, VU5x86, VU5x86, and VWSTx86
start /wait msiexec /x {02E0F3DE-3FB4-435C-B727-9C9E9EE4ACA4} /qn /norestart /passive
start /wait msiexec /x {DBEAA361-F8A4-4298-B41C-9E9DCB9AAB84} /qn /norestart /passive
start /wait msiexec /x {F2611404-06BF-4E67-A5B7-8DB2FFC1CBF6} /qn /norestart /passive
start /wait msiexec /x {A49A517F-5332-4665-922C-6D9AD31ADD4F} /qn /norestart /passive
start /wait msiexec /x {4F31AC31-0A28-4F5A-8416-513972DA1F79} /qn /norestart /passive
start /wait msiexec /x {B24BB74E-8359-43AA-985A-8E80C9219C70} /qn /norestart /passive
start /wait msiexec /x {6B7DE186-374B-4873-AEC1-7464DA337DD6} /qn /norestart /passive
start /wait msiexec /x {9D12A8B5-9D41-4465-BF11-70719EB0CD02} /qn /norestart /passive
start /wait msiexec /x {D2D23D08-D10E-43D6-883C-78E0B2AC9CC6} /qn /norestart /passive
start /wait msiexec /x {B8991D99-88FD-41F2-8C32-DB70278D5C30} /qn /norestart /passive

:: swMSM -  Shockwave Player Merge Module (hidden)
start /wait msiexec /x {612C34C7-5E90-47D8-9B5C-0F717DD82726} /qn /norestart /passive
start /wait msiexec /x {C30E30A6-0AB5-470A-AB67-D322938F5429} /qn /norestart /passive

:: Spybot - Search & Destroy
start /wait msiexec /x {B4092C6D-E886-4CB2-BA68-FE5A88D31DE6} /qn /norestart /passive

:: Sql Server Customer Experience Improvement Program (various versions)
start /wait msiexec /x {2D95D8C0-0DC4-44A6-A729-1E2388D2C03E} /qn /norestart /passive
start /wait msiexec /x {C942A025-A840-4BF2-8987-849C0DD44574} /qn /norestart /passive
start /wait msiexec /x {91C4DE4A-CE48-4F8B-9D73-D2BFB619FB88} /qn /norestart /passive
start /wait msiexec /x {F021CC0C-21C3-4038-AA4A-6E3CBC669CE8} /qn /norestart /passive
start /wait msiexec /x {BD1CD96B-FE4B-4EAE-83D4-6EF55AB5779C} /qn /norestart /passive
start /wait msiexec /x {63B58043-A08C-4379-8929-4233291B743A} /qn /norestart /passive

:: SRS Premium Sound for HP Thin Speakers
start /wait msiexec /x {DEA9F247-F832-4E36-90BF-D8EDA206521A} /qn /norestart /passive

:: Symantec WebReg
start /wait msiexec /x {CCB9B81A-167F-4832-B305-D2A0430840B3} /qn /norestart /passive

:: System Requirements Lab for Intel
start /wait msiexec /x {04C4B49D-45D9-4A28-9ED1-B45CBD99B8C7} /qn /norestart /passive
start /wait msiexec /x {76CE5B47-F5A4-4E5C-99A0-CEFF6146EA4A} /qn /norestart /passive
start /wait msiexec /x {DB2C58E0-6284-4B48-97F2-22A980B6360B} /qn /norestart /passive
start /wait msiexec /x {63B7AC7E-0178-4F4F-A79B-08D97ADD02D7} /qn /norestart /passive

:: Toshiba Audio Enhancement
start /wait msiexec /x {1515F5E3-29EA-4CD1-A981-032D88880F09} /qn /norestart /passive
start /wait msiexec /x {F2DE0088-CF05-4DAB-AC4D-9D2C4D657456} /qn /norestart /passive

:: Toshiba Application Installer
start /wait msiexec /x {970472D0-F5F9-4158-A6E3-1AE49EFEF2D3} /qn /norestart /passive
start /wait msiexec /x {1E6A96A1-2BAB-43EF-8087-30437593C66C} /qn /norestart /passive

:: TOSHIBA Audio Enhancement
start /wait msiexec /x {11955FE2-CAC6-4C3B-AA68-F787D7405400} /qn /norestart /passive

:: Toshiba App Place
start /wait msiexec /x {ED3CBA78-488F-4E8C-B33F-8E3BF4DDB4D2} /qn /norestart /passive
start /wait msiexec /x {84FA4D2D-4273-4C66-BD3D-ADD3FE48DFA2} /qn /norestart /passive

:: TOSHIBA Assist
start /wait msiexec /x {1B87C40B-A60B-4EF3-9A68-706CF4B69978} /qn /norestart /passive

:: Toshiba Bluetooth Statck for Windows by Toshiba
start /wait msiexec /x {230D1595-57DA-4933-8C4E-375797EBB7E1} /qn /norestart /passive
start /wait msiexec /x {CEBB6BFB-D708-4F99-A633-BC2600E01EF6} /qn /norestart /passive

:: Toshiba Book Place
start /wait msiexec /x {92C7DC44-DAD3-49FE-B89B-F92C6BA9A331} /qn /norestart /passive
start /wait msiexec /x {39187A4B-7538-4BE7-8BAD-9E83303793AA} /qn /norestart /passive
start /wait msiexec /x {05A55927-DB9B-4E26-BA44-828EBFF829F0} /qn /norestart /passive

:: TOSHIBA Bulletin Board
start /wait msiexec /x {C14518AF-1A0F-4D39-8011-69BAA01CD380} /qn /norestart /passive
start /wait msiexec /x {229C190B-7690-40B7-8680-42530179F3E9} /qn /norestart /passive
start /wait msiexec /x {1C8C049A-145F-4A6E-8290-B5C245EBE39D} /qn /norestart /passive

:: TOSHIBA ConfigFree
start /wait msiexec /x {716C8275-A4A9-48CB-88C0-9829334CA3C5} /qn /norestart /passive
start /wait msiexec /x {EAF55C99-A493-4373-A8C5-09ACC5DCD7EF} /qn /norestart /passive

:: Toshiba Desktop Assist
start /wait msiexec /x {95CCACF0-010D-45F0-82BF-858643D8BC02} /qn /norestart /passive

:: TOSHIBA Disc Creator
start /wait msiexec /x {5944B9D4-3C2A-48DE-931E-26B31714A2F7} /qn /norestart /passive

:: Toshiba Display Utility
start /wait msiexec /x {0B39C39A-3ECE-4582-9C91-842D22819A24} /qn /norestart /passive
start /wait msiexec /x {78C6A78A-8B03-48C8-A47C-78BA1FCA2307} /qn /norestart /passive
start /wait msiexec /x {11244D6B-9842-440F-8579-6A4D771A0D9B} /qn /norestart /passive

:: TOSHIBA Eco Utility
start /wait msiexec /x {72EFCFA8-3923-451D-AF52-7CE9D87BC2A1} /qn /norestart /passive
start /wait msiexec /x {59358FD4-252B-4B38-AB81-955C491A494F} /qn /norestart /passive
start /wait msiexec /x {2C486987-D447-4E36-8D61-86E48E24199C} /qn /norestart /passive

:: TOSHIBA Extended Tiles for Windows Mobility Center // GUID shared with TOSHIBA Disc Creator
start /wait msiexec /x {5DA0E02F-970B-424B-BF41-513A5018E4C0} /qn /norestart /passive

:: TOSHIBA Face Recognition
start /wait msiexec /x {F67FA545-D8E5-4209-86B1-AEE045D1003F} /qn /norestart /passive

:: TOSHIBA Flash Cards Support Utility
start /wait msiexec /x {617C36FD-0CBE-4600-84B2-441CEB12FADF} /qn /norestart /passive

:: TOSHIBA HDD/SDD Alert 3.1.64.x
start /wait msiexec /x {D4322448-B6AF-4316-B859-D8A0E84DCB38} /qn /norestart /passive

:: TOSHIBA Media Controller and TOSHIBA Media Controller Plug-in 1.0.5.11
start /wait msiexec /x {983CD6FE-8320-4B80-A8F6-0D0366E0AA22} /qn /norestart /passive
start /wait msiexec /x {F26FDF57-483E-42C8-A9C9-EEE1EDB256E0} /qn /norestart /passive

:: Toshiba Password Utility
start /wait msiexec /x {26BB68BB-CF93-4A12-BC6D-A3B6F53AC8D9} /qn /norestart /passive
start /wait msiexec /x {21A63CA3-75C0-4E56-B602-B7CD2EF6B621} /qn /norestart /passive

:: TOSHIBA PC Health Monitor
start /wait msiexec /x {9DECD0F9-D3E8-48B0-A390-1CF09F54E3A4} /qn /norestart /passive

:: TOSHIBA Peak Shift Control
start /wait msiexec /x {73F1BDB6-11E1-11D5-9DC6-00C04F2FC33B} /qn /norestart /passive

:: TOSHIBA Quality Application
start /wait msiexec /x {E69992ED-A7F6-406C-9280-1C156417BC49} /qn /norestart /passive
start /wait msiexec /x {620BBA5E-F848-4D56-8BDA-584E44584C5E} /qn /norestart /passive

:: TOSHIBARegistration
start /wait msiexec /x {5AF550B4-BB67-4E7E-82F1-2C4300279050} /qn /norestart /passive

:: TOSHIBA Recovery Media Creator
start /wait msiexec /x {B65BBB06-1F8E-48F5-8A54-B024A9E15FDF} /qn /norestart /passive

:: Toshiba ReelTime
start /wait msiexec /x {24811C12-F4A9-4D0F-8494-A7B8FE46123C} /qn /norestart /passive

:: Toshiba Service Station
start /wait msiexec /x {0DFA8761-7735-4DE8-A0EB-2286578DCFC6} /qn /norestart /passive
start /wait msiexec /x {6499E894-43F8-458B-AE35-724F4732BCDE} /qn /norestart /passive
start /wait msiexec /x {F64E9295-E1B3-4EEA-86D3-AF44A0087B06} /qn /norestart /passive

:: TOSHIBA Speech System Appplications, SR Engine(U.S.), TTS Engine(U.S.)
start /wait msiexec /x {EE033C1F-443E-41EC-A0E2-559B539A4E4D} /qn /norestart /passive
start /wait msiexec /x {008D69EB-70FF-46AB-9C75-924620DF191A} /qn /norestart /passive
start /wait msiexec /x {3FBF6F99-8EC6-41B4-8527-0A32241B5496} /qn /norestart /passive

:: Toshiba System Driver
start /wait msiexec /x {16562A90-71BC-41A0-B890-D91B0C267120} /qn /norestart /passive

:: Toshiba System Settings
start /wait msiexec /x {B040D5C9-C9AA-430A-A44E-696656012E61} /qn /norestart /passive
start /wait msiexec /x {EFCCEE68-1317-40A5-B785-C07AD2769338} /qn /norestart /passive

:: Toshiba Utility Common Driver (hidden)
start /wait msiexec /x {12688FD7-CB92-4A5B-BEE4-5C8E0574434F} /qn /norestart /passive

:: Toshiba User's Guide
start /wait msiexec /x {3384E1D9-3F18-4A98-8655-180FEF0DFC02} /qn /norestart /passive

:: Toshiba Value Added Package
start /wait msiexec /x {066CFFF8-12BF-4390-A673-75F95EFF188E} /qn /norestart /passive
start /wait msiexec /x {FBFCEEA5-96EA-4C8E-9262-43CBBEBAE413} /qn /norestart /passive

:: TOSHIBA Web Camera Application
start /wait msiexec /x {5E6F6CF3-BACC-4144-868C-E14622C658F3} /qn /norestart /passive
start /wait msiexec /x {6F3C8901-EBD3-470D-87F8-AC210F6E5E02} /qn /norestart /passive

:: TOSHIBA VIDEO PLAYER
start /wait msiexec /x {FF07604E-C860-40E9-A230-E37FA41F103A} /qn /norestart /passive

:: Toshiba Wireless LAN Indicator
start /wait msiexec /x {CDADE9BC-612C-42B8-B929-5C6A823E7FF9} /qn /norestart /passive
start /wait msiexec /x {5B01BCB7-A5D3-476F-AF11-E515BA206591} /qn /norestart /passive

:: TrayApp (various versions)
start /wait msiexec /x {CD31E63D-47FD-491C-8117-CF201D0AFAB5} /qn /norestart /passive
start /wait msiexec /x {FF075778-6E50-47ed-991D-3B07FD4E3250} /qn /norestart /passive
start /wait msiexec /x {4D304678-738E-42a0-931A-2B022F49DEB8} /qn /norestart /passive
start /wait msiexec /x {1EC71BFB-01A3-4239-B6AF-B1AE656B15C0} /qn /norestart /passive
start /wait msiexec /x {1B57D761-768E-4FB8-A6BB-057A977A7C81} /qn /norestart /passive
start /wait msiexec /x {5ACE69F0-A3E8-44eb-88C1-0A841E700180} /qn /norestart /passive

:: Trend Micro Trial
start /wait msiexec /x {BED0B8A2-2986-49F8-90D6-FA008D37A3D2} /qn /norestart /passive

:: Trend Micro Worry-Free Business Security Trial
start /wait msiexec /x {0A07E717-BB5D-4B99-840B-6C5DED52B277} /qn /norestart /passive

:: uLead Burn.Now 4.5 4.5.0
start /wait msiexec /x {FB3A15FD-FC67-3A2F-892B-6890B0C56EA9} /qn /norestart /passive

:: Vegas Movie Studio HD Platinum 11.0
start /wait msiexec /x {CE3DE3AE-F384-11E0-B00E-F04DA23A5C58} /qn /norestart /passive

:: VIP Access (Lenovo-installed OEM bloatware for Verisign)
start /wait msiexec /x {E8D46836-CD55-453C-A107-A59EC51CB8DC} /qn /norestart /passive

:: Video Downloader, VideoManager, VideoStage, VideoToolkit
start /wait msiexec /x {62796191-6F12-4ABE-BA8B-B4D4A266C997} /qn /norestart /passive
start /wait msiexec /x {6F0FA48E-DAEE-4CCE-BA6A-68C25E27BC85} /qn /norestart /passive
start /wait msiexec /x {E60AFF01-6087-47BD-8272-61FA3CFC309D} /qn /norestart /passive
start /wait msiexec /x {9C618A4D-5428-41B7-8A25-36B311FF8C77} /qn /norestart /passive
start /wait msiexec /x {DCE0E79A-B9AC-41AC-98C1-7EF0538BCA7F} /qn /norestart /passive

:: WD Quick View, SmartWare
start /wait msiexec /x {F9843E68-4E61-41B0-946E-66989DB35902} /qn /norestart /passive
start /wait msiexec /x {7AE43D6C-B3F1-448D-AD84-1CDC7AC6EBC7} /qn /norestart /passive
start /wait msiexec /x {79966948-BECF-4CB1-A79F-E76C830A17D2} /qn /norestart /passive

:: WildTangent GUIDs. Thanks to /u/mnbitcoin
start /wait msiexec /x {23170F69-40C1-2702-0938-000001000000} /qn /norestart /passive
start /wait msiexec /x {EE691BD9-2B2C-6BFB-6389-ABAF5AD2A4A1} /qn /norestart /passive
start /wait msiexec /x {6E3610B2-430D-4EB0-81E3-2B57E8B9DE8D} /qn /norestart /passive
start /wait msiexec /x {9E9EF3EC-22BC-445C-A883-D8DB2908698D} /qn /norestart /passive

:: "Delicious Emilys Childhood Memories Premium Edition", also used by "Enterprise 50.0.165.000"
start /wait msiexec /x {FC0ADA4D-8FA5-4452-8AFF-F0A0BAC97EF7} /qn /norestart /passive
start /wait msiexec /x {DD7C5FC1-DCA5-487A-AF23-658B1C00243F} /qn /norestart /passive
start /wait msiexec /x {0F929651-F516-4956-90F2-FFBD2CD5D30E} /qn /norestart /passive
start /wait msiexec /x {89C7E0A7-4D9D-4DCC-8834-A9A2B92D7EBB} /qn /norestart /passive
start /wait msiexec /x {9B56B031-A6C0-4BB7-8F61-938548C1B759} /qn /norestart /passive
start /wait msiexec /x {36AC0D1D-9715-4F13-B6A4-86F1D35FB4DF} /qn /norestart /passive
start /wait msiexec /x {03D562B5-C4E2-4846-A920-33178788BE00} /qn /norestart /passive

:: Windows 7 USB/DVD Download Tool
start /wait msiexec /x {CCF298AF-9CE1-4B26-B251-486E98A34789} /qn /norestart /passive

:: Windows 7 Upgrade Advisor
start /wait msiexec /x {AAF91344-2808-4D6B-9242-FBE5AF79D60A} /qn /norestart /passive

:: Windows Live Family Safety // Disabled by Vocatus for Tron (some family systems may be using this)
::start /wait msiexec /x {5F611ADA-B98C-4DBB-ADDE-414F08457ECF} /qn /norestart /passive

:: Windows Live Sign-in Assistant
start /wait msiexec /x {CE52672C-A0E9-4450-8875-88A221D5CD50} /qn /norestart /passive
start /wait msiexec /x {1B8ABA62-74F0-47ED-B18C-A43128E591B8} /qn /norestart /passive
start /wait msiexec /x {9B48B0AC-C813-4174-9042-476A887592C7} /qn /norestart /passive
start /wait msiexec /x {0610DFB0-CCEA-6EC0-E3C3-A0160AD7FD98} /qn /norestart /passive
start /wait msiexec /x {993F6DDC-63F8-4BCD-9B28-D941971A9CAC} /qn /norestart /passive
start /wait msiexec /x {1ACC8FFB-9D84-4C05-A4DE-D28A9BC91698} /qn /norestart /passive
start /wait msiexec /x {6152DEA9-EA0C-4013-9DBF-4A8881A7F722} /qn /norestart /passive
start /wait msiexec /x {19BA08F7-C728-469C-8A35-BFBD3633BE08} /qn /norestart /passive
start /wait msiexec /x {C424CD5E-EA05-4D3E-B5DA-F9F149E1D3AC} /qn /norestart /passive
start /wait msiexec /x {81128EE8-8EAD-4DB0-85C6-17C2CE50FF71} /qn /norestart /passive
start /wait msiexec /x {CDC1AB00-01FF-4FC7-816A-16C67F0923C0} /qn /norestart /passive

:: Windows Live Toolbar
start /wait msiexec /x {995F1E2E-F542-4310-8E1D-9926F5A279B3} /qn /norestart /passive

:: WOT for Internet Explorer plugin
start /wait msiexec /x {373B90E1-A28C-434C-92B6-7281AFA6115A} /qn /norestart /passive

:: Xmarks for IE
start /wait msiexec /x {ABFA6EAE-C9C0-4B39-B722-02094EF6B889} /qn /norestart /passive

:: Xnet Local Print Extension
start /wait msiexec /x {FD8D8382-4058-4F74-8EF1-FE61091F854A} /qn /norestart /passive

:: YouTube Downloader 2.7.2
start /wait msiexec /x {1a413f37-ed88-4fec-9666-5c48dc4b7bb7} /qn /norestart /passive

:: Zinio Alert Messenger
start /wait msiexec /x {D2E707E8-090E-EC5B-4833-1CA694FB7460} /qn /norestart /passive

:: ZoneAlarm Antivirus, Firewall, and Security
start /wait msiexec /x {043A5C25-EC0E-4152-A53B-73065A4315DF} /qn /norestart /passive
start /wait msiexec /x {537317B1-FB59-4578-953F-544914A8F25F} /qn /norestart /passive
start /wait msiexec /x {9A121E1B-1E87-4F37-BC9C-F8D073047942} /qn /norestart /passive

:: Zune Desktop Theme
start /wait msiexec /x {76BA306B-2AA0-47C0-AB6B-F313AB56C136} /qn /norestart /passive

:: Zune Language Pack (various versions)
start /wait msiexec /x {07EEE598-5F21-4B57-B40B-46592625B3D9} /qn /norestart /passive
start /wait msiexec /x {9B75648B-6C30-4A0D-9DE6-0D09D20AF5A5} /qn /norestart /passive
start /wait msiexec /x {A5A53EA8-A11E-49F0-BDF5-AE536426A31A} /qn /norestart /passive
start /wait msiexec /x {8960A0A1-BB5A-479E-92CF-65AB9D684B43} /qn /norestart /passive
start /wait msiexec /x {B4870774-5F3A-46D9-9DFE-06FB5599E26B} /qn /norestart /passive
start /wait msiexec /x {2A9DFFD8-4E09-4B91-B957-454805B0D7C4} /qn /norestart /passive
start /wait msiexec /x {6740BCB0-5863-47F4-80F4-44F394DE4FE2} /qn /norestart /passive
start /wait msiexec /x {A8F2E50B-86E2-4D96-9BD2-9758BCC6F9B3} /qn /norestart /passive
start /wait msiexec /x {C5D37FFA-7483-410B-982B-91E93FD3B7DA} /qn /norestart /passive
start /wait msiexec /x {C68D33B1-0204-4EBE-BC45-A6E432B1D13A} /qn /norestart /passive
start /wait msiexec /x {8B112338-2B08-4851-AF84-E7CAD74CEB32} /qn /norestart /passive
start /wait msiexec /x {BE236D9A-52EC-4A17-82DA-84B5EAD31E3E} /qn /norestart /passive
start /wait msiexec /x {C6BE19C6-B102-4038-B2A6-1C313872DBB4} /qn /norestart /passive
start /wait msiexec /x {3589A659-F732-4E65-A89A-5438C332E59D} /qn /norestart /passive
start /wait msiexec /x {6EB931CD-A7DA-4A44-B74A-89C8EB50086F} /qn /norestart /passive
start /wait msiexec /x {5DEFD397-4012-46C3-B6DA-E8013E660772} /qn /norestart /passive
start /wait msiexec /x {5C93E291-A1CC-4E51-85C6-E194209FCDB4} /qn /norestart /passive
start /wait msiexec /x {7E20EFE6-E604-48C6-8B39-BA4742F2CDB4} /qn /norestart /passive
start /wait msiexec /x {98BED31B-B364-4D74-BFBD-5C070E5DA77D} /qn /norestart /passive
start /wait msiexec /x {57C51D56-B287-4C11-9192-EC3C46EF76A4} /qn /norestart /passive
start /wait msiexec /x {51C839E1-2BE4-4E77-A1BA-CCEA5DAFA741} /qn /norestart /passive
start /wait msiexec /x {6B33492E-FBBC-4EC3-8738-09E16E395A10} /qn /norestart /passive

:: Bing/Windows Live Bar Removal
start /wait msiexec /x {C28D96C0-6A90-459E-A077-A6706F4EC0FC} /qn /norestart /passive
start /wait msiexec /x {786C4AD1-DCBA-49A6-B0EF-B317A344BD66} /qn /norestart /passive
start /wait msiexec /x {A5C4AD72-25FE-4899-B6DF-6D8DF63C93CF} /qn /norestart /passive
start /wait msiexec /x {341201D4-4F61-4ADB-987E-9CCE4D83A58D} /qn /norestart /passive
start /wait msiexec /x {F084395C-40FB-4DB3-981C-B51E74E1E83D} /qn /norestart /passive
start /wait msiexec /x {D5A145FC-D00C-4F1A-9119-EB4D9D659750} /qn /norestart /passive
start /wait msiexec /x {1e03db52-d5cb-4338-a338-e526dd4d4db1} /qn /norestart /passive

:: Live Mesh
start /wait msiexec /x {DECDCB7C-58CC-4865-91AF-627F9798FE48} /qn /norestart /passive

:: Live Mail
start /wait msiexec /x {C66824E4-CBB3-4851-BB3F-E8CFD6350923} /qn /norestart /passive

:: Live Mesh ActiveX
start /wait msiexec /x {2902F983-B4C1-44BA-B85D-5C6D52E2C441} /qn /norestart /passive

:: Live Messager
start /wait msiexec /x {EB4DF488-AAEF-406F-A341-CB2AAA315B90} /qn /norestart /passive

:: Energy Star
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
"C:\Program Files (x86)\InstallShield Installation Information\{BC12448A-0B41-4E11-B242-B1129512F5B7} /qn /norestart /passive\setup.exe" -l0x9  /remove 2>NUL
start /wait msiexec /x {BC8233D8-59BA-4D40-92B9-4FDE7452AA8B} /qn /norestart /passive
start /wait msiexec /x {C2D4CD4A-AE20-40B3-8726-8ED1C03E8C15} /qn /norestart /passive

:: Here we check the status of %TempCleanup% and check to see if we agreed to run the script.
cls 
if /i %TempCleanup%==Y echo Running TempFileCleanup now && call TempFileCleanup.bat 

cls
color CF
echo. 
echo.
echo.
echo.
echo.
echo.
echo.
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