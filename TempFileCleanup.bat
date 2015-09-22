:: Purpose:       Tempfilecleanup.bat
:: Requirements:  Admin access helps but is not required

SETLOCAL

:: --------------------------- Don't edit anything below this line --------------------------- ::


:::::::::::::::::::::
:: PREP AND CHECKS ::
:::::::::::::::::::::
@echo off
pushd %SystemDrive%
set SCRIPT_VERSION=1.0.0
set SCRIPT_UPDATED=2015-09-22


::::::::::::::::::::::::::
:: USER CLEANUP SECTION :: -- Most stuff in here doesn't require Admin rights
::::::::::::::::::::::::::
:: Create the log header for this job
echo --------------------------------------------------------------------------------------------
echo %CUR_DATE% %TIME%  TempFileCleanup v%SCRIPT_VERSION%, executing as %USERDOMAIN%\%USERNAME%
echo --------------------------------------------------------------------------------------------
echo.
echo  Starting temp file cleanup
echo  --------------------------
echo.
echo   Cleaning USER temp files...

::::::::::::::::::::::
:: Version-agnostic :: (these jobs run regardless of OS version)
::::::::::::::::::::::
:: Create log line
echo.  %% echo  ! Cleaning USER temp files... %% echo.

:: User temp files, history, and random My Documents stuff
del /F /S /Q "%TEMP%" 2>NUL

:: Internet Explorer cleanup
rundll32.exe inetcpl.cpl,ClearMyTracksByProcess 4351 2>NUL

:: Previous Windows versions cleanup. These are left behind after upgrading an installation from XP/Vista/7/8 to a higher version. Thanks to /u/bodkov and others
if exist %SystemDrive%\Windows.old\ (
	takeown /F %SystemDrive%\Windows.old\* /R /A /D Y
	echo y| cacls %SystemDrive%\Windows.old\*.* /C /T /grant administrators:F
	rmdir /S /Q %SystemDrive%\Windows.old\
	)
if exist %SystemDrive%\$Windows.~BT\ (
	takeown /F %SystemDrive%\$Windows.~BT\* /R /A
	icacls %SystemDrive%\$Windows.~BT\*.* /T /grant administrators:F
	rmdir /S /Q %SystemDrive%\$Windows.~BT\
	)
if exist %SystemDrive%\$Windows.~WS (
	takeown /F %SystemDrive%\$Windows.~WS\* /R /A
	icacls %SystemDrive%\$Windows.~WS\*.* /T /grant administrators:F
	rmdir /S /Q %SystemDrive%\$Windows.~WS\
	)

::::::::::::::::::::::
:: Version-specific :: (these jobs run depending on OS version)
::::::::::::::::::::::
:: First block handles XP/2k3, second block handles Vista and up
:: Read 9 characters into the WIN_VER variable. Only versions of Windows older than Vista had "Microsoft" as the first part of their title,
:: so if we don't find "Microsoft" in the first 9 characters we can safely assume we're not on XP/2k3.
if /i "%WIN_VER:~0,9%"=="Microsoft" (
	for /D %%x in ("%SystemDrive%\Documents and Settings\*") do (
		del /F /Q "%%x\Local Settings\Temp\*" 2>NUL
		del /F /Q "%%x\Recent\*" 2>NUL
		del /F /Q "%%x\Local Settings\Temporary Internet Files\*" 2>NUL
		del /F /Q "%%x\Local Settings\Application Data\ApplicationHistory\*" 2>NUL
		del /F /Q "%%x\My Documents\*.tmp" 2>NUL
		del /F /Q "%%x\Application Data\Sun\Java\*" 2>NUL
		del /F /Q "%%x\Application Data\Adobe\Flash Player\*" 2>NUL
		del /F /Q "%%x\Application Data\Macromedia\Flash Player\*" 2>NUL
	)
) else (
	for /D %%x in ("%SystemDrive%\Users\*") do (
		del /F /Q "%%x\AppData\Local\Temp\*" 2>NUL
		del /F /Q "%%x\AppData\Roaming\Microsoft\Windows\Recent\*" 2>NUL
		del /F /Q "%%x\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" 2>NUL
		del /F /Q "%%x\My Documents\*.tmp" 2>NUL
		del /F /Q "%%x\AppData\LocalLow\Sun\Java\*" 2>NUL
		del /F /Q "%%x\AppData\Roaming\Adobe\Flash Player\*" 2>NUL
		del /F /Q "%%x\AppData\Roaming\Macromedia\Flash Player\*" 2>NUL
		del /F /Q "%%x\AppData\Local\Microsoft\Windows\*.blf" 2>NUL
		del /F /Q "%%x\AppData\Local\Microsoft\Windows\*.regtrans-ms" 2>NUL
		del /F /Q "%%x\*.blf" 2>NUL
		del /F /Q "%%x\*.regtrans-ms" 2>NUL
	)
)

echo. && echo   Done. && echo.
echo.  && echo   Done. && echo.



::::::::::::::::::::::::::::
:: SYSTEM CLEANUP SECTION :: -- Most stuff here requires Admin rights
::::::::::::::::::::::::::::
echo.
echo   Cleaning SYSTEM temp files...
echo   Cleaning SYSTEM temp files...  && echo.


::::::::::::::::::::::
:: Version-agnostic :: (these jobs run regardless of OS version)
::::::::::::::::::::::
:: JOB: System temp files
del /F /S /Q "%WINDIR%\TEMP\*" 2>NUL

:: JOB: Root drive garbage (usually C drive)
rmdir /S /Q %SystemDrive%\Temp 2>NUL
for %%i in (bat,txt,log,jpg,jpeg,tmp,bak,backup,exe) do (
			del /F /Q "%SystemDrive%\*.%%i" 2>NUL
		)

:: JOB: ::move files left over from installing Nvidia/ATI/AMD/Dell/Intel/HP drivers
for %%i in (NVIDIA,ATI,AMD,Dell,Intel,HP) do (
			rmdir /S /Q "%SystemDrive%\%%i" 2>NUL
		)

:: JOB: Clear additional unneeded files from NVIDIA driver installs
if exist "%ProgramFiles%\Nvidia Corporation\Installer2" del /Q "%ProgramFiles%\Nvidia Corporation\Installer2"
if exist "%ALLUSERSPROFILE%\NVIDIA Corporation\NetService" del /Q "%ALLUSERSPROFILE%\NVIDIA Corporation\NetService\*.exe"

:: JOB: ::move the Office installation cache. Usually around ~1.5 GB
if exist %SystemDrive%\MSOCache rmdir /S /Q %SystemDrive%\MSOCache

:: JOB: ::move the Windows installation cache. Can be up to 1.0 GB
if exist %SystemDrive%\i386 rmdir /S /Q %SystemDrive%\i386

:: JOB: Empty all recycle bins on Windows 5.1 (XP/2k3) and 6.x (Vista and up) systems (Could cause some issues on client PCs, disabled for now)
:: if exist %SystemDrive%\RECYCLER rmdir /s /q %SystemDrive%\RECYCLER
:: if exist %SystemDrive%\$Recycle.Bin rmdir /s /q %SystemDrive%\$Recycle.Bin

:: JOB: Clear MUI cache
reg delete "HKCU\SOFTWARE\Classes\Local Settings\Muicache" /f

:: JOB: Clear queued and archived Windows Error Reporting (WER) reports
if exist "%USERPROFILE%\AppData\Local\Microsoft\Windows\WER\ReportArchive" rmdir /s /q "%USERPROFILE%\AppData\Local\Microsoft\Windows\WER\ReportArchive"
if exist "%USERPROFILE%\AppData\Local\Microsoft\Windows\WER\ReportQueue" rmdir /s /q "%USERPROFILE%\AppData\Local\Microsoft\Windows\WER\ReportQueue"
if exist "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportArchive" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportArchive"
if exist "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportQueue" rmdir /s /q "%ALLUSERSPROFILE%\Microsoft\Windows\WER\ReportQueue"

:: JOB: Windows update logs & built-in backgrounds (space waste)
del /F /Q %WINDIR%\*.log 2>NUL
del /F /Q %WINDIR%\*.txt 2>NUL
del /F /Q %WINDIR%\*.bmp 2>NUL
del /F /Q %WINDIR%\*.tmp 2>NUL
del /F /Q %WINDIR%\Web\Wallpaper\*.* 2>NUL
rmdir /S /Q %WINDIR%\Web\Wallpaper\Dell 2>NUL

::::::::::::::::::::::
:: Version-specific :: (these jobs run depending on OS version)
::::::::::::::::::::::
:: JOB: Windows XP/2k3: "guided tour" annoyance
if /i "%WIN_VER:~0,9%"=="Microsoft" (
	del %WINDIR%\system32\dllcache\tourstrt.exe 2>NUL
	del %WINDIR%\system32\dllcache\tourW.exe 2>NUL
	rmdir /S /Q %WINDIR%\Help\Tours 2>NUL
	)


:: JOB: Windows Server: ::move built-in media files (all Server versions)
echo %WIN_VER% | findstr /i /c:"server" >NUL
if %ERRORLEVEL%==0 (
	echo.
	echo  ! Server operating system detected.
	echo    ::moving built-in media files ^(.wav, .midi, etc^)...
	echo.
	echo.  && echo  ! Server operating system detected. ::moving built-in media files ^(.wave, .midi, etc^)... && echo.

	:: 2. Take ownership of the files so we can actually delete them. By default even Administrators have Read-only rights.
	echo    Taking ownership of %WINDIR%\Media in order to delete files... && echo.
	echo    Taking ownership of %WINDIR%\Media in order to delete files...  && echo.
	if exist %WINDIR%\Media takeown /f %WINDIR%\Media /r /d y 2>NUL && echo.
	if exist %WINDIR%\Media icacls %WINDIR%\Media /grant administrators:F /t  && echo.

	:: 3. Do the cleanup
	rmdir /S /Q %WINDIR%\Media 2>NUL

	echo    Done.
	echo.
	echo    Done.
	echo.
	)

:: JOB: Windows CBS logs
::      these only exist on Vista and up, so we look for "Microsoft", and assuming we don't find it, clear out the folder
echo %WIN_VER% | findstr /i /c:"server" >NUL
if not %ERRORLEVEL%==0 del /F /Q %WINDIR%\Logs\CBS\* 2>NUL

:: JOB: Windows XP/2003: Cleanup hotfix uninstallers. They use a lot of space so ::moving them is beneficial.
:: Really we should use a tool that deletes their corresponding registry entries, but oh well.

::  0. Check Windows version.
::    We simply look for "Microsoft" in the version name, because only versions prior to Vista had the word "Microsoft" as part of their version name
::    Everything after XP/2k3 drops the "Microsoft" prefix
echo %WIN_VER% | findstr /i /c:"Microsoft" >NUL
if %ERRORLEVEL%==0 (
	:: 1. If we made it here we're doing the cleanup. Notify user and log it.
	echo.
	echo  ! Windows XP/2003 detected.
	echo    ::moving hotfix uninstallers...
	echo.
	echo.  && echo  ! Windows XP/2003 detected. ::moving hotfix uninstallers...

	:: 2. Build the list of hotfix folders. They always have "$" signs around their name, e.g. "$NtUninstall092330$" or "$hf_mg$"
	pushd %WINDIR%
	dir /A:D /B $*$ > %TEMP%\hotfix_nuke_list.txt 2>NUL

	:: 3. Do the hotfix clean up
	for /f %%i in (%TEMP%\hotfix_nuke_list.txt) do (
		echo Deleting %%i...
		echo Deleted folder %%i
		rmdir /S /Q %%i 2>NUL
		)

	:: 4. Log that we are done with hotfix cleanup and leave the Windows directory
	echo    Done.  && echo.
	echo    Done.
	del %TEMP%\hotfix_nuke_list.txt
	echo.
	popd
)

echo   Done. && echo.
echo   Done. && echo.

::::::::::::::::::::::::::
:: Cleanup and complete ::
::::::::::::::::::::::::::
:complete
@echo off
echo --------------------------------------------------------------------------------------------
echo %CUR_DATE% %TIME%  TempFileCleanup v%SCRIPT_VERSION%, finished. Executed as %USERDOMAIN%\%USERNAME%
echo --------------------------------------------------------------------------------------------
echo.
echo  Cleanup complete.
echo.
echo.
ENDLOCAL