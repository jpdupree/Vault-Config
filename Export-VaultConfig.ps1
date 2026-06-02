<#
.SYNOPSIS
    Exports an Autodesk Vault (Pro) configuration to a JSON file that the
    Vault Pro Configuration Dashboard (vault-config-dashboard.html) can load
    via its "Load Data" button.

.DESCRIPTION
    Connects to a Vault server using the Vault Web Services API (the DLLs that
    ship with the Vault client) and reads property definitions, lifecycle
    definitions (states + transitions), revision schemes, categories and the
    top-level folder structure. It writes them to a single JSON document that
    matches the dashboard schema ("vault-config-dashboard/1").

    The script is intentionally tolerant: each section is wrapped in its own
    try/catch, and member access uses fallbacks, so a failure in one area
    (or a slightly different API version) still produces a usable file.
    Diagram colors and node positions are NOT stored in Vault — the dashboard
    assigns sensible colors (Released=green, Obsolete=red, WIP=orange, …) and
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
    Vault Client 2025 Explorer folder; change to match your installed version
    (…\Vault Client <year>\Explorer or the Vault SDK \bin folder).

.EXAMPLE
    .\Export-VaultConfig.ps1 -Server localhost -Vault Vault -User Administrator

.EXAMPLE
    .\Export-VaultConfig.ps1 -Server vault01 -Vault ACME -User svc -Password p@ss `
        -OutFile C:\Temp\acme-vault.json `
        -VaultClientPath "C:\Program Files\Autodesk\Vault Client 2024\Explorer"

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
    [string] $VaultClientPath = "C:\Program Files\Autodesk\Vault Client 2025\Explorer"
)

$ErrorActionPreference = 'Stop'

# --- Helpers -------------------------------------------------------------
function Get-Prop {
    # Tolerant property read: returns the first member that exists / is non-null.
    param($Object, [string[]]$Names, $Default = $null)
    foreach ($n in $Names) {
        try {
            $v = $Object.$n
            if ($null -ne $v) { return $v }
        } catch { }
    }
    return $Default
}

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
# Some installs split the high-level tools into a second assembly:
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

# Result container (matches the dashboard schema) ------------------------
$config = [ordered]@{
    schema    = "vault-config-dashboard/1"
    vault     = [ordered]@{
        name           = $Vault
        server         = $Server
        version        = (Get-Prop $mgr.WebServiceCredentials.ServerVersion @('Version','ToString') $null)
        administrator  = $User
        organization   = ""
        documentDate   = (Get-Date -Format "yyyy-MM-dd")
        preparedBy     = $env:USERNAME
        documentRevision = "1.0"
        notes          = "Exported by Export-VaultConfig.ps1 on $(Get-Date)"
    }
    properties      = @()
    lifecycles      = @()
    revisionSchemes = @()
    categories      = @()
    folders         = @()
    items           = @()
    generalNotes    = ""
}

# --- Property definitions ------------------------------------------------
try {
    Write-Host "Reading property definitions ..."
    $seen = @{}
    foreach ($entCls in @("FILE","ITEM","CO","FLDR","CUSTENT")) {
        try {
            $defs = $mgr.PropertyService.GetPropertyDefinitionsByEntityClassId($entCls)
            foreach ($p in $defs) {
                $id = [string](Get-Prop $p @('Id'))
                if ($seen.ContainsKey($id)) { continue }
                $seen[$id] = $true
                $config.properties += [ordered]@{
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
    Write-Host ("  {0} properties." -f $config.properties.Count)
} catch { Write-Warning "Property definitions failed: $($_.Exception.Message)" }

# --- Lifecycle definitions (states + transitions) ------------------------
try {
    Write-Host "Reading lifecycle definitions ..."
    $lcDefs = $mgr.LifeCycleService.GetAllLifeCycleDefinitions()
    foreach ($def in $lcDefs) {
        $relId = [string](Get-Prop $def @('ReleasedStateId','ReleasedStateID'))
        $obsId = [string](Get-Prop $def @('ObsoleteStateId','ObsoleteStateID'))
        $dfltId= [string](Get-Prop $def @('DfltStateId','DefaultStateId'))

        $states = @()
        foreach ($s in (Get-Prop $def @('StateArray','States') @())) {
            $sid  = [string](Get-Prop $s @('Id'))
            $name = [string](Get-Prop $s @('DispName','DisplayName','Name'))
            $isRel = [bool](Get-Prop $s @('IsRel','IsReleased','Released') $false) -or ($relId -and $sid -eq $relId)
            $isObs = [bool](Get-Prop $s @('IsObs','IsObsolete','Obsolete') $false) -or ($obsId -and $sid -eq $obsId)
            $isDf  = [bool](Get-Prop $s @('IsDflt','IsDefault','Default') $false) -or ($dfltId -and $sid -eq $dfltId)
            $states += [ordered]@{
                id              = $sid
                name            = $name
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

        $config.lifecycles += [ordered]@{
            id          = [string](Get-Prop $def @('Id'))
            name        = [string](Get-Prop $def @('DispName','DisplayName','Name'))
            description = [string](Get-Prop $def @('Descr','Description'))
            states      = $states
            transitions = $trans
        }
    }
    Write-Host ("  {0} lifecycles." -f $config.lifecycles.Count)
} catch { Write-Warning "Lifecycle definitions failed: $($_.Exception.Message)" }

# --- Revision schemes ----------------------------------------------------
try {
    Write-Host "Reading revision schemes ..."
    $revs = $mgr.RevisionService.GetAllRevisionDefinitions()
    foreach ($r in $revs) {
        $config.revisionSchemes += [ordered]@{
            name      = [string](Get-Prop $r @('DispName','DisplayName','Name'))
            format    = [string](Get-Prop $r @('SchemeType','Format','Typ'))
            primary   = ""
            secondary = ""
            notes     = ""
        }
    }
    Write-Host ("  {0} revision schemes." -f $config.revisionSchemes.Count)
} catch { Write-Warning "Revision schemes failed: $($_.Exception.Message)" }

# --- Categories (names + entity; lifecycle/revision left for review) ------
try {
    Write-Host "Reading categories ..."
    foreach ($map in @(@{cls="FILE";ent="File"}, @{cls="FLDR";ent="Folder"}, @{cls="ITEM";ent="Item"}, @{cls="CO";ent="Change Order"})) {
        try {
            $cats = $mgr.CategoryService.GetCategoriesByEntityClassId($map.cls, $true)
            foreach ($c in $cats) {
                $config.categories += [ordered]@{
                    name      = [string](Get-Prop $c @('Name','DispName'))
                    entity    = $map.ent
                    lifecycle = ""
                    revision  = ""
                    notes     = ""
                }
            }
        } catch { Write-Warning "  category class $($map.cls): $($_.Exception.Message)" }
    }
    Write-Host ("  {0} categories." -f $config.categories.Count)
} catch { Write-Warning "Categories failed: $($_.Exception.Message)" }

# --- Top-level folders ---------------------------------------------------
try {
    Write-Host "Reading folder structure ..."
    $root = $mgr.DocumentService.GetFolderRoot()
    $folders = $mgr.DocumentService.GetFoldersByParentId($root.Id, $false)
    foreach ($f in $folders) {
        $config.folders += [ordered]@{
            id             = [string](Get-Prop $f @('Id'))
            name           = [string](Get-Prop $f @('FullName','Name'))
            createUserName = [string](Get-Prop $f @('CreateUserName','CreatedBy'))
            createDate     = ([string](Get-Prop $f @('CreateDate','Created'))) -split 'T' | Select-Object -First 1
        }
    }
    Write-Host ("  {0} folders." -f $config.folders.Count)
} catch { Write-Warning "Folder structure failed: $($_.Exception.Message)" }

# --- Write JSON ----------------------------------------------------------
try {
    $json = $config | ConvertTo-Json -Depth 12
    Set-Content -Path $OutFile -Value $json -Encoding UTF8
    Write-Host "`nWrote configuration to $OutFile" -ForegroundColor Green
    Write-Host "Open vault-config-dashboard.html and use 'Load Data' to load it."
} catch { Write-Warning "Failed to write $OutFile : $($_.Exception.Message)" }

# --- Disconnect ----------------------------------------------------------
try { $mgr.SignOut() } catch { }
