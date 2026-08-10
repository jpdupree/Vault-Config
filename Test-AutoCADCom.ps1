<#
.SYNOPSIS
    Diagnoses why AutoCAD COM automation is unavailable (REGDB_E_CLASSNOTREG).

.DESCRIPTION
    Get-DwgBlockAttributes.ps1 needs AutoCAD's COM server. When creating it
    fails with 0x80040154 "Class not registered", there are three usual causes
    and they need different fixes:

      1. AutoCAD LT is installed. LT ships no COM/ActiveX automation interface
         at all, so no amount of registration will help.
      2. The PowerShell host bitness does not match AutoCAD's. A 32-bit host
         looks in the WOW6432Node registry view, where 64-bit AutoCAD is not
         registered.
      3. The COM server really is unregistered — an install that was repaired,
         cloned, or deployed without elevation.

    This script reports which one applies. It only reads: nothing is changed.

.EXAMPLE
    .\Test-AutoCADCom.ps1

.EXAMPLE
    .\Test-AutoCADCom.ps1 | Tee-Object -FilePath "$env:USERPROFILE\Desktop\acad-com-report.txt"
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

function Write-Section {
    param([string] $Title)
    Write-Output ''
    Write-Output ('=' * 68)
    Write-Output "  $Title"
    Write-Output ('=' * 68)
}

#---------------------------------------------------------------------------
Write-Section 'Host'
#---------------------------------------------------------------------------
Write-Output "PowerShell version : $($PSVersionTable.PSVersion)"
Write-Output "PowerShell edition : $($PSVersionTable.PSEdition)"
Write-Output "Process is 64-bit  : $([Environment]::Is64BitProcess)"
Write-Output "OS is 64-bit       : $([Environment]::Is64BitOperatingSystem)"
Write-Output "Host executable    : $([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)"

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    Write-Output ''
    Write-Output '>> This is a 32-bit host on a 64-bit OS. If AutoCAD is 64-bit (all modern'
    Write-Output '   releases are), COM lookup will fail here even when registration is fine.'
    Write-Output '   Relaunch "Windows PowerShell ISE" -- NOT the "(x86)" shortcut.'
}

#---------------------------------------------------------------------------
Write-Section 'Running Autodesk processes'
#---------------------------------------------------------------------------
$procs = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(acad|acadlt|accoreconsole|revit|inventor)' }

if ($procs) {
    $procs | Select-Object Id, Name, @{ n = 'Path'; e = { $_.Path } } |
        Format-Table -AutoSize | Out-String -Width 200 | Write-Output
    if (@($procs.Name) -contains 'acadlt') {
        Write-Output '>> acadlt.exe is running -- that is AutoCAD LT. See the LT note below.'
    }
} else {
    Write-Output 'No AutoCAD/LT process is running right now.'
    Write-Output '(Not itself a problem -- the extractor can start one -- but if you expected'
    Write-Output ' AutoCAD to be open, it is not.)'
}

#---------------------------------------------------------------------------
Write-Section 'Installed Autodesk products (registry)'
#---------------------------------------------------------------------------
$found = $false
foreach ($root in @(
        'HKLM:\SOFTWARE\Autodesk\AutoCAD',
        'HKLM:\SOFTWARE\WOW6432Node\Autodesk\AutoCAD')) {
    if (-not (Test-Path $root)) { continue }
    foreach ($rel in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
        foreach ($lang in (Get-ChildItem $rel.PSPath -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty $lang.PSPath -ErrorAction SilentlyContinue
            $name = if ($p.PSObject.Properties.Name -contains 'ProductName') { $p.ProductName } else { '(unnamed)' }
            $loc = if ($p.PSObject.Properties.Name -contains 'AcadLocation') { $p.AcadLocation } else { '' }
            Write-Output ("{0,-42} {1} [{2}]" -f $name, $loc, $rel.PSChildName)
            $found = $true
        }
    }
}
if (-not $found) { Write-Output 'No AutoCAD product keys found under HKLM\SOFTWARE\Autodesk\AutoCAD.' }

#---------------------------------------------------------------------------
Write-Section 'Registered COM ProgIDs'
#---------------------------------------------------------------------------

function Get-ProgIdReport {
    param([Microsoft.Win32.RegistryView] $View)

    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
        [Microsoft.Win32.RegistryHive]::ClassesRoot, $View)
    try {
        $names = $base.GetSubKeyNames() |
            Where-Object { $_ -match '^(AutoCAD\.Application|ObjectDBX\.AxDbDocument)' } |
            Sort-Object
        foreach ($n in $names) {
            $clsid = ''
            $sub = $base.OpenSubKey("$n\CLSID")
            if ($sub) {
                $clsid = $sub.GetValue('')
                $sub.Close()
            }
            $server = ''
            if ($clsid) {
                foreach ($kind in 'LocalServer32', 'InprocServer32') {
                    $s = $base.OpenSubKey("CLSID\$clsid\$kind")
                    if ($s) {
                        $server = "$kind = $($s.GetValue(''))"
                        $s.Close()
                        break
                    }
                }
                if (-not $server) { $server = '!! CLSID present but no server path registered' }
            } else {
                $server = '!! no CLSID subkey'
            }
            [pscustomobject]@{ ProgID = $n; CLSID = $clsid; Server = $server }
        }
    } finally {
        $base.Close()
    }
}

Write-Output ''
Write-Output 'NOTE: ProgIDs carry the MAJOR release number, so consecutive releases share one.'
Write-Output '      AutoCAD 2026 is R25.1 and 2025 is R25.0 — both use ...Application.25 and'
Write-Output '      ...AxDbDocument.25. There is no ".26". Do not read a missing .26 as a fault.'

foreach ($view in @('Registry64', 'Registry32')) {
    if ($view -eq 'Registry64' -and -not [Environment]::Is64BitOperatingSystem) { continue }
    Write-Output ''
    Write-Output "--- $view view of HKEY_CLASSES_ROOT ---"
    $rows = @(Get-ProgIdReport -View ([Microsoft.Win32.RegistryView]$view))
    if ($rows.Count -eq 0) {
        Write-Output '(nothing matching AutoCAD.Application* or ObjectDBX.AxDbDocument*)'
    } else {
        $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
    }
}

#---------------------------------------------------------------------------
Write-Section 'Live activation test'
#---------------------------------------------------------------------------
$base = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
    [Microsoft.Win32.RegistryHive]::ClassesRoot,
    [Microsoft.Win32.RegistryView]::Default)
$candidates = @('AutoCAD.Application')
$candidates += ($base.GetSubKeyNames() |
        Where-Object { $_ -match '^AutoCAD\.Application\.\d+$' } |
        Sort-Object { [int]($_ -replace '\D') } -Descending)
$base.Close()

# Never quit a session the user already had open — only one we started here.
$acadWasRunning = @(Get-Process -Name 'acad' -ErrorAction SilentlyContinue).Count -gt 0
if ($acadWasRunning) {
    Write-Output '(AutoCAD already running: attaching only, will not close it.)'
} else {
    Write-Output '(Starting AutoCAD to test activation — this can take 30-60 seconds.)'
}

$worked = $null
foreach ($progId in ($candidates | Select-Object -Unique)) {
    try {
        $o = New-Object -ComObject $progId -ErrorAction Stop
        Write-Output "OK      $progId  -> version $($o.Version)"
        if (-not $worked) { $worked = $progId }
        if (-not $acadWasRunning) { try { $o.Quit() } catch { } }
        $null = [Runtime.InteropServices.Marshal]::ReleaseComObject($o)
    } catch {
        $msg = $_.Exception.Message -replace '\s+', ' '
        if ($msg.Length -gt 110) { $msg = $msg.Substring(0, 110) + '...' }
        Write-Output "FAIL    $progId  -> $msg"
    }
}

#---------------------------------------------------------------------------
Write-Section 'Verdict'
#---------------------------------------------------------------------------
$hasLt = $false
$hasFull = $false
foreach ($p in @($procs)) {
    if ($p.Name -eq 'acadlt') { $hasLt = $true }
    if ($p.Name -eq 'acad') { $hasFull = $true }
}
foreach ($exe in @('acad.exe', 'acadlt.exe')) {
    $k = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exe"
    if (Test-Path $k) {
        if ($exe -eq 'acadlt.exe') { $hasLt = $true } else { $hasFull = $true }
    }
}

if ($worked) {
    Write-Output "COM automation WORKS via ProgID '$worked'."
    Write-Output 'Re-run the extractor; if it still fails, the failure is elsewhere.'
} elseif ($hasLt -and -not $hasFull) {
    Write-Output 'AutoCAD LT detected, and no full AutoCAD.'
    Write-Output 'LT has no COM/ActiveX automation interface -- this approach cannot work on LT.'
    Write-Output 'Use the ODA File Converter (DWG -> DXF) and parse the DXF instead.'
} elseif ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    Write-Output 'Most likely cause: 32-bit PowerShell host against 64-bit AutoCAD.'
    Write-Output 'Relaunch in 64-bit "Windows PowerShell ISE" and re-run this script.'
} else {
    Write-Output 'AutoCAD appears installed but its COM server is not registered.'
    Write-Output 'Fix: close AutoCAD, open an ADMIN command prompt, and run:'
    $exe = $null
    foreach ($root in @('HKLM:\SOFTWARE\Autodesk\AutoCAD',
                        'HKLM:\SOFTWARE\WOW6432Node\Autodesk\AutoCAD')) {
        if ($exe -or -not (Test-Path $root)) { continue }
        $releases = Get-ChildItem $root -ErrorAction SilentlyContinue |
            Sort-Object {
                $v = $null
                if ([version]::TryParse(($_.PSChildName -replace '^R', ''), [ref]$v)) { $v }
                else { [version]'0.0' }
            } -Descending
        foreach ($rel in $releases) {
            foreach ($lang in (Get-ChildItem $rel.PSPath -ErrorAction SilentlyContinue)) {
                $loc = (Get-ItemProperty $lang.PSPath -ErrorAction SilentlyContinue).AcadLocation
                if ($loc -and (Test-Path (Join-Path $loc 'acad.exe'))) {
                    $exe = Join-Path $loc 'acad.exe'
                    break
                }
            }
            if ($exe) { break }
        }
    }
    if (-not $exe) { $exe = 'C:\Program Files\Autodesk\AutoCAD 2026\acad.exe' }
    Write-Output "    `"$exe`" /regserver"
    Write-Output 'Then re-run this script.'
}
Write-Output ''
