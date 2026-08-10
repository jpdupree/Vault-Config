<#
.SYNOPSIS
    Extracts block attributes (title block tags and their values) from AutoCAD
    DWG files and emits them as PowerShell objects or CSV.

.DESCRIPTION
    Reads every attributed block reference in one or more DWG files and returns
    the tag/value pairs — the DWG_NO, REV, SHEET, DRAWN_BY style fields that
    live in a title block.

    Two read methods are supported:

      ObjectDBX  (default)  Uses the AxDbDocument in-process reader that ships
                            with AutoCAD. The drawing is never opened in the
                            editor, nothing is drawn on screen, and no document
                            lock is taken — typically 10-50x faster than opening
                            each file, and safe to run over a whole folder.

      Interactive           Falls back to Documents.Open(..., ReadOnly) against a
                            real AutoCAD session. Slower, but works when
                            ObjectDBX refuses a file (rare: a DWG saved by a
                            *newer* AutoCAD than the one installed, or a drawing
                            that needs a recover/audit pass first).

    Both methods need AutoCAD installed and licensed on the machine running the
    script — ObjectDBX is licensed through a (hidden) AutoCAD application object,
    which this script starts for you if one is not already running.

    Attributes are read from model space and from every paper space layout.
    Nested block references are not walked: AutoCAD does not allow a block
    reference inside a block definition to carry variable attribute values, so
    there is nothing there to read. Constant attributes do live in the block
    *definition* and are excluded by default — add -IncludeConstant for them.

.PARAMETER Path
    One or more DWG files, folders, or wildcard patterns. Folders are scanned
    for *.dwg. Accepts pipeline input, so Get-ChildItem piping works.

.PARAMETER Recurse
    Recurse into subfolders when -Path names a folder.

.PARAMETER BlockName
    Only return attributes from blocks whose name matches one of these patterns
    (wildcards allowed, case-insensitive). Matched against both the block name
    and, for dynamic blocks, the effective name. Default: all blocks.

.PARAMETER Tag
    Only return attributes whose tag matches one of these patterns (wildcards
    allowed, case-insensitive). Default: all tags.

.PARAMETER Space
    Which spaces to read: Model, Paper, or All (default).

.PARAMETER IncludeConstant
    Also emit constant attributes. These are fixed text defined in the block and
    identical for every insert, so they are off by default. They are reported
    with IsConstant = $true and no per-insert handle.

.PARAMETER Pivot
    Return one row per block reference with each attribute tag as its own
    column, instead of one row per attribute. This is the shape you want for a
    "one line per drawing" title block report. Tag names are sanitized into
    property names; columns are unioned across every block so the CSV is square.

.PARAMETER Method
    ObjectDBX (default) or Interactive. See the description.

.PARAMETER Password
    Password for encrypted drawings. Applied to every file in the run.

.PARAMETER OutFile
    Write the results to this CSV path in addition to returning them.

.PARAMETER Encoding
    Encoding for -OutFile. Default UTF8. Use 'utf8BOM' (PS7) or 'UTF8' (5.1) if
    Excel mangles accented characters.

.EXAMPLE
    .\Get-DwgBlockAttributes.ps1 -Path 'C:\Drawings\A-101.dwg'

    Every attribute in one drawing, one object per attribute.

.EXAMPLE
    .\Get-DwgBlockAttributes.ps1 -Path C:\Drawings -Recurse -BlockName 'TITLEBLOCK*' -Pivot -OutFile titleblocks.csv

    Walks the tree, keeps only title block inserts, and writes a square CSV with
    one row per title block and a column per tag.

.EXAMPLE
    Get-ChildItem C:\Vault\Designs -Filter *.dwg -Recurse |
        .\Get-DwgBlockAttributes.ps1 -Tag DWG_NO,REV |
        Group-Object Value -Property Value

    Pipeline input, narrowed to two tags.

.EXAMPLE
    .\Get-DwgBlockAttributes.ps1 -Path C:\Drawings\Problem.dwg -Method Interactive

    Retry a file ObjectDBX rejected, using a real AutoCAD session.

.NOTES
    Run this in **64-bit Windows PowerShell 5.1** for the smoothest experience.
    ObjectDBX is an in-process COM server, so the PowerShell host bitness must
    match AutoCAD's (64-bit for any modern release). PowerShell 7 usually works
    but its COM interop is less forgiving; the script warns rather than blocks.

    Per-file errors never stop the run — a bad drawing produces a warning and
    the scan continues.

    If AutoCAD is already running the script attaches to that session and
    leaves it open when finished; it only quits AutoCAD when it started the
    instance itself. Note that -Method Interactive opens and closes documents
    in whatever session it attaches to, so it will change the active drawing in
    a session you have open — ObjectDBX (the default) does not.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName', 'PSPath')]
    [string[]] $Path,

    [switch] $Recurse,

    [string[]] $BlockName,

    [string[]] $Tag,

    [ValidateSet('Model', 'Paper', 'All')]
    [string] $Space = 'All',

    [switch] $IncludeConstant,

    [switch] $Pivot,

    [ValidateSet('ObjectDBX', 'Interactive')]
    [string] $Method = 'ObjectDBX',

    [string] $Password,

    [string] $OutFile,

    [string] $Encoding = 'UTF8'
)

begin {
    Set-StrictMode -Version 2.0
    $ErrorActionPreference = 'Stop'

    if ($env:OS -ne 'Windows_NT') {
        throw 'This script requires Windows with AutoCAD installed (COM automation).'
    }
    if (-not [Environment]::Is64BitProcess) {
        Write-Warning 'Running in a 32-bit PowerShell host. ObjectDBX is in-process and must match AutoCAD bitness — start 64-bit PowerShell if the reader fails to load.'
    }
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Write-Warning 'PowerShell 7 detected. COM interop with AutoCAD is more reliable under Windows PowerShell 5.1 — switch hosts if you hit odd COM errors.'
    }

    #-------------------------------------------------------------------------
    # COM plumbing
    #-------------------------------------------------------------------------

    # AutoCAD rejects incoming COM calls while it is busy (RPC_E_CALL_REJECTED /
    # RPC_E_SERVERCALL_RETRYLATER). Back off and retry rather than dying.
    function Invoke-ComRetry {
        param(
            [Parameter(Mandatory)] [scriptblock] $Script,
            [int] $Retries = 6
        )
        for ($i = 0; $i -lt $Retries; $i++) {
            try {
                return & $Script
            } catch {
                $hr = 0
                if ($_.Exception -is [System.Runtime.InteropServices.COMException]) {
                    $hr = $_.Exception.HResult
                }
                # 0x8001010A server busy, 0x80010001 call rejected
                if ($hr -ne -2147417846 -and $hr -ne -2147418111) { throw }
                Start-Sleep -Milliseconds (250 * [math]::Pow(2, $i))
            }
        }
        throw 'AutoCAD stayed busy and kept rejecting COM calls. Close any modal dialog in AutoCAD and try again.'
    }

    function Get-AcadExePath {
        # Real acad.exe path from the install registry, so the /regserver hint
        # names the actual folder rather than a placeholder. Newest release
        # first — key names look like 'R25.1' (AutoCAD 2026), 'R25.0' (2025).
        foreach ($root in @('HKLM:\SOFTWARE\Autodesk\AutoCAD',
                            'HKLM:\SOFTWARE\WOW6432Node\Autodesk\AutoCAD')) {
            if (-not (Test-Path $root)) { continue }
            $releases = Get-ChildItem $root -ErrorAction SilentlyContinue |
                Sort-Object {
                    # Unparsable key names sort last instead of throwing.
                    $v = $null
                    if ([version]::TryParse(($_.PSChildName -replace '^R', ''), [ref]$v)) { $v }
                    else { [version]'0.0' }
                } -Descending
            foreach ($rel in $releases) {
                foreach ($lang in (Get-ChildItem $rel.PSPath -ErrorAction SilentlyContinue)) {
                    $loc = (Get-ItemProperty $lang.PSPath -ErrorAction SilentlyContinue).AcadLocation
                    if ($loc) {
                        $exe = Join-Path $loc 'acad.exe'
                        if (Test-Path $exe) { return $exe }
                    }
                }
            }
        }
        return $null
    }

    function New-AcadComObject {
        # The version-independent ProgID is not always registered even when the
        # versioned ones are (side-by-side installs, repaired installs, and
        # deployments that ran without elevation all produce this). Try it
        # first, then every AutoCAD.Application.<n> found in the registry,
        # newest first.
        $candidates = @('AutoCAD.Application')
        try {
            $hkcr = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
                [Microsoft.Win32.RegistryHive]::ClassesRoot,
                [Microsoft.Win32.RegistryView]::Default)
            try {
                $candidates += ($hkcr.GetSubKeyNames() |
                        Where-Object { $_ -match '^AutoCAD\.Application\.\d+$' } |
                        Sort-Object { [int]($_ -replace '\D') } -Descending)
            } finally {
                $hkcr.Close()
            }
        } catch {
            Write-Verbose "Could not enumerate AutoCAD ProgIDs from the registry: $($_.Exception.Message)"
        }

        $lastError = $null
        foreach ($progId in ($candidates | Select-Object -Unique)) {
            try {
                $obj = New-Object -ComObject $progId -ErrorAction Stop
                Write-Verbose "Created AutoCAD COM object via ProgID '$progId'."
                return $obj
            } catch {
                $lastError = $_
                Write-Verbose "ProgID '$progId' failed: $($_.Exception.Message)"
            }
        }

        # Nothing worked — say which of the three usual causes applies.
        $ltOnly = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\acadlt.exe') -and
                  -not (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\acad.exe')
        $hint = if ($ltOnly) {
            'AutoCAD LT appears to be the installed product. LT ships no COM/ActiveX automation interface, so this script cannot read its drawings — convert DWG to DXF (e.g. with the free ODA File Converter) and parse that instead.'
        } elseif ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
            'This is a 32-bit PowerShell host on a 64-bit OS, so it cannot see 64-bit AutoCAD''s registration. Relaunch 64-bit Windows PowerShell / ISE (not the "(x86)" shortcut).'
        } else {
            $exe = Get-AcadExePath
            if (-not $exe) { $exe = 'C:\Program Files\Autodesk\AutoCAD 20XX\acad.exe' }
            "AutoCAD's COM server does not appear to be registered. Close AutoCAD, then from an ELEVATED command prompt run:  `"$exe`" /regserver"
        }
        throw "Could not start AutoCAD via COM (tried: $(($candidates | Select-Object -Unique) -join ', ')). $hint Run .\Test-AutoCADCom.ps1 for a full diagnosis. Underlying error: $($lastError.Exception.Message)"
    }

    function Get-AcadApplication {
        # Whether AutoCAD was already running decides whether we may Quit() it
        # at the end. Check the process list rather than relying on how we got
        # the COM handle: Marshal::GetActiveObject does not exist in .NET Core,
        # so under PowerShell 7 it always throws and we would otherwise treat a
        # session the user has open as one we started — and close their work.
        $preexisting = @(Get-Process -Name 'acad' -ErrorAction SilentlyContinue)
        $script:StartedAcad = $false

        $app = $null
        if ($preexisting.Count -gt 0) {
            Write-Verbose "AutoCAD is already running (PID $($preexisting[0].Id)); attaching and leaving it open."
            try {
                $app = [Runtime.InteropServices.Marshal]::GetActiveObject('AutoCAD.Application')
            } catch {
                # PS7, or the instance is not in the running object table yet.
                Write-Verbose "GetActiveObject unavailable ($($_.Exception.Message)); falling back to New-Object."
                $app = New-AcadComObject
            }
        } else {
            Write-Verbose 'No running AutoCAD found; starting a hidden instance.'
            $app = New-AcadComObject
            $script:StartedAcad = $true
            # A freshly created instance defaults to hidden, but be explicit.
            try { $app.Visible = $false } catch { }
        }

        # Force the app to finish initializing before we ask it for anything.
        $null = Invoke-ComRetry { $app.Version }
        return $app
    }

    function Get-ObjectDbxDocument {
        param([Parameter(Mandatory)] $Application)

        # ObjectDBX must be version-matched to the host application, so derive
        # the major version from AutoCAD itself (e.g. "25.0s (LMS Tech)" -> 25).
        $version = Invoke-ComRetry { $Application.Version }
        $major = if ($version -match '^(\d+)') { [int]$Matches[1] } else { 0 }

        $candidates = @()
        if ($major -gt 0) { $candidates += "ObjectDBX.AxDbDocument.$major" }
        # Fall back across nearby releases, then the version-independent ProgID.
        foreach ($v in ($major - 1)..($major - 4)) {
            if ($v -ge 16) { $candidates += "ObjectDBX.AxDbDocument.$v" }
        }
        $candidates += 'ObjectDBX.AxDbDocument'

        foreach ($progId in $candidates) {
            try {
                $doc = Invoke-ComRetry { $Application.GetInterfaceObject($progId) }
                if ($doc) {
                    Write-Verbose "Using ObjectDBX reader '$progId'."
                    return $doc
                }
            } catch {
                Write-Verbose "ProgID '$progId' unavailable: $($_.Exception.Message)"
            }
        }
        throw 'Could not create an ObjectDBX (AxDbDocument) reader. Re-run with -Method Interactive.'
    }

    function Remove-ComRef {
        param($Object)
        if ($null -ne $Object -and [Runtime.InteropServices.Marshal]::IsComObject($Object)) {
            try { $null = [Runtime.InteropServices.Marshal]::ReleaseComObject($Object) } catch { }
        }
    }

    #-------------------------------------------------------------------------
    # Reading
    #-------------------------------------------------------------------------

    function Test-NameMatch {
        param([string] $Value, [string[]] $Patterns)
        if (-not $Patterns) { return $true }
        foreach ($p in $Patterns) {
            if ($Value -like $p) { return $true }
        }
        return $false
    }

    function Get-SafeProperty {
        # COM property access that tolerates a member missing on older releases.
        param($Object, [string] $Name, $Default = $null)
        try { return $Object.$Name } catch { return $Default }
    }

    function Read-DocumentAttributes {
        <#
            Walks the Blocks collection and reads every layout block (model space
            plus each paper space layout). Index-based iteration is used rather
            than foreach because AutoCAD's IEnumVARIANT enumerators are flaky
            under some PowerShell hosts.
        #>
        param(
            [Parameter(Mandatory)] $Document,
            [Parameter(Mandatory)] [string] $File
        )

        $fileName = [IO.Path]::GetFileName($File)
        $blocks = Invoke-ComRetry { $Document.Blocks }
        $blockCount = Invoke-ComRetry { $blocks.Count }

        for ($b = 0; $b -lt $blockCount; $b++) {
            $layoutBlock = Invoke-ComRetry { $blocks.Item($b) }
            try {
                if (-not (Get-SafeProperty $layoutBlock 'IsLayout' $false)) { continue }
                if (Get-SafeProperty $layoutBlock 'IsXRef' $false) { continue }

                $blkName = Get-SafeProperty $layoutBlock 'Name' ''
                $isModel = $blkName -eq '*Model_Space'
                $spaceKind = if ($isModel) { 'Model' } else { 'Paper' }
                if ($Space -ne 'All' -and $Space -ne $spaceKind) { continue }

                $layoutName = $spaceKind
                try { $layoutName = $layoutBlock.Layout.Name } catch { $layoutName = $blkName }

                $entCount = Invoke-ComRetry { $layoutBlock.Count }
                for ($e = 0; $e -lt $entCount; $e++) {
                    $ent = Invoke-ComRetry { $layoutBlock.Item($e) }
                    try {
                        if ((Get-SafeProperty $ent 'ObjectName' '') -ne 'AcDbBlockReference') { continue }

                        $name = Get-SafeProperty $ent 'Name' ''
                        # Dynamic block inserts report an anonymous name (*U12);
                        # EffectiveName is the name the user actually sees.
                        $effective = Get-SafeProperty $ent 'EffectiveName' $name
                        if (-not (Test-NameMatch $name $BlockName) -and
                            -not (Test-NameMatch $effective $BlockName)) { continue }

                        $handle = Get-SafeProperty $ent 'Handle' ''
                        $layer = Get-SafeProperty $ent 'Layer' ''
                        $point = Get-SafeProperty $ent 'InsertionPoint' @(0, 0, 0)

                        $attribs = @()
                        if (Get-SafeProperty $ent 'HasAttributes' $false) {
                            $raw = Invoke-ComRetry { $ent.GetAttributes() }
                            if ($raw) { $attribs = @($raw) }
                        }

                        foreach ($a in $attribs) {
                            $attTag = Get-SafeProperty $a 'TagString' ''
                            if (-not (Test-NameMatch $attTag $Tag)) { continue }

                            [pscustomobject]@{
                                File          = $File
                                FileName      = $fileName
                                Layout        = $layoutName
                                Space         = $spaceKind
                                BlockName     = $name
                                EffectiveName = $effective
                                Handle        = $handle
                                Tag           = $attTag
                                Value         = Get-SafeProperty $a 'TextString' ''
                                Prompt        = Get-SafeProperty $a 'PromptString' ''
                                IsConstant    = $false
                                Invisible     = [bool](Get-SafeProperty $a 'Invisible' $false)
                                Layer         = $layer
                                X             = [double]$point[0]
                                Y             = [double]$point[1]
                                Z             = [double]$point[2]
                            }
                        }

                        if ($IncludeConstant) {
                            # Constant attributes are AcDbAttributeDefinition entities
                            # in the block *definition*, not on the insert.
                            $defName = if ($effective) { $effective } else { $name }
                            foreach ($c in (Get-ConstantAttribute -Document $Document -DefinitionName $defName)) {
                                if (-not (Test-NameMatch $c.Tag $Tag)) { continue }

                                [pscustomobject]@{
                                    File          = $File
                                    FileName      = $fileName
                                    Layout        = $layoutName
                                    Space         = $spaceKind
                                    BlockName     = $name
                                    EffectiveName = $effective
                                    Handle        = $handle
                                    Tag           = $c.Tag
                                    Value         = $c.Value
                                    Prompt        = $c.Prompt
                                    IsConstant    = $true
                                    Invisible     = $c.Invisible
                                    Layer         = $layer
                                    X             = [double]$point[0]
                                    Y             = [double]$point[1]
                                    Z             = [double]$point[2]
                                }
                            }
                        }
                    } finally {
                        Remove-ComRef $ent
                    }
                }
            } finally {
                Remove-ComRef $layoutBlock
            }
        }
        Remove-ComRef $blocks
    }

    # Constant attributes are identical for every insert of a block, so cache
    # the block definition scan per document.
    $script:ConstantCache = @{}

    function Get-ConstantAttribute {
        # DefinitionName, not BlockName — the script-level -BlockName filter is
        # a different thing and must not be shadowed here.
        param($Document, [string] $DefinitionName)

        if ($script:ConstantCache.ContainsKey($DefinitionName)) {
            return $script:ConstantCache[$DefinitionName]
        }

        $result = @()
        try {
            $def = Invoke-ComRetry { $Document.Blocks.Item($DefinitionName) }
            $count = Invoke-ComRetry { $def.Count }
            for ($i = 0; $i -lt $count; $i++) {
                $ent = Invoke-ComRetry { $def.Item($i) }
                try {
                    if ((Get-SafeProperty $ent 'ObjectName' '') -ne 'AcDbAttributeDefinition') { continue }
                    if (-not (Get-SafeProperty $ent 'Constant' $false)) { continue }
                    $result += [pscustomobject]@{
                        Tag       = Get-SafeProperty $ent 'TagString' ''
                        Value     = Get-SafeProperty $ent 'TextString' ''
                        Prompt    = Get-SafeProperty $ent 'PromptString' ''
                        Invisible = [bool](Get-SafeProperty $ent 'Invisible' $false)
                    }
                } finally {
                    Remove-ComRef $ent
                }
            }
            Remove-ComRef $def
        } catch {
            Write-Verbose "Could not scan block definition '$DefinitionName' for constant attributes: $($_.Exception.Message)"
        }

        $script:ConstantCache[$DefinitionName] = $result
        return $result
    }

    #-------------------------------------------------------------------------
    # State
    #-------------------------------------------------------------------------
    $script:StartedAcad = $false
    $script:Acad = $null
    $script:Dbx = $null
    $script:Files = [System.Collections.Generic.List[string]]::new()
    $script:Results = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($p in $Path) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }

        $resolved = @()
        try {
            $resolved = Resolve-Path -Path $p -ErrorAction Stop
        } catch {
            Write-Warning "Path not found: $p"
            continue
        }

        foreach ($r in $resolved) {
            $item = Get-Item -LiteralPath $r.ProviderPath
            if ($item.PSIsContainer) {
                $found = Get-ChildItem -LiteralPath $item.FullName -Filter *.dwg -File -Recurse:$Recurse
                if (-not $found) { Write-Warning "No .dwg files under: $($item.FullName)" }
                foreach ($f in $found) { $script:Files.Add($f.FullName) }
            } elseif ($item.Extension -eq '.dwg') {
                $script:Files.Add($item.FullName)
            } else {
                Write-Verbose "Skipping non-DWG file: $($item.FullName)"
            }
        }
    }
}

end {
    # Wrap in @() — a single file would otherwise collapse to a scalar string,
    # and StrictMode 2.0 rejects .Count on it.
    $files = @($script:Files | Select-Object -Unique)
    if (-not $files) {
        Write-Warning 'No DWG files to read.'
        return
    }

    Write-Verbose "Reading $($files.Count) drawing(s) with method '$Method'."

    try {
        $script:Acad = Get-AcadApplication
        if ($Method -eq 'ObjectDBX') {
            $script:Dbx = Get-ObjectDbxDocument -Application $script:Acad
        }

        $i = 0
        foreach ($file in $files) {
            $i++
            Write-Progress -Activity 'Extracting DWG attributes' `
                -Status "$i of $($files.Count): $([IO.Path]::GetFileName($file))" `
                -PercentComplete (100 * $i / $files.Count)

            $script:ConstantCache = @{}
            $doc = $null
            $opened = $false
            try {
                if ($Method -eq 'ObjectDBX') {
                    if ($Password) {
                        Invoke-ComRetry { $script:Dbx.Open($file, $Password) }
                    } else {
                        Invoke-ComRetry { $script:Dbx.Open($file) }
                    }
                    $doc = $script:Dbx
                } else {
                    # ReadOnly open so we never dirty the file or fight a lock.
                    $doc = Invoke-ComRetry { $script:Acad.Documents.Open($file, $true) }
                    $opened = $true
                }

                foreach ($row in (Read-DocumentAttributes -Document $doc -File $file)) {
                    $script:Results.Add($row)
                }
            } catch {
                $hint = if ($Method -eq 'ObjectDBX') { ' Try -Method Interactive for this file.' } else { '' }
                Write-Warning "Failed to read '$file': $($_.Exception.Message)$hint"
            } finally {
                if ($opened -and $doc) {
                    try { Invoke-ComRetry { $doc.Close($false) } } catch { }
                    Remove-ComRef $doc
                }
            }
        }
        Write-Progress -Activity 'Extracting DWG attributes' -Completed
    } finally {
        Remove-ComRef $script:Dbx
        if ($script:Acad) {
            # Only shut AutoCAD down if we were the ones who started it.
            if ($script:StartedAcad) {
                try { Invoke-ComRetry { $script:Acad.Quit() } } catch { }
            }
            Remove-ComRef $script:Acad
        }
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }

    #-------------------------------------------------------------------------
    # Shape the output
    #-------------------------------------------------------------------------
    $output = @($script:Results)

    if ($Pivot) {
        $grouped = $output | Group-Object File, Layout, Handle, BlockName

        # Union every tag so each row carries the same columns and the CSV is square.
        $allTags = [System.Collections.Specialized.OrderedDictionary]::new()
        foreach ($row in $output) {
            $prop = ($row.Tag -replace '[^\w]', '_')
            if ([string]::IsNullOrWhiteSpace($prop)) { $prop = 'UNNAMED' }
            if (-not $allTags.Contains($prop)) { $allTags.Add($prop, $true) }
        }

        $pivoted = foreach ($g in $grouped) {
            $first = $g.Group[0]
            $obj = [ordered]@{
                File          = $first.File
                FileName      = $first.FileName
                Layout        = $first.Layout
                Space         = $first.Space
                BlockName     = $first.BlockName
                EffectiveName = $first.EffectiveName
                Handle        = $first.Handle
            }
            foreach ($t in $allTags.Keys) { $obj[$t] = $null }
            foreach ($a in $g.Group) {
                $prop = ($a.Tag -replace '[^\w]', '_')
                if ([string]::IsNullOrWhiteSpace($prop)) { $prop = 'UNNAMED' }
                # Repeated tags on one insert are rare but legal; keep them all.
                if ($null -ne $obj[$prop] -and $obj[$prop] -ne '') {
                    $obj[$prop] = "$($obj[$prop]); $($a.Value)"
                } else {
                    $obj[$prop] = $a.Value
                }
            }
            [pscustomobject]$obj
        }
        $output = @($pivoted)
    }

    if ($OutFile) {
        $dir = Split-Path -Parent $OutFile
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            $null = New-Item -ItemType Directory -Path $dir -Force
        }
        $output | Export-Csv -Path $OutFile -NoTypeInformation -Encoding $Encoding
        Write-Verbose "Wrote $($output.Count) row(s) to $OutFile"
    }

    $output
}
