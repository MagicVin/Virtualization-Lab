# [Office 365 totally FREE](https://msguides.com/office-365) -- waiting for verification :)
> Using KMS licene key to activate Office 365
> KMS license is totally free, legal and is valid for 180 days only. But don't worry about the period because it can be renewed easily.

## Steps
1. Remove current trial license
    > This steps is optional if your trial license was expired. However, if it is still valid, you need to remove it.
    1. Open command prompt as administrator
    2. Copy/run this command to determine what is the license key you want to remove
        ```
        cscript "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" /dstatus
        ```
        if error, try this command:
        ```
        cscript "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" /dstatus
        ```
        > **Note:** "Office16" is codename of Office2016. If you are using Office 2010/2013, replace "Office16" with "Office14" or "Office15"
    3. Cope/run these commands to remove the license.
        > **Note:** replace "VMFTK" with the last 5 characters of your product key.
        ```
        cscript "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" /unpkey:VMFTK
        ```
        if error, try this command:
        ```
        cscript "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" /unpkey:VMFTK
        ```
2. Make sure your computer is ready  
    You need to check your internet connection again and make sure that the Windows Update service is turned on. 
    > Check the web site is blocked or not:  
    > Open browser and visitting: https://s8.uk.to   
    > If it is visible, the KMS servers is not blocked or blocked.
3. Activating Office 365 using KMS client key
    1. Manual method -- Manually activate Office 365 using KMS client key.  
        1.1 Open command prompt as administrator  
        1.2 Navigate to Office folder 
        ```
        cd /d %ProgramFiles%\Microsoft Office\Office16
        cd /d %ProgramFiles(x86)%\Microsoft Office\Office16
        ``` 
        > One of them  will work  

        1.3 Convert Office license to volume one if possible 
        ```
        for /f %x in ('dir /b ..\root\Licenses16\proplusvl_kms*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%x"
        ```
        1.4 Use KMS client key to activate Office
        > Make sure the PC is connected to the internet, then run the following command.
        ``` 
        cscript ospp.vbs /inpkey:XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
        cscript ospp.vbs /unpkey:BTDRB >nul
        cscript ospp.vbs /unpkey:KHGM9 >nul
        cscript ospp.vbs /unpkey:CPQVG >nul
        cscript ospp.vbs /sethst:s8.uk.to
        cscript ospp.vbs /setprt:1688
        cscript ospp.vbs /act
        ```
    2. Using bath script, cope the following as a batch file, like: office365.cmd
        > run the batch file as administrator right(important!)
        ```
        @echo off
        title Activate Office 365 ProPlus for FREE - MSGuides.com&cls&echo =====================================================================================&echo #Project: Activating Microsoft software products for FREE without additional software&echo =====================================================================================&echo.&echo #Supported products: Office 365 ProPlus (x86-x64)&echo.&echo.&(if exist "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" cd /d "%ProgramFiles%\Microsoft Office\Office16")&(if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" cd /d "%ProgramFiles(x86)%\Microsoft Office\Office16")&(for /f %%x in ('dir /b ..\root\Licenses16\proplusvl_kms*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul)&(for /f %%x in ('dir /b ..\root\Licenses16\proplusvl_mak*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%%x" >nul)&echo.&echo ============================================================================&echo Activating your Office...&cscript //nologo slmgr.vbs /ckms >nul&cscript //nologo ospp.vbs /setprt:1688 >nul&cscript //nologo ospp.vbs /unpkey:WFG99 >nul&cscript //nologo ospp.vbs /unpkey:DRTFM >nul&cscript //nologo ospp.vbs /unpkey:BTDRB >nul&set i=1&cscript //nologo ospp.vbs /inpkey:XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99 >nul||cscript //nologo ospp.vbs /inpkey:NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP >nul||goto notsupported
        :skms
        if %i% GTR 10 goto busy
        if %i% EQU 1 set KMS=kms7.MSGuides.com
        if %i% EQU 2 set KMS=s8.uk.to
        if %i% EQU 3 set KMS=s9.us.to
        if %i% GTR 3 goto ato
        cscript //nologo ospp.vbs /sethst:%KMS% >nul
        :ato
        echo ============================================================================&echo.&echo.&cscript //nologo ospp.vbs /act | find /i "successful" && (echo.&echo ============================================================================&echo.&echo #My official blog: MSGuides.com&echo.&echo #How it works: bit.ly/kms-server&echo.&echo #Please feel free to contact me at msguides.com@gmail.com if you have any questions or concerns.&echo.&echo #Please consider supporting this project: donate.msguides.com&echo #Your support is helping me keep my servers running 24/7!&echo.&echo ============================================================================&choice /n /c YN /m "Would you like to visit my blog [Y,N]?" & if errorlevel 2 exit) || (echo The connection to my KMS server failed! Trying to connect to another one... & echo Please wait... & echo. & echo. & set /a i+=1 & goto skms)
        explorer "http://MSGuides.com"&goto halt
        :notsupported
        echo ============================================================================&echo.&echo Sorry, your version is not supported.&echo.&goto halt
        :busy
        echo ============================================================================&echo.&echo Sorry, the server is busy and can't respond to your request. Please try again.&echo.
        :halt
        pause >nul
        ```
    3. Renew Office365 license
        1. Open command prompt as administrator
        2. Copy/run the commmand
        > **Note:** "Office16" is code name of Office2016. If you Office 2013/2010, just replace it with "Office15" and "Office14".
        ```
        cscript "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" /act
        cscript "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" /act
        ```
        > One of them will work.
        3. Appendix: Renew Microsoft Windows license
            1. Open command prompt as adminstrator
            2. Execute this command
                ```
                cscript slmgr.vbs /ato
                ```
   
