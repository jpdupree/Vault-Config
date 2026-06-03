<#
.SYNOPSIS
    Exports an Autodesk Vault (Pro) configuration to a JSON file that the
    Vault Pro Configuration Dashboard (vault-config-dashboard.html) can load
    via its "Load Data" button.

.DESCRIPTION
    Connects to a Vault server using the Vault Web Services API (the DLLs that
    ship with the Vault client) and reads the selected sections of the
    configuration. It writes them to a single JSON document that matches the
    dashboard schema ("vault-config-dashboard/1").

    You choose which pieces to export with -Include / -Exclude, or run with
    -Interactive to pick from a menu. Only the sections you export are written
    to the file, so when you load it in the dashboard you control what gets
    updated:
      * Load with the dashboard's "Replace" toggle OFF  -> only the exported
        sections are updated; everything else keeps its current values (merge).
      * Load with "Replace" ON -> exported sections are applied and any section
        NOT in the file is cleared (clean full replace of just these pieces).

    The script is tolerant: each section is wrapped in its own try/catch and
    member access uses fallbacks, so a failure in one area (or a slightly
    different API version) still produces a usable file. Diagram colors and
    node positions are not stored in Vault — the dashboard assigns colors and
    auto-lays-out the flowchart on import.

.PARAMETER Server
    Vault / ADMS server name or IP (e.g. "localhost" or "vault01").

.PARAMETER Vault
    Vault name (e.g. "Vault").

.PARAMETER User
    Vault user name (e.g. "Administrator").

.PARAMETER Password
    Vault password. If omitted you will be prompted securely.

.PARAMETER OutFile
    Output path for the JSON file. Default: .\vault-config.json

.PARAMETER VaultClientPath
    Folder containing Autodesk.Connectivity.WebServices.dll. Defaults to the
    Vault Client 2025 Explorer folder; change to match your installed version.

.PARAMETER Include
    Which sections to export. Default 'All'. Valid section names:
      vault, properties, lifecycles, revisions, categories, folders,
      users, groups, server
    Example: -Include lifecycles,properties

.PARAMETER Exclude
    Sections to skip (applied after -Include). Example: -Exclude users,groups

.PARAMETER Interactive
    Prompt to choose sections from a menu instead of using -Include/-Exclude.

.PARAMETER Protocol
    Protocol to record in the 'server' section (HTTPS/HTTP). Default HTTPS.

.PARAMETER Port
    Server port to record in the 'server' section (e.g. 25734).

.PARAMETER DbServer
    SQL server to record in the 'server' section (not read from the API).

.PARAMETER DbName
    Vault database name to record in the 'server' section.

.PARAMETER FileStore
    File store path to record in the 'server' section.

.EXAMPLE
    .\Export-VaultConfig.ps1 -Server localhost -Vault Vault -User Administrator

.EXAMPLE
    # Export only lifecycles and properties
    .\Export-VaultConfig.ps1 -Server vault01 -Vault ACME -User svc -Password p `
        -Include lifecycles,properties

.EXAMPLE
    # Pick interactively, and record DB details that aren't in the API
    .\Export-VaultConfig.ps1 -Server vault01 -Vault ACME -User svc -Interactive `
        -DbServer "SQL01\AUTODESKVAULT" -DbName "ACME" -Port 25734

.NOTES
    Requires the Autodesk Vault client (or Vault SDK) installed on the machine
    running the script. Run in Windows PowerShell 5.1 or PowerShell 7.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $Server,
    [Parameter(Mandatory = $true)] [string] $Vault,
    [Parameter(Mandatory = $true)] [string] $User,
    [string] $Password,
    [string] $OutFile = ".\vault-config.json",
    [string] $VaultClientPath = "C:\Program Files\Autodesk\Vault Client 2025\Explorer",
    [ValidateSet('All','vault','properties','lifecycles','revisions','categories','folders','users','groups','server')]
    [string[]] $Include = @('All'),
    [ValidateSet('vault','properties','lifecycles','revisions','categories','folders','users','groups','server')]
    [string[]] $Exclude = @(),
    [switch] $Interactive,
    [ValidateSet('HTTPS','HTTP')] [string] $Protocol = 'HTTPS',
    [int]    $Port,
    [string] $DbServer,
    [string] $DbName,
    [string] $FileStore
)

$ErrorActionPreference = 'Stop'
$AllSections = 'vault','properties','lifecycles','revisions','categories','folders','users','groups','server'

# --- Helpers -------------------------------------------------------------
function Get-Prop {
    # Tolerant property read: returns the first member that exists / is non-null.
    param($Object, [string[]]$Names, $Default = $null)
    foreach ($n in $Names) {
        try { $v = $Object.$n; if ($null -ne $v) { return $v } } catch { }
    }
    return $Default
}

# --- Choose sections -----------------------------------------------------
if ($Interactive) {
    Write-Host "`nSelect the configuration pieces to export:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $AllSections.Count; $i++) {
        "{0,2}. {1}" -f ($i + 1), $AllSections[$i] | Write-Host
    }
    Write-Host " A. All sections"
    $resp = Read-Host "Enter numbers separated by commas (e.g. 1,3,4) or A for all"
    if ($resp -match '^\s*[Aa]\s*$' -or [string]::IsNullOrWhiteSpace($resp)) {
        $Include = @('All')
    } else {
        $picked = @()
        foreach ($tok in ($resp -split '[,\s]+')) {
            if ($tok -match '^\d+$') {
                $idx = [int]$tok - 1
                if ($idx -ge 0 -and $idx -lt $AllSections.Count) { $picked += $AllSections[$idx] }
            }
        }
        if ($picked.Count -eq 0) { throw "No valid sections selected." }
        $Include = $picked
    }
}

function Want([string]$name) {
    if ($Exclude -contains $name) { return $false }
    if ($Include -contains 'All') { return $true }
    return ($Include -contains $name)
}

$selected = $AllSections | Where-Object { Want $_ }
Write-Host ("Exporting sections: {0}" -f ($selected -join ', ')) -ForegroundColor Cyan

if (-not $Password) {
    $sec = Read-Host -AsSecureString "Vault password for '$User'"
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

# --- Load the Vault Web Services assemblies ------------------------------
$dll = Join-Path $VaultClientPath "Autodesk.Connectivity.WebServices.dll"
if (-not (Test-Path $dll)) {
    throw "Could not find Autodesk.Connectivity.WebServices.dll at '$dll'. " +
          "Set -VaultClientPath to your Vault client Explorer folder or SDK bin folder."
}
Add-Type -Path $dll
$toolsDll = Join-Path $VaultClientPath "Autodesk.Connectivity.WebServicesTools.dll"
if (Test-Path $toolsDll) { Add-Type -Path $toolsDll }

# --- Connect -------------------------------------------------------------
Write-Host "Connecting to $Server / $Vault as $User ..."
$svrIds = New-Object Autodesk.Connectivity.WebServicesTools.ServerIdentities
$svrIds.DataServer = $Server
$svrIds.FileServer = $Server
$authFlags = [Autodesk.Connectivity.WebServices.AuthenticationFlags]::Standard
$cred = New-Object Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials(
    $svrIds, $Vault, $User, $Password, $authFlags)
$mgr  = New-Object Autodesk.Connectivity.WebServicesTools.WebServiceManager($cred)
Write-Host "Connected." -ForegroundColor Green

# Result container — only selected sections are added ---------------------
$config = [ordered]@{ schema = "vault-config-dashboard/1" }

# --- vault ---------------------------------------------------------------
if (Want 'vault') {
    $config.vault = [ordered]@{
        name             = $Vault
        server           = $Server
        version          = (Get-Prop $mgr.WebServiceCredentials.ServerVersion @('Version','ToString') $null)
        administrator    = $User
        organization     = ""
        documentDate     = (Get-Date -Format "yyyy-MM-dd")
        preparedBy       = $env:USERNAME
        documentRevision = "1.0"
        notes            = "Exported by Export-VaultConfig.ps1 on $(Get-Date)"
    }
}

# --- properties ----------------------------------------------------------
if (Want 'properties') {
    try {
        Write-Host "Reading property definitions ..."
        $props = @(); $seen = @{}
        foreach ($entCls in @("FILE","ITEM","CO","FLDR","CUSTENT")) {
            try {
                $defs = $mgr.PropertyService.GetPropertyDefinitionsByEntityClassId($entCls)
                foreach ($p in $defs) {
                    $id = [string](Get-Prop $p @('Id'))
                    if ($seen.ContainsKey($id)) { continue }
                    $seen[$id] = $true
                    $props += [ordered]@{
                        Id          = $id
                        DisplayName = [string](Get-Prop $p @('DispName','DisplayName'))
                        SystemName  = [string](Get-Prop $p @('SysName','SystemName'))
                        DataType    = [string](Get-Prop $p @('Typ','DataType','Type'))
                        IsSystem    = [bool]  (Get-Prop $p @('IsSys','IsSystem') $false)
                        Active      = [bool]  (Get-Prop $p @('IsActive','Active') $true)
                    }
                }
            } catch { Write-Warning "  property class ${entCls}: $($_.Exception.Message)" }
        }
        $config.properties = $props
        Write-Host ("  {0} properties." -f $props.Count)
    } catch { Write-Warning "Property definitions failed: $($_.Exception.Message)" }
}

# --- lifecycles (states + transitions) -----------------------------------
if (Want 'lifecycles') {
    try {
        Write-Host "Reading lifecycle definitions ..."
        $lcs = @()
        $lcDefs = $mgr.LifeCycleService.GetAllLifeCycleDefinitions()
        foreach ($def in $lcDefs) {
            $relId  = [string](Get-Prop $def @('ReleasedStateId','ReleasedStateID'))
            $obsId  = [string](Get-Prop $def @('ObsoleteStateId','ObsoleteStateID'))
            $dfltId = [string](Get-Prop $def @('DfltStateId','DefaultStateId'))
            $states = @()
            foreach ($s in (Get-Prop $def @('StateArray','States') @())) {
                $sid   = [string](Get-Prop $s @('Id'))
                $isRel = ([bool](Get-Prop $s @('IsRel','IsReleased','Released') $false)) -or ($relId -and $sid -eq $relId)
                $isObs = ([bool](Get-Prop $s @('IsObs','IsObsolete','Obsolete') $false)) -or ($obsId -and $sid -eq $obsId)
                $isDf  = ([bool](Get-Prop $s @('IsDflt','IsDefault','Default') $false)) -or ($dfltId -and $sid -eq $dfltId)
                $states += [ordered]@{
                    id              = $sid
                    name            = [string](Get-Prop $s @('DispName','DisplayName','Name'))
                    description     = [string](Get-Prop $s @('Descr','Description'))
                    comments        = @()
                    isDefault       = $isDf
                    isReleasedState = $isRel
                    isObsoleteState = $isObs
                }
            }
            $trans = @()
            foreach ($t in (Get-Prop $def @('TransArray','TransitionArray','Transitions') @())) {
                $trans += [ordered]@{
                    id   = [string](Get-Prop $t @('Id'))
                    from = [string](Get-Prop $t @('FromId','From','FromStateId'))
                    to   = [string](Get-Prop $t @('ToId','To','ToStateId'))
                }
            }
            $lcs += [ordered]@{
                id          = [string](Get-Prop $def @('Id'))
                name        = [string](Get-Prop $def @('DispName','DisplayName','Name'))
                description = [string](Get-Prop $def @('Descr','Description'))
                states      = $states
                transitions = $trans
            }
        }
        $config.lifecycles = $lcs
        Write-Host ("  {0} lifecycles." -f $lcs.Count)
    } catch { Write-Warning "Lifecycle definitions failed: $($_.Exception.Message)" }
}

# --- revisions -----------------------------------------------------------
if (Want 'revisions') {
    try {
        Write-Host "Reading revision schemes ..."
        $revs = @()
        foreach ($r in $mgr.RevisionService.GetAllRevisionDefinitions()) {
            $revs += [ordered]@{
                name      = [string](Get-Prop $r @('DispName','DisplayName','Name'))
                format    = [string](Get-Prop $r @('SchemeType','Format','Typ'))
                primary   = ""
                secondary = ""
                notes     = ""
            }
        }
        $config.revisionSchemes = $revs
        Write-Host ("  {0} revision schemes." -f $revs.Count)
    } catch { Write-Warning "Revision schemes failed: $($_.Exception.Message)" }
}

# --- categories ----------------------------------------------------------
if (Want 'categories') {
    try {
        Write-Host "Reading categories ..."
        $cats = @()
        foreach ($map in @(@{cls="FILE";ent="File"}, @{cls="FLDR";ent="Folder"}, @{cls="ITEM";ent="Item"}, @{cls="CO";ent="Change Order"})) {
            try {
                foreach ($c in $mgr.CategoryService.GetCategoriesByEntityClassId($map.cls, $true)) {
                    $cats += [ordered]@{
                        name      = [string](Get-Prop $c @('Name','DispName'))
                        entity    = $map.ent
                        lifecycle = ""
                        revision  = ""
                        notes     = ""
                    }
                }
            } catch { Write-Warning "  category class $($map.cls): $($_.Exception.Message)" }
        }
        $config.categories = $cats
        Write-Host ("  {0} categories." -f $cats.Count)
    } catch { Write-Warning "Categories failed: $($_.Exception.Message)" }
}

# --- folders -------------------------------------------------------------
if (Want 'folders') {
    try {
        Write-Host "Reading folder structure ..."
        $fl = @()
        $root = $mgr.DocumentService.GetFolderRoot()
        foreach ($f in $mgr.DocumentService.GetFoldersByParentId($root.Id, $false)) {
            $fl += [ordered]@{
                id             = [string](Get-Prop $f @('Id'))
                name           = [string](Get-Prop $f @('FullName','Name'))
                createUserName = [string](Get-Prop $f @('CreateUserName','CreatedBy'))
                createDate     = (([string](Get-Prop $f @('CreateDate','Created'))) -split 'T' | Select-Object -First 1)
            }
        }
        $config.folders = $fl
        Write-Host ("  {0} folders." -f $fl.Count)
    } catch { Write-Warning "Folder structure failed: $($_.Exception.Message)" }
}

# --- users ---------------------------------------------------------------
if (Want 'users') {
    try {
        Write-Host "Reading users ..."
        $us = @()
        foreach ($u in $mgr.AdminService.GetAllUsers()) {
            $first = [string](Get-Prop $u @('FirstName'))
            $last  = [string](Get-Prop $u @('LastName'))
            $full  = ($first + ' ' + $last).Trim()
            if (-not $full) { $full = [string](Get-Prop $u @('Name')) }
            $role = ""
            try {
                $roles = $mgr.AdminService.GetRolesByUserId((Get-Prop $u @('Id')))
                if ($roles) { $role = (($roles | ForEach-Object { Get-Prop $_ @('Name','DispName') }) -join ', ') }
            } catch { }
            $active = Get-Prop $u @('IsActive','Active') $true
            $status = if ([bool]$active) { 'Active' } else { 'Inactive' }
            $us += [ordered]@{
                username = [string](Get-Prop $u @('Name','UserName'))
                fullName = $full
                email    = [string](Get-Prop $u @('Email'))
                role     = $role
                status   = $status
            }
        }
        $config.users = $us
        Write-Host ("  {0} users." -f $us.Count)
    } catch { Write-Warning "Users failed: $($_.Exception.Message)" }
}

# --- groups --------------------------------------------------------------
if (Want 'groups') {
    try {
        Write-Host "Reading groups ..."
        $gs = @()
        foreach ($grp in $mgr.AdminService.GetAllGroups()) {
            $members = ""
            try {
                $gm = $mgr.AdminService.GetUsersByGroupId((Get-Prop $grp @('Id')))
                if ($gm) { $members = (($gm | ForEach-Object { Get-Prop $_ @('Name','UserName') }) -join ', ') }
            } catch { }
            $gs += [ordered]@{
                name        = [string](Get-Prop $grp @('Name','DispName'))
                description = [string](Get-Prop $grp @('Descr','Description'))
                members     = $members
            }
        }
        $config.groups = $gs
        Write-Host ("  {0} groups." -f $gs.Count)
    } catch { Write-Warning "Groups failed: $($_.Exception.Message)" }
}

# --- server & database ---------------------------------------------------
# The Web Services API does not expose SQL/file-store config, so this section
# records the connection details plus anything you pass via parameters.
if (Want 'server') {
    $portStr = if ($PSBoundParameters.ContainsKey('Port')) { "$Port" } else { "" }
    $config.server = [ordered]@{
        'srv-host'  = $Server
        'srv-port'  = $portStr
        'srv-proto' = $Protocol
        'srv-fstore'= [string]$FileStore
        'db-host'   = [string]$DbServer
        'db-name'   = [string]$DbName
    }
    Write-Host "  server/database details recorded."
}

# --- Write JSON ----------------------------------------------------------
try {
    $json = $config | ConvertTo-Json -Depth 12
    Set-Content -Path $OutFile -Value $json -Encoding UTF8
    Write-Host "`nWrote configuration to $OutFile" -ForegroundColor Green
    Write-Host "Sections in file: $($selected -join ', ')"
    Write-Host "Open vault-config-dashboard.html and use 'Load Data' to load it."
    Write-Host "Tip: leave the dashboard's 'Replace' toggle OFF to merge only these sections."
} catch { Write-Warning "Failed to write $OutFile : $($_.Exception.Message)" }

# --- Disconnect ----------------------------------------------------------
try { $mgr.SignOut() } catch { }
