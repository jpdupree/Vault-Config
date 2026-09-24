<#
.SYNOPSIS
    Creates Vault Items from an Excel part list, renames the matching Vault file(s)
    to the item number, and links the files to the item.

.DESCRIPTION
    Refactor of the original createItems script (R. Smith, v2.2, 7/8/23).

    ALL SETTINGS ARE IN THE CONFIGURATION REGION DIRECTLY BELOW - edit those and run.

    v3.2 - Linking rebuilt on the calls proven against this Vault.
      * Primary link: ItemService.AssignFileToItem. UpdateItemFileAssociations
        returned OK but created no primary link on a new item.
      * Attachments: EditItems + ItemService.UpdateAttachments (existing
        attachments are kept).
      * Secondary / tertiary: UpdateItemFileAssociations once the item has a
        primary link - NOT YET CONFIRMED against this Vault.
      * Every link is read back from Vault afterwards; anything missing is
        logged as "NOT LINKED" instead of being reported as linked.
      * $RelinkExistingItems: rename and link files for items that already
        exist (only adds missing links, never replaces an existing primary).

    v3.1 - Multi-file linking and LL prefix rename.
      * Every Vault file whose name starts with a PartNum (followed by a
        separator . - _ or space) is matched to that item. When several
        PartNums fit, the longest one wins (1074-5.4375-A.ipt goes to
        1074-5.4375-A if that is also in the master list).
      * Files without the $FilePrefix (LL) are matched as if they had it,
        and are renamed to add it (1074-5.4375.ipt -> LL1074-5.4375.ipt).
      * Link rules per item:
          IPT/IAM   -> one Primary (exact-name IAM > exact-name IPT >
                       other IAM > other IPT), the rest Secondary
          IDW/DWG   -> Primary only if there is no IPT/IAM, otherwise Tertiary
          Other     -> Attachment

    v3.0 - Master list switched to "Wildeck LL Parts - Current Revisions" format.
      Master columns: PartNum | Latest Revision | RevShortDesc | Effective Date |
                      Approved Date | Approved By          (sheet: "Current Revs")

      Consequences of the new master list:
        * There is no PartNoLL column. PartNum is the item number, and the
          file is found by PartNum (with or without the LL prefix).
        * There is no Description or Type column. Those now come from the
          supplemental part list if present, otherwise they are left blank.
        * Revisions are numeric (1, 2, 3, 5, 20...), not alphabetic.
        * Approved By / Approved Date feed the "By" and "Date" item properties.

    Changes carried over from the v2.2 refactor:
      * Hashtable join instead of nested Where-Object (O(n) instead of O(n*m)).
      * Single canonical property-name map used end to end (fixes null writes).
      * -like instead of -contains for path matching.
      * Per-item try/catch with UndoEditItems so a failure does not leave
        items checked out.
      * AddItemNumbers restriction results are inspected before commit.
      * PropSync job passes the file version Id, not the MasterId.
      * Rename returns the new FileIteration so callers can test it.
      * Promote/update runs once in batch instead of once per item.
      * -WhatIf support for a dry run against the match/validation logic.

.EXAMPLE
    .\createItems.ps1 -WhatIf     # dry run, no Vault changes
    .\createItems.ps1             # live run

.NOTES
    Requires: powerVault, ImportExcel
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

#region =================== CONFIGURATION - EDIT THIS SECTION ===================

# --- Vault connection -------------------------------------------------------
$Server    = 'wiltestvault'
$VaultName = 'Vault'
$VaultUser = 'administrator'

# Leave $VaultPassword as $null to be prompted securely at run time (recommended).
$VaultPassword = $null

# --- Vault folder to search -------------------------------------------------
# Single quotes are required: "$/..." in double quotes will try to expand $/
$VaultPath = '$/Designs/Testing'

# --- MASTER list (drives the run) -------------------------------------------
# Wildeck LL Parts - Current Revisions format.
$MasterListPath  = 'C:\Devops\Wildeck\Wildeck LL Parts - Current Revisions 2026-08-27.xlsx'
$MasterSheetName = 'Test' #Current Revs'

# Column names in the master workbook. Change here if the header row changes.
$ColPartNum      = 'PartNum'
$ColRevision     = 'Latest Revision'
$ColRevShortDesc = 'RevShortDesc'
$ColEffectiveDte = 'Effective Date'
$ColApprovedDte  = 'Approved Date'
$ColApprovedBy   = 'Approved By'

# --- SUPPLEMENTAL list (optional attribute enrichment) ----------------------
# Joined to the master on PartNum. Set $UseSupplementalList = $false to skip it
# entirely and create items from the master list alone.
$UseSupplementalList = $true
$SupplementalListPath  = 'C:\Devops\Wildeck\TEST 100 Internal ENG file-PartNumberList OBS.xlsx'
$SupplementalSheetName = 'Test' #Part Numbers'
$ColSupplementalKey    = 'Part Num'    # join column in the supplemental workbook

# --- Logging ----------------------------------------------------------------
$LogFile = "C:\createItems log\log_$(Get-Date -f yyyyMMdd_HHmmss).csv"

# --- Vault schemes ----------------------------------------------------------
$NumberingScheme              = 'Mapped'
$NumericRevisionSchemeName    = 'Wildeck Numeric Format'
$AlphabeticRevisionSchemeName = 'Standard Alphabetic Format'

# --- Behavior toggles -------------------------------------------------------
$SkipRename  = $false    # $true = create/link items but do not rename files
$SkipPromote = $false    # $true = skip the BOM promote / assign-update stage

# Master rows with no matching file in Vault: $true = still create the item
# (number-only, nothing to link/rename), $false = skip the row entirely.
$CreateItemsWithoutFiles = $true

# Items that already exist in Vault: $true = still rename and link their files
# (only adds links that are missing - an existing primary link to a different
# file is never replaced). $false = leave existing items untouched.
$RelinkExistingItems = $false

# --- File name prefix -------------------------------------------------------
# Item numbers carry this prefix, Vault file names may not
# (file 1074-5.4375.ipt -> item LL1074-5.4375). Matched files without the
# prefix are renamed to add it. Set to '' to disable.
$FilePrefix = 'LL'

# --- File link rules --------------------------------------------------------
#   CAD      -> one Primary (exact-name IAM > exact-name IPT > other IAM > other IPT), rest Secondary
#   Drawings -> Primary only if there is no CAD file, otherwise Tertiary
#   Anything else -> Attachment
$CadExtensions     = @('iam', 'ipt')
$DrawingExtensions = @('idw', 'dwg')

# Attachments: $false = follow the latest file version, $true = pin to the linked version
$PinAttachments = $false

# --- Item property map ------------------------------------------------------
# Vault ITEM property display name -> column name on the merged data row.
# This single map drives BOTH the propdef lookup and the value write.
# Comment out any line whose property does not exist in your Vault.
$ItemPropertyMap = [ordered]@{
    'Type'                     = 'Type'
    'Material'                 = 'Material'
    'Reference Category'       = 'ReferenceCategory'
    'Replaced By'              = 'ReplacedBy'
    'Supplier'                 = 'Supplier'
    'Supplier Part Number'     = 'SupplierPartNumber'
    'Manufacturer'             = 'Manufacturer'
    'Manufacturer Part Number' = 'ManufacturerPartNumber'
    'By'                       = 'By'         # <- Approved By from master
    'Date'                     = 'Date'       # <- Approved Date from master
}

#endregion ========================= END CONFIGURATION =========================

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

#region ------------------------------------------------------------ Functions

function Write-Stage {
    param([string] $Message)
    Write-Host ("[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message) -ForegroundColor Cyan
}

function Initialize-Log {
    param([string] $Path)
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
    return $Path
}

function Format-LinkNames {
    param([object[]] $Entries)
    if (-not $Entries -or $Entries.Count -eq 0) { return '' }
    return (@($Entries | ForEach-Object Name) -join '; ')
}

function Add-LogRow {
    <#  Appends a single worklist row to the CSV. #>
    param($Row, [string] $Path)

    try {
        [PSCustomObject]@{
            'Timestamp'              = [datetime]::Now
            'Part Number'            = $Row.itemNumber
            'Master Revision'        = $Row.itemRevision
            'Rev Short Desc'         = $Row.revShortDesc
            'Revision Scheme'        = $Row.itemRevisionScheme
            'Original File Name'     = $Row.originalFileName
            'File Extension'         = $Row.extension
            'Original File Location' = $Row.originalFilePath
            'File Found in Vault?'   = $Row.matchComment
            'Matched Supp. List?'    = $Row.matchedSupplemental
            'Item Number Valid?'     = $Row.numberComment
            'Item Created?'          = $Row.itemComment
            'Item Revision Set?'     = $Row.revisionComment
            'File Renamed?'          = $Row.fileRenamedComment
            'New File Name'          = $Row.newFileName
            'File Linked to Item?'   = $Row.itemLinkComment
            'Secondary Links'        = Format-LinkNames $Row.linkPlan.Secondary
            'Tertiary Links'         = Format-LinkNames $Row.linkPlan.Tertiary
            'Attachments'            = Format-LinkNames $Row.linkPlan.Attachments
            'Error'                  = $Row.errorMessage
            'Other Comment'          = $Row.comment
        } | Export-Csv -Path $Path -NoTypeInformation -Append
    }
    catch {
        Write-Warning "Failed to write log row for '$($Row.itemNumber)': $($_.Exception.Message)"
    }
}

function Get-VaultErrorText {
    <#  Vault SOAP errors carry the real error code in the detail. #>
    param($ErrorRecord)
    $code = $null
    try { $code = $ErrorRecord.Exception.InnerException.Detail.InnerText } catch { }
    if (-not $code) { try { $code = $ErrorRecord.Exception.Detail.InnerText } catch { } }
    $msg = $ErrorRecord.Exception.Message
    if ($code) { $msg = "$msg (Vault error $code)" }
    return $msg
}

function Get-PropDefIdMap {
    param(
        [string[]] $DisplayNames,
        [ValidateSet('ITEM', 'FILE')][string] $EntityClassId
    )

    $defs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
    $map  = @{}

    foreach ($name in $DisplayNames) {
        $def = $defs | Where-Object { $_.DispName -eq $name } | Select-Object -First 1
        if ($def) { $map[$name] = $def.Id }
        else { Write-Warning "$EntityClassId property '$name' not found - it will not be added or written." }
    }
    return $map
}

function Resolve-RevisionScheme {
    <#  The master list is numeric, but keep alpha detection in case a
        hand-entered value like 'A' or 'x' shows up. #>
    param([string] $Revision)

    if ([string]::IsNullOrWhiteSpace($Revision)) { return $NumericRevisionSchemeName }
    if ($Revision -match '^\d+$')                { return $NumericRevisionSchemeName }
    if ($Revision -match '^[A-Za-z]+$')          { return $AlphabeticRevisionSchemeName }
    return $NumericRevisionSchemeName
}

function Resolve-ItemCategory {
    param([string] $FullPath, [string] $Extension)

    if ($FullPath -like '*Content Center Files*' -or
        $FullPath -like '*\Library\*' -or
        $FullPath -like '*/Library/*') {
        return 'Purchased'
    }
    switch ($Extension) {
        'iam'   { return 'Assembly' }
        'ipt'   { return 'Part' }
        default { return 'General' }
    }
}

function Test-BaseNameMatch {
    <#  True when $FileName starts with $Base followed by a separator.
        1074-5.4375 matches 1074-5.4375.ipt, 1074-5.4375-A.iam, 1074-5.4375.idw.pdf.pdf
        but not 1074-5.43751.ipt or 1074-5.4375.5.ipt #>
    param([string] $FileName, [string] $Base)

    if (-not $FileName.StartsWith($Base, [StringComparison]::OrdinalIgnoreCase)) { return $false }
    if ($FileName.Length -eq $Base.Length) { return $true }

    $next = $FileName[$Base.Length]
    if ([char]::IsLetterOrDigit($next)) { return $false }

    # "base.5..." is a longer decimal part number, not an extension
    if ($next -eq '.' -and $FileName.Length -gt $Base.Length + 1 -and
        [char]::IsDigit($FileName[$Base.Length + 1])) { return $false }

    return $true
}

function Get-OwningPartNum {
    <#  Returns the longest PartNum in $PartNums that $FileName belongs to, or $null. #>
    param([string] $FileName, [hashtable] $PartNums)

    for ($i = $FileName.Length; $i -gt 0; $i--) {
        if ($i -lt $FileName.Length -and [char]::IsLetterOrDigit($FileName[$i])) { continue }
        $candidate = $FileName.Substring(0, $i)
        if ($PartNums.ContainsKey($candidate) -and (Test-BaseNameMatch $FileName $candidate)) {
            return $candidate
        }
    }
    return $null
}

function Get-ItemFileLinkPlan {
    <#  Splits the files matched to one item into Primary / Secondary / Tertiary / Attachments.
        $Entries: objects with File, Name, MatchName, FolderPath, FullPath, NewName. #>
    param(
        [Parameter(Mandatory)][string] $ItemNumber,
        [object[]] $Entries = @()
    )

    $info = @(
        foreach ($e in $Entries) {
            if (-not $e) { continue }
            $n   = $e.MatchName
            $ext = [IO.Path]::GetExtension($n).TrimStart('.').ToLowerInvariant()
            [PSCustomObject]@{
                Entry = $e
                Name  = $n
                Ext   = $ext
                Exact = ([IO.Path]::GetFileNameWithoutExtension($n) -ieq $ItemNumber)
            }
        }
    )

    $cad = @($info | Where-Object { $CadExtensions -contains $_.Ext } |
             Sort-Object @{ e = { -not $_.Exact } }, @{ e = { if ($_.Ext -eq 'iam') { 0 } else { 1 } } }, Name)
    $drw = @($info | Where-Object { $DrawingExtensions -contains $_.Ext } |
             Sort-Object @{ e = { -not $_.Exact } }, @{ e = { if ($_.Ext -eq 'idw') { 0 } else { 1 } } }, Name)
    $oth = @($info | Where-Object { ($CadExtensions + $DrawingExtensions) -notcontains $_.Ext } |
             Sort-Object Name)

    $plan = [PSCustomObject]@{
        Primary     = $null
        Secondary   = @()
        Tertiary    = @()
        Attachments = @($oth | ForEach-Object Entry)
    }

    if ($cad.Count -gt 0) {
        $plan.Primary   = $cad[0].Entry
        $plan.Secondary = @($cad | Select-Object -Skip 1 | ForEach-Object Entry)
        $plan.Tertiary  = @($drw | ForEach-Object Entry)
    }
    elseif ($drw.Count -gt 0) {
        $plan.Primary  = $drw[0].Entry
        $plan.Tertiary = @($drw | Select-Object -Skip 1 | ForEach-Object Entry)
    }

    return $plan
}

function Get-LatestFileId {
    <#  Latest version Id for a gathered file (renames/check-ins create new versions). #>
    param($Entry)
    return $vault.DocumentService.GetLatestFileByMasterId($Entry.File.MasterId).Id
}

function Test-LinkEligible {
    <#  Items created in this run, plus existing items when $RelinkExistingItems is on. #>
    param($Row)
    if ($Row.itemCreated) { return $true }
    return ($RelinkExistingItems -and $null -ne $Row.item)
}

function Get-ItemLinks {
    <#  All file links on an item as Type/Name/FileId rows (one query per link type -
        filtering by a single type is confirmed to work). #>
    param([long] $ItemId)
    foreach ($opt in [enum]::GetNames([Autodesk.Connectivity.WebServices.ItemFileLnkTypOpt])) {
        foreach ($a in @($vault.ItemService.GetItemFileAssociationsByItemIds(@($ItemId), $opt))) {
            if ($a) { [PSCustomObject]@{ Type = $opt; Name = $a.FileName; FileId = [long]$a.CldFileId } }
        }
    }
}

$fileMasterCache = @{}
function Get-FileMasterId {
    <#  MasterId for a file version Id (cached). #>
    param([long] $FileId)
    if (-not $fileMasterCache.ContainsKey($FileId)) {
        $fileMasterCache[$FileId] = $vault.DocumentService.GetFileById($FileId).MasterId
    }
    return $fileMasterCache[$FileId]
}

function Get-MissingEntries {
    <#  Entries whose file (compared by MasterId) is not among the item's links of the given types. #>
    param([object[]] $Entries, [object[]] $Links, [string[]] $Types)
    $have = @($Links | Where-Object { $_ -and $Types -contains $_.Type } |
              ForEach-Object { Get-FileMasterId $_.FileId })
    @($Entries | Where-Object { $_ -and ($have -notcontains $_.File.MasterId) })
}

function Get-ItemAttachmentInfo {
    <#  Current attachments (Attmt objects with FileId/Pin). Readable = $false when the
        result object has no Attmt* property, so existing attachments are never overwritten blind. #>
    param([long] $ItemId)
    $info = [PSCustomObject]@{ Readable = $false; Items = @() }
    $att  = @($vault.ItemService.GetAttachmentsByItemIds(@($ItemId)))
    if ($att.Count -gt 0 -and $att[0]) {
        $prop = $att[0].PSObject.Properties | Where-Object { $_.Name -like 'Attmt*' } | Select-Object -First 1
        if ($prop) {
            $info.Readable = $true
            if ($prop.Value) { $info.Items = @($prop.Value) }
        }
    }
    else { $info.Readable = $true }    # nothing returned = no attachments
    return $info
}

function Set-ItemFileAssociations {
    <#  Writes the item's full link set with UpdateItemFileAssociations.
        NOT YET CONFIRMED for secondary/tertiary links: on a new item without a primary
        link this call returned OK but created nothing, so callers always read the links
        back. -UseEdit puts the item in edit first; without it the call is made on the
        committed item, the same way AssignFileToItem works. #>
    param(
        [Parameter(Mandatory)][string] $ItemNumber,
        [long]   $PrimaryId,
        [bool]   $PrimaryIsSub,
        [long[]] $SecondaryIds = @(),
        [long[]] $StdCompIds   = @(),
        [long[]] $SecSubIds    = @(),
        [long[]] $TertiaryIds  = @(),
        [switch] $UseEdit
    )

    $item   = $vault.ItemService.GetLatestItemByItemNumber($ItemNumber)
    $revId  = $item.RevId
    $inEdit = $false
    try {
        if ($UseEdit) {
            $revId  = ($vault.ItemService.EditItems(@($item.RevId)))[0].RevId
            $inEdit = $true
        }
        $r = $vault.ItemService.UpdateItemFileAssociations(
                $revId, $PrimaryId, $PrimaryIsSub,
                [long[]]@($SecondaryIds), [long[]]@($StdCompIds), [long[]]@($SecSubIds), [long[]]@($TertiaryIds))
        $inEdit = $true
        $vault.ItemService.UpdateAndCommitItems(@($r)) | Out-Null
    }
    catch {
        if ($inEdit) { try { $vault.ItemService.UndoEditItems(@($revId)) | Out-Null } catch { } }
        throw
    }
}

function New-VaultItemRecord {
    <#  Creates an item, adds the propdefs, assigns the number, writes values.
        Undoes the edit on any failure so the item is not left checked out. #>
    param(
        [Parameter(Mandatory)][string] $Number,
        [Parameter(Mandatory)][string] $CategoryName,
        [Parameter(Mandatory)][hashtable] $PropDefIdMap,
        [Parameter(Mandatory)] $DataRow
    )

    $item = $null

    try {
        $categories = $vault.CategoryService.GetCategoriesByEntityClassId('ITEM', $true)
        $category   = $categories | Where-Object { $_.Name -eq $CategoryName } | Select-Object -First 1
        if (-not $category) { throw "Item category '$CategoryName' not found in Vault." }

        $numSchemes = $vault.NumberingService.GetNumberingSchemes('ITEM', 'Activated')
        $numScheme  = $numSchemes | Where-Object { $_.Name -eq $NumberingScheme } | Select-Object -First 1
        if (-not $numScheme) { throw "Item numbering scheme '$NumberingScheme' not found or not activated." }

        # --- create the item revision
        $item      = $vault.ItemService.AddItemRevision($category.Id)
        $item.Comm = 'Item created by script'

        try   { $vault.ItemService.UpdateAndCommitItems(@($item)) | Out-Null }
        catch { Write-Verbose "Initial commit returned $($_.Exception.Message) for new item - continuing." }

        # --- add property definitions (AddItemRevision does not add category props)
        if ($PropDefIdMap.Count -gt 0) {
            $edited = $vault.ItemService.EditItems(@($item.RevId))
            $item   = $edited[0]
            $vault.ItemService.UpdateItemPropertyDefinitions(
                @($item.MasterId), [int[]]$PropDefIdMap.Values, @(), 'Adding properties to item') | Out-Null
        }

        # --- assign the number, checking restrictions before committing
        $edited = $vault.ItemService.EditItems(@($item.RevId))
        $item   = $edited[0]

        $stringArray       = New-Object Autodesk.Connectivity.WebServices.StringArray
        $stringArray.Items = @($Number)
        $restrictions      = $null

        $itemNums = $vault.ItemService.AddItemNumbers(
            @($item.MasterId), @($numScheme.SchmID), @($stringArray), [ref]$restrictions)

        if ($restrictions) {
            $msg = ($restrictions | ForEach-Object { $_.Msg }) -join '; '
            if ($msg) { throw "Number '$Number' rejected by Vault: $msg" }
        }

        $itemNum = $itemNums[0]
        $vault.ItemService.CommitItemNumbers(@($itemNum.ItemMasterId), @($itemNum.ItemNum1)) | Out-Null

        $item.ItemNum = $itemNum.ItemNum1
        $item.Comm    = 'Item renamed by script'
        $vault.ItemService.UpdateAndCommitItems(@($item)) | Out-Null

        # --- write property values using the same canonical map
        $props = @{}
        foreach ($dispName in $ItemPropertyMap.Keys) {
            if (-not $PropDefIdMap.ContainsKey($dispName)) { continue }
            $value = $DataRow.($ItemPropertyMap[$dispName])
            if ($null -ne $value -and "$value" -ne '') { $props[$dispName] = $value }
        }

        $updateArgs = @{ Number = $itemNum.ItemNum1 }
        if ($DataRow.Description) { $updateArgs['Description'] = $DataRow.Description }
        if ($props.Count -gt 0)   { $updateArgs['Properties']  = $props }

        Update-VaultItem @updateArgs | Out-Null

        return $vault.ItemService.GetLatestItemByItemNumber($itemNum.ItemNum1)
    }
    catch {
        if ($item -and $item.RevId) {
            try { $vault.ItemService.UndoEditItems(@($item.RevId)) | Out-Null }
            catch { Write-Warning "UndoEditItems failed for '$Number': $($_.Exception.Message)" }
        }
        throw
    }
}

function Rename-VaultFileIteration {
    <#  Renames a file in Vault, preserving child associations.
        Returns the new FileIteration.
        NOTE: parent files (drawings/assemblies) that reference this file are
        not updated - their internal reference still uses the old name. #>
    param(
        [Parameter(Mandatory)][string] $CurrentFullPath,
        [Parameter(Mandatory)][string] $NewFileName,
        [string] $Comment = 'Renamed via script when creating Items'
    )

    $localFile = Save-VaultFile -File $CurrentFullPath -ExcludeChildren
    $vaultFile = $vault.DocumentService.GetLatestFileByMasterId($localFile.MasterId)
    $iteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration(
                    $vaultConnection, $vaultFile)

    # Child associations must be re-supplied on checkin or they are dropped.
    $assocParams = @()
    $assocs = $vault.DocumentService.GetFileAssociationsByIds(
        @($iteration.EntityIterationId), 'None', $false, 'All', $false, $false, $true)

    if ($assocs -and $assocs[0].FileAssocs) {
        foreach ($assoc in $assocs[0].FileAssocs) {
            $p = New-Object Autodesk.Connectivity.WebServices.FileAssocParam
            $p.CldFileId         = $assoc.CldFile.Id
            $p.ExpectedVaultPath = $assoc.ExpectedVaultPath
            $p.RefId             = $assoc.RefId
            $p.Source            = $assoc.Source
            $p.Typ               = $assoc.Typ
            $assocParams += $p
        }
    }

    $settings = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.AcquireFilesSettings($vaultConnection)
    $settings.OptionsRelationshipGathering.FileRelationshipSettings.IncludeChildren = $false
    $settings.OptionsRelationshipGathering.FileRelationshipSettings.RecurseChildren = $false
    $settings.OptionsRelationshipGathering.FileRelationshipSettings.VersionGatheringOption = 'Latest'
    $settings.AddFileToAcquire($iteration, 'Checkout')
    $vaultConnection.FileManager.AcquireFiles($settings) | Out-Null

    try {
        return $vaultConnection.FileManager.CheckinFile(
            $iteration, $Comment, $false, $assocParams, $null, $true,
            $NewFileName, $iteration.FileClassification, $iteration.IsHidden, $null)
    }
    catch {
        try { $vaultConnection.FileManager.UndoCheckoutFile($iteration) | Out-Null } catch { }
        throw
    }
}

function Test-VaultFileNameAvailable {
    param([string] $FolderPath, [string] $FileName)
    try {
        $existing = $vault.DocumentService.FindLatestFilesByPaths(@("$FolderPath/$FileName"))
        return (-not $existing -or -not $existing[0] -or $existing[0].Id -le 0)
    }
    catch { return $true }
}

function Get-JobParam {
    param([string] $Key, [string] $Value)
    $p = New-Object Autodesk.Connectivity.WebServices.JobParam
    $p.Name = $Key
    $p.Val  = $Value
    return $p
}

function Add-PropSyncJob {
    param(
        [Parameter(Mandatory)] $File,
        [string] $NewFileName,
        [int] $Priority = 100,
        [switch] $QueueDWFJob
    )

    $fileVersionId = $File.Id    # file version Id, not MasterId

    [Autodesk.Connectivity.WebServices.JobParam[]] $params = @(
        (Get-JobParam 'FileVersionId' "$fileVersionId")
        (Get-JobParam 'EntityId'      "$fileVersionId")
        (Get-JobParam 'EntityClassId' 'FILE')
        (Get-JobParam 'QueueCreateDwfJobOnCompletion' $QueueDWFJob.IsPresent.ToString())
    )

    return $vaultConnection.WebServiceManager.JobService.AddJob(
        'Autodesk.Vault.SyncProperties',
        "Synchronize properties for file $NewFileName",
        $params, $Priority)
}

function Invoke-ItemPromote {
    <#  Runs the promote/update cycle ONCE for a set of items. #>
    param([string[]] $ItemNumbers)

    $committed = @()

    foreach ($number in $ItemNumbers) {
        try {
            $item = $vault.ItemService.GetLatestItemByItemNumber($number)
            if (-not $item -or $item.Locked) { continue }
            $vault.ItemService.UpdatePromoteComponents(
                $item.RevId,
                [Autodesk.Connectivity.WebServices.ItemAssignAll]::Default,
                $true) | Out-Null
        }
        catch {
            Write-Warning "UpdatePromoteComponents failed for '$number': $($_.Exception.Message)"
        }
    }

    try {
        $timestamp  = [DateTime]::Now
        $components = $vault.ItemService.GetPromoteComponentOrder([ref]$timestamp)

        if ($components -and $components.PrimaryArray) {
            $vault.ItemService.PromoteComponents($timestamp, $components.PrimaryArray) | Out-Null
            $result = $vault.ItemService.GetPromoteComponentsResults($timestamp)

            for ($i = 0; $i -lt $result.ItemRevArray.Length; $i++) {
                if ($result.StatusArray[$i] -gt 1) {     # 1 = Unaffected
                    $committed += $result.ItemRevArray[$i]
                }
            }

            if ($committed.Count -gt 0) {
                $vault.ItemService.UpdateAndCommitItems($committed) | Out-Null
                Write-Stage "Promoted and committed $($committed.Count) item(s)."
            }
        }
    }
    catch {
        Write-Warning "Promote stage failed: $($_.Exception.Message)"
        foreach ($rev in $committed) {
            try { $vault.ItemService.UndoEditItems(@($rev.RevId)) | Out-Null } catch { }
        }
    }
}

function Get-CellValue {
    <#  Safe column read - returns $null when the column is absent, rather than
        throwing under Set-StrictMode. #>
    param($Row, [string] $ColumnName)

    if (-not $ColumnName) { return $null }
    $prop = $Row.PSObject.Properties[$ColumnName]
    if ($prop) { return $prop.Value }
    return $null
}

#endregion

#region ------------------------------------------------------------ Connect

Import-Module powerVault  -ErrorAction Stop
Import-Module ImportExcel -ErrorAction Stop

if ([string]::IsNullOrEmpty($VaultPassword)) {
    $cred = Get-Credential -UserName $VaultUser -Message "Vault credentials for $Server\$VaultName"
    if (-not $cred) { throw 'No credentials supplied.' }
    $VaultUser     = $cred.UserName
    $VaultPassword = $cred.GetNetworkCredential().Password
}

Write-Stage "Connecting to $Server\$VaultName as $VaultUser ..."
Open-VaultConnection -Server $Server -Vault $VaultName `
                     -User $VaultUser -Password $VaultPassword | Out-Null

# Verify against the module globals, not a return value.
if (-not $vaultConnection -or -not $vault) {
    throw "Could not connect to Vault '$VaultName' on '$Server' as '$VaultUser'."
}

# Prove the session actually works before doing anything destructive.
try {
    $null = $vault.DocumentService.GetFolderByPath('$/')
}
catch {
    throw "Connected to '$VaultName' but the session is not usable: $($_.Exception.Message)"
}

Write-Stage "Connected. Vault session established."

$LogFile = Initialize-Log -Path $LogFile
Write-Stage "Log: $LogFile"

#endregion

#region ------------------------------------------------------------ Load master list

Write-Stage "Importing master list: $(Split-Path $MasterListPath -Leaf) [$MasterSheetName]"
$masterRows = @(Import-Excel -Path $MasterListPath -WorksheetName $MasterSheetName)

if ($masterRows.Count -eq 0) { throw "No rows found in '$MasterListPath' / '$MasterSheetName'." }

# Verify the expected header row is actually present before doing any work.
$firstRow    = $masterRows[0]
$presentCols = $firstRow.PSObject.Properties.Name
$missingCols = @(@($ColPartNum, $ColRevision) | Where-Object { $_ -notin $presentCols })
if ($missingCols.Count -gt 0) {
    throw ("Master sheet '$MasterSheetName' is missing required column(s): {0}. Found: {1}" -f
           ($missingCols -join ', '), ($presentCols -join ', '))
}

# --- optional supplemental list, indexed for an O(1) join
$suppIndex = @{}
if ($UseSupplementalList) {
    if (Test-Path -LiteralPath $SupplementalListPath) {
        Write-Stage "Importing supplemental list: $(Split-Path $SupplementalListPath -Leaf) [$SupplementalSheetName]"
        $suppRows = @(Import-Excel -Path $SupplementalListPath -WorksheetName $SupplementalSheetName)
        foreach ($row in $suppRows) {
            $key = "$(Get-CellValue -Row $row -ColumnName $ColSupplementalKey)".Trim()
            if ($key) {
                if ($suppIndex.ContainsKey($key)) {
                    Write-Warning "Duplicate '$ColSupplementalKey' in supplemental list: $key (using first occurrence)."
                }
                else { $suppIndex[$key] = $row }
            }
        }
        Write-Stage "Supplemental list indexed: $($suppIndex.Count) unique part number(s)."
    }
    else {
        Write-Warning "Supplemental list not found at '$SupplementalListPath' - continuing with master list only."
    }
}

# --- build the merged item list
$itemList     = [System.Collections.Generic.List[object]]::new()
$dupeMaster   = 0
$seenPartNums = @{}

foreach ($m in $masterRows) {

    $partNum = "$(Get-CellValue -Row $m -ColumnName $ColPartNum)".Trim()
    if (-not $partNum) { continue }

    if ($seenPartNums.ContainsKey($partNum)) {
        Write-Warning "Duplicate PartNum in master list: $partNum (first occurrence kept)."
        $dupeMaster++
        continue
    }
    $seenPartNums[$partNum] = $true

    $s = if ($suppIndex.ContainsKey($partNum)) { $suppIndex[$partNum] } else { $null }

    # Property names here are the canonical ones used by $ItemPropertyMap.
    $itemList.Add([PSCustomObject]@{
        PartNum                = $partNum
        Revision               = "$(Get-CellValue -Row $m -ColumnName $ColRevision)".Trim()
        RevShortDesc           = Get-CellValue -Row $m -ColumnName $ColRevShortDesc
        EffectiveDate          = Get-CellValue -Row $m -ColumnName $ColEffectiveDte
        By                     = Get-CellValue -Row $m -ColumnName $ColApprovedBy
        Date                   = Get-CellValue -Row $m -ColumnName $ColApprovedDte

        # From the supplemental list when available, otherwise blank.
        Description            = if ($s) { Get-CellValue -Row $s -ColumnName 'Description' }      else { $null }
        Type                   = if ($s) { Get-CellValue -Row $s -ColumnName 'Type' }             else { $null }
        OldNum                 = if ($s) { Get-CellValue -Row $s -ColumnName 'Old Num' }          else { $null }
        H1                     = if ($s) { Get-CellValue -Row $s -ColumnName 'H1' }               else { $null }
        Material               = if ($s) { Get-CellValue -Row $s -ColumnName 'Material' }         else { $null }
        ReferenceCategory      = if ($s) { Get-CellValue -Row $s -ColumnName 'Ref Category' }     else { $null }
        ReplacedBy             = if ($s) { Get-CellValue -Row $s -ColumnName 'Replaced By' }      else { $null }
        Supplier               = if ($s) { Get-CellValue -Row $s -ColumnName 'Supplier' }         else { $null }
        SupplierPartNumber     = if ($s) { Get-CellValue -Row $s -ColumnName 'Supplier PartNum' } else { $null }
        Manufacturer           = if ($s) { Get-CellValue -Row $s -ColumnName 'Manufacturer' }     else { $null }
        ManufacturerPartNumber = if ($s) { Get-CellValue -Row $s -ColumnName 'Mfr PartNum' }      else { $null }

        MatchedSupplemental    = [bool]$s
    })
}

Write-Stage ("Master rows: {0} unique part number(s){1}; {2} enriched from the supplemental list." -f
             $itemList.Count,
             $(if ($dupeMaster) { ", $dupeMaster duplicate(s) skipped" } else { '' }),
             @($itemList | Where-Object MatchedSupplemental).Count)

#endregion

#region ------------------------------------------------------------ Gather Vault files

Write-Stage "Gathering files under $VaultPath ..."
$rootFolder = $vault.DocumentService.GetFolderByPath($VaultPath)
if (-not $rootFolder) { throw "Vault folder '$VaultPath' not found." }

$allFolders = [System.Collections.Generic.List[object]]::new()
$allFolders.Add($rootFolder)
$sub = $vault.DocumentService.GetFoldersByParentId($rootFolder.Id, $true)
if ($sub) { foreach ($f in $sub) { $allFolders.Add($f) } }

$fileEntries = [System.Collections.Generic.List[object]]::new()
foreach ($folder in $allFolders) {
    $found = $vault.DocumentService.GetLatestFilesByFolderId($folder.Id, $false)
    if ($found) {
        foreach ($f in $found) {
            $fileEntries.Add([PSCustomObject]@{
                File       = $f
                Name       = $f.Name
                FolderPath = $folder.FullName
                FullPath   = "$($folder.FullName)/$($f.Name)"
                MatchName  = $f.Name      # name used for matching (prefixed if needed)
                NewName    = $null        # set when the file needs the prefix added
            })
        }
    }
}
Write-Stage "Found $($fileEntries.Count) file(s) in $($allFolders.Count) folder(s)."

# Group every file under the PartNum it belongs to (longest match wins).
# Files missing the prefix are matched as if they had it, and flagged for rename.
$filesByPart = @{}
foreach ($e in $fileEntries) {
    $owner = Get-OwningPartNum -FileName $e.Name -PartNums $seenPartNums

    if (-not $owner -and $FilePrefix -and
        -not $e.Name.StartsWith($FilePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $owner = Get-OwningPartNum -FileName ($FilePrefix + $e.Name) -PartNums $seenPartNums
        if ($owner) {
            $e.MatchName = $FilePrefix + $e.Name
            $e.NewName   = $e.MatchName
        }
    }

    if (-not $owner) { continue }
    if (-not $filesByPart.ContainsKey($owner)) {
        $filesByPart[$owner] = [System.Collections.Generic.List[object]]::new()
    }
    $filesByPart[$owner].Add($e)
}
$needRename = @($fileEntries | Where-Object NewName).Count
Write-Stage "Matched files to $($filesByPart.Count) part number(s); $needRename file(s) need the '$FilePrefix' prefix."

#endregion

#region ------------------------------------------------------------ Build worklist

$workList = [System.Collections.Generic.List[object]]::new()
$skipped  = 0
$noFile   = 0

foreach ($row in $itemList) {

    $entries = @(if ($filesByPart.ContainsKey($row.PartNum)) { $filesByPart[$row.PartNum] })
    $plan    = Get-ItemFileLinkPlan -ItemNumber $row.PartNum -Entries $entries

    # Same file name (after prefixing) in more than one folder, or with and without the prefix
    $dupes = @($entries | Group-Object { $_.MatchName.ToLowerInvariant() } | Where-Object Count -gt 1)
    foreach ($d in $dupes) {
        Write-Warning ("[$($row.PartNum)] AMBIGUOUS: $($d.Count) files match '$($d.Group[0].MatchName)': " +
                       (($d.Group | ForEach-Object FullPath) -join ', '))
    }

    $hit = if ($plan.Primary) { $plan.Primary.File } else { $null }
    $matchComment = $null
    if ($entries.Count -gt 0) {
        $toRen = @($entries | Where-Object NewName).Count
        $matchComment = "Primary: $(if ($plan.Primary) { $plan.Primary.Name } else { 'none' }); " +
                        "Secondary: $($plan.Secondary.Count); Tertiary: $($plan.Tertiary.Count); " +
                        "Attachments: $($plan.Attachments.Count); To rename: $toRen" +
                        $(if ($dupes.Count) { ' - AMBIGUOUS duplicate names' } else { '' })
    }

    $file = $null
    if ($hit) {
        $file = Get-VaultFile -FileId $hit.Id
        if (-not $file) {
            Write-Warning "Get-VaultFile returned nothing for id $($hit.Id) ($($row.PartNum)) - skipped."
            $skipped++
            continue
        }
    }
    elseif ($entries.Count -eq 0) {
        $noFile++
        $matchComment = 'No file found in Vault'
        if (-not $CreateItemsWithoutFiles) {
            Write-Warning "$($row.PartNum) not found in Vault - skipped."
            $skipped++
            continue
        }
        Write-Warning "$($row.PartNum) not found in Vault - item will be created without a file."
    }
    # else: attachments only (no CAD/drawing) - item is created, files attached, no primary link

    $workList.Add([PSCustomObject]@{
        fileIteration        = $hit
        file                 = $file
        fileId               = if ($file) { $file.Id }          else { $null }
        originalFileName     = if ($file) { $file.Name }        else { $null }
        extension            = if ($file) { "$($file._Extension)".ToLowerInvariant() } else { $null }
        originalFilePath     = if ($file) { $file._FullPath }   else { $null }
        folderPath           = if ($file) { $file._FolderPath } else { $null }
        hasFile              = [bool]$file
        matchComment         = $matchComment
        matchedSupplemental  = $row.MatchedSupplemental

        itemNumber           = $row.PartNum
        itemRevision         = $row.Revision
        revShortDesc         = $row.RevShortDesc
        itemRevisionScheme   = Resolve-RevisionScheme -Revision $row.Revision

        numberIsValid        = $false
        numberComment        = $null
        item                 = $null
        itemCreated          = $false
        itemComment          = $null
        revisionComment      = $null
        fileRenamedComment   = $null
        newFileName          = $null
        newFilePath          = $null
        itemLinkComment      = $null
        errorMessage         = $null
        comment              = $null
        dataRow              = $row
        linkPlan             = $plan
        linkedThisRun        = $false
    })
}

Write-Stage "Worklist: $($workList.Count) row(s) to process; $noFile with no file in Vault; $skipped skipped."
if ($workList.Count -eq 0) { Write-Warning 'Nothing to process.'; return }

#endregion

#region ------------------------------------------------------------ Validate numbers

foreach ($w in $workList) {
    # Replace with your real format check (checkNumberFormat) when available.
    $w.numberIsValid = -not [string]::IsNullOrWhiteSpace($w.itemNumber)
    $w.numberComment = if ($w.numberIsValid) { 'Item number is valid' } else { 'Item number is not valid' }
}

$propDefIdMap = Get-PropDefIdMap -DisplayNames $ItemPropertyMap.Keys -EntityClassId 'ITEM'
Write-Stage "Resolved $($propDefIdMap.Count) of $($ItemPropertyMap.Count) item property definition(s)."

#endregion

#region ------------------------------------------------------------ Create items

$n = 0
foreach ($w in $workList) {
    $n++
    Write-Progress -Activity 'Creating items' -Status "$n of $($workList.Count): $($w.itemNumber)" `
                   -PercentComplete (($n / $workList.Count) * 100)

    if (-not $w.numberIsValid) {
        $w.itemComment = 'Item number invalid, item not created'
        continue
    }

    try {
        $existing = $null
        try   { $existing = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber) }
        catch { $existing = $null }   # 1350 = not found, the expected path
        if ($existing) {
            $w.item        = $existing
            $w.itemComment = 'Item already exists, no item created'
            continue
        }

        $category = if ($w.hasFile) {
                        Resolve-ItemCategory -FullPath $w.originalFilePath -Extension $w.extension
                    } else { 'General' }

        if ($PSCmdlet.ShouldProcess($w.itemNumber, "Create $category item")) {
            $w.item        = New-VaultItemRecord -Number $w.itemNumber -CategoryName $category `
                                                 -PropDefIdMap $propDefIdMap -DataRow $w.dataRow
            $w.itemCreated = [bool]$w.item
            $w.itemComment = if ($w.itemCreated) { "Item $($w.item.ItemNum) created ($category)" }
                             else { 'Item not created' }
        }
        else { $w.itemComment = "WhatIf: would create $category item" }
    }
    catch {
        $w.errorMessage = $_.Exception.Message
        $w.itemComment  = 'Item creation failed'
        Write-Warning "[$($w.itemNumber)] $($_.Exception.Message)"
    }
}
Write-Progress -Activity 'Creating items' -Completed

#endregion

#region ------------------------------------------------------------ Set item revisions

# Look up scheme IDs by name - IDs differ between vaults
$revDefIds = @{}
$revDefInfo = $vault.RevisionService.GetAllRevisionDefinitionInfo()
foreach ($rd in $revDefInfo.RevDefArray) {
    $revDefIds[$rd.DispName] = $rd.Id
}
Write-Verbose ("Revision schemes: " + (($revDefIds.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))

foreach ($w in $workList) {
    if (-not $w.itemCreated) { continue }

    if ([string]::IsNullOrWhiteSpace($w.itemRevision)) {
        $w.revisionComment = 'No revision in master list - left as created'
        continue
    }

    # Always work from the latest committed version, not the object captured at create time
    $latest = $null
    try   { $latest = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber) }
    catch { $latest = $null }

    if (-not $latest) {
        $w.revisionComment = 'Item not found when setting revision'
        Write-Warning "[$($w.itemNumber)] $($w.revisionComment)"
        continue
    }

    $currentRev = $latest.RevNum
    if ("$currentRev" -eq "$($w.itemRevision)") {
        $w.revisionComment = "Already at revision $($w.itemRevision)"
        continue
    }

    $schemeName = $w.itemRevisionScheme
    if (-not $revDefIds.ContainsKey($schemeName)) {
        $w.revisionComment = "Revision scheme '$schemeName' not found. Available: $($revDefIds.Keys -join ', ')"
        Write-Warning "[$($w.itemNumber)] $($w.revisionComment)"
        continue
    }

    if ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($w.itemNumber, "Set revision $currentRev -> $($w.itemRevision) ($schemeName)")) {
        $w.revisionComment = "WhatIf: would set revision $currentRev -> $($w.itemRevision)"
        continue
    }

    try {
        $result = $vault.ItemService.UpdateRevisionDefinitionAndNumbers(
            [long[]]@($latest.Id),                       # Item.Id, not RevId
            [long[]]@($revDefIds[$schemeName]),
            [string[]]@("$($w.itemRevision)"),
            'Revision set by script')

        $after = if ($result) { $result[0].RevNum } else { $null }
        if ("$after" -eq "$($w.itemRevision)") {
            $w.item            = $result[0]               # keep the fresh object
            $w.revisionComment = "Revision set to $($w.itemRevision)"
        }
        else {
            $w.revisionComment = "REVISION NOT APPLIED: requested $($w.itemRevision), item is at $after"
            Write-Warning "[$($w.itemNumber)] $($w.revisionComment)"
        }
    }
    catch {
        $w.errorMessage    = "Revision set failed: $(Get-VaultErrorText $_)"
        $w.revisionComment = 'Revision not set (error)'
        Write-Warning "[$($w.itemNumber)] $($w.errorMessage)"
    }
}

#endregion

#region ------------------------------------------------------------ Rename files

$renameCount = 0

if (-not $SkipRename) {
    foreach ($w in $workList) {
        if (-not (Test-LinkEligible $w)) { $w.fileRenamedComment = 'File not renamed'; continue }

        $plan = $w.linkPlan
        $all  = @(@($plan.Primary) + $plan.Secondary + $plan.Tertiary + $plan.Attachments |
                  Where-Object { $_ })
        $toRename = @($all | Where-Object { $_.NewName })

        if ($all.Count -eq 0)      { $w.fileRenamedComment = 'No file to rename'; continue }
        if ($toRename.Count -eq 0) { $w.fileRenamedComment = 'Already named for item number'; continue }

        $notes = [System.Collections.Generic.List[string]]::new()

        foreach ($e in $toRename) {
            if (-not (Test-VaultFileNameAvailable -FolderPath $e.FolderPath -FileName $e.NewName)) {
                $notes.Add("COLLISION: $($e.NewName) already exists - $($e.Name) not renamed")
                Write-Warning "[$($w.itemNumber)] $($notes[-1])"
                continue
            }

            if (-not $PSCmdlet.ShouldProcess($e.FullPath, "Rename to $($e.NewName)")) {
                $notes.Add("WhatIf: $($e.Name) -> $($e.NewName)")
                continue
            }

            try {
                $renamed = Rename-VaultFileIteration -CurrentFullPath $e.FullPath -NewFileName $e.NewName
                if (-not $renamed) { throw 'Rename returned no result' }

                # Confirm Vault actually holds the new name - CheckinFile can return without renaming
                $latestFile = $vault.DocumentService.GetLatestFileByMasterId($e.File.MasterId)
                if ($latestFile.Name -ne $e.NewName) {
                    throw "RENAME NOT APPLIED: Vault still shows '$($latestFile.Name)' (version $($latestFile.VerNum), checked out: $($latestFile.CheckedOut))"
                }

                Write-Host "  $($e.Name) -> $($e.NewName)"
                $renameCount++
                $notes.Add("$($e.Name) -> $($e.NewName)")
                $e.Name     = $e.NewName
                $e.FullPath = "$($e.FolderPath)/$($e.NewName)"
                $e.NewName  = $null
            }
            catch {
                $msg = "Rename failed ($($e.Name)): $(Get-VaultErrorText $_)"
                $w.errorMessage = if ($w.errorMessage) { "$($w.errorMessage); $msg" } else { $msg }
                $notes.Add("FAILED: $($e.Name)")
                Write-Warning "[$($w.itemNumber)] $msg"
            }
        }

        if ($plan.Primary) {
            $w.newFileName = $plan.Primary.Name
            $w.newFilePath = $plan.Primary.FullPath
        }
        $w.fileRenamedComment = $notes -join ' | '
    }
}
else { Write-Stage 'Rename stage skipped ($SkipRename = $true).' }

#endregion

#region ------------------------------------------------------------ Link files to items

# Link methods, as tested against this Vault:
#   Primary     -> AssignFileToItem           (confirmed; UpdateItemFileAssociations returned
#                                              OK on a new item but created no primary link)
#   Attachments -> EditItems + UpdateAttachments  (confirmed)
#   Secondary / Tertiary -> UpdateItemFileAssociations once the item has a primary link
#                                             (NOT YET CONFIRMED - see Set-ItemFileAssociations)
# Everything is read back from Vault at the end; anything missing is logged as NOT LINKED.

foreach ($w in $workList) {
    if (-not (Test-LinkEligible $w)) { continue }

    $plan = $w.linkPlan
    if (-not $plan.Primary -and $plan.Attachments.Count -eq 0) {
        $w.itemLinkComment = 'No file to link'
        if ($w.itemCreated) { $w.comment = 'Item created (number only, no file)' }
        continue
    }

    $summary = "primary: $(if ($plan.Primary) { $plan.Primary.Name } else { 'none' }), " +
               "$($plan.Secondary.Count) secondary, $($plan.Tertiary.Count) tertiary, $($plan.Attachments.Count) attachment(s)"

    if (-not $PSCmdlet.ShouldProcess($w.itemNumber, "Link files ($summary)")) {
        $w.itemLinkComment = "WhatIf: would link $summary"
        continue
    }

    $notes           = [System.Collections.Generic.List[string]]::new()
    $problem         = $false
    $primaryConflict = $false
    $assocErr        = $null

    try {
        # --- 1) Primary link: AssignFileToItem
        if ($plan.Primary) {
            $item  = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber)
            $prim  = @(Get-ItemLinks -ItemId $item.Id | Where-Object { $_.Type -in 'Primary', 'PrimarySub' })

            if ($prim.Count -eq 0) {
                $primaryId = Get-LatestFileId $plan.Primary
                $linked    = $vault.ItemService.AssignFileToItem($item.RevId, $primaryId)
                $vault.ItemService.UpdateAndCommitItems(@($linked)) | Out-Null
                $w.linkedThisRun = $true

                # Property sync on the newly linked primary file
                try {
                    $primaryFile = Get-VaultFile -FileId $primaryId
                    if ($primaryFile) { $null = Add-PropSyncJob -File $primaryFile -NewFileName $primaryFile.Name }
                }
                catch { Write-Warning "[$($w.itemNumber)] PropSync job not queued: $($_.Exception.Message)" }
            }
            elseif (@(Get-MissingEntries -Entries @($plan.Primary) -Links $prim -Types 'Primary', 'PrimarySub').Count -gt 0) {
                # Never replace a primary link that points at a different file
                $notes.Add("Item already has primary $($prim[0].Name) - $($plan.Primary.Name) NOT LINKED")
                $primaryConflict = $true
                $problem         = $true
            }
        }

        # --- 2) Secondary / tertiary links (need a primary link on the item)
        if ($plan.Secondary.Count -gt 0 -or $plan.Tertiary.Count -gt 0) {
            $item    = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber)
            $links   = @(Get-ItemLinks -ItemId $item.Id)
            $prim    = @($links | Where-Object { $_.Type -in 'Primary', 'PrimarySub' })
            $missSec = @(Get-MissingEntries -Entries $plan.Secondary -Links $links -Types 'Secondary')
            $missTer = @(Get-MissingEntries -Entries $plan.Tertiary  -Links $links -Types 'Tertiary')

            if (($missSec.Count -gt 0 -or $missTer.Count -gt 0) -and $prim.Count -gt 0) {
                # Pass the item's full existing link set plus the new files, so nothing is dropped
                $assocArgs = @{
                    ItemNumber   = $w.itemNumber
                    PrimaryId    = $prim[0].FileId
                    PrimaryIsSub = ($prim[0].Type -eq 'PrimarySub')
                    SecondaryIds = [long[]]@(@($links | Where-Object Type -eq 'Secondary' | ForEach-Object FileId) +
                                             @($missSec | ForEach-Object { Get-LatestFileId $_ }))
                    StdCompIds   = [long[]]@($links | Where-Object Type -eq 'StandardComponent' | ForEach-Object FileId)
                    SecSubIds    = [long[]]@($links | Where-Object Type -eq 'SecondarySub' | ForEach-Object FileId)
                    TertiaryIds  = [long[]]@(@($links | Where-Object Type -eq 'Tertiary' | ForEach-Object FileId) +
                                             @($missTer | ForEach-Object { Get-LatestFileId $_ }))
                }

                # Not yet confirmed which form Vault accepts: try on the committed item, then after EditItems
                foreach ($useEdit in @($false, $true)) {
                    try   { Set-ItemFileAssociations @assocArgs -UseEdit:$useEdit }
                    catch { $assocErr = Get-VaultErrorText $_ }

                    $item  = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber)
                    $links = @(Get-ItemLinks -ItemId $item.Id)
                    if (@(Get-MissingEntries -Entries $plan.Secondary -Links $links -Types 'Secondary').Count -eq 0 -and
                        @(Get-MissingEntries -Entries $plan.Tertiary  -Links $links -Types 'Tertiary').Count  -eq 0) {
                        $assocErr = $null
                        break
                    }
                }
            }
        }

        # --- 3) Attachments: EditItems + UpdateAttachments, keeping existing attachments
        if ($plan.Attachments.Count -gt 0) {
            $item = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber)
            $cur  = Get-ItemAttachmentInfo -ItemId $item.Id

            if (-not $cur.Readable -and -not $w.itemCreated) {
                $notes.Add('Attachments NOT ADDED: existing attachments could not be read, so they were left unchanged')
                $problem = $true
            }
            else {
                $haveAtt = @($cur.Items | Where-Object { $_ } | ForEach-Object { Get-FileMasterId $_.FileId })
                $missAtt = @($plan.Attachments | Where-Object { $_ -and ($haveAtt -notcontains $_.File.MasterId) })

                if ($missAtt.Count -gt 0) {
                    $attmts = @(
                        foreach ($a in $cur.Items) { if ($a) { $a } }     # keep existing attachments
                        foreach ($e in $missAtt) {
                            $n = New-Object Autodesk.Connectivity.WebServices.Attmt
                            $n.FileId = Get-LatestFileId $e
                            $n.Pin    = $PinAttachments
                            $n
                        }
                    )
                    $edit = ($vault.ItemService.EditItems(@($item.RevId)))[0]
                    try {
                        $r = $vault.ItemService.UpdateAttachments(
                                $edit.RevId, [Autodesk.Connectivity.WebServices.Attmt[]]$attmts)
                        $vault.ItemService.UpdateAndCommitItems(@($r)) | Out-Null
                    }
                    catch {
                        try { $vault.ItemService.UndoEditItems(@($edit.RevId)) | Out-Null } catch { }
                        throw
                    }
                }
            }
        }

        # --- 4) Read back what Vault actually holds and log it
        $item   = $vault.ItemService.GetLatestItemByItemNumber($w.itemNumber)
        $w.item = $item
        $links  = @(Get-ItemLinks -ItemId $item.Id)

        $checks = @(
            @{ Label = 'Primary';   Entries = @($plan.Primary);   Types = @('Primary', 'PrimarySub') }
            @{ Label = 'Secondary'; Entries = @($plan.Secondary); Types = @('Secondary') }
            @{ Label = 'Tertiary';  Entries = @($plan.Tertiary);  Types = @('Tertiary') }
        )
        foreach ($c in $checks) {
            $entries = @($c.Entries | Where-Object { $_ })
            if ($entries.Count -eq 0) { continue }
            if ($c.Label -eq 'Primary' -and $primaryConflict) { continue }    # already logged

            $miss    = @(Get-MissingEntries -Entries $entries -Links $links -Types $c.Types)
            $missIds = @($miss | ForEach-Object { $_.File.MasterId })
            $ok      = @($entries | Where-Object { $missIds -notcontains $_.File.MasterId })
            if ($ok.Count   -gt 0) { $notes.Add("$($c.Label): $(Format-LinkNames $ok)") }
            if ($miss.Count -gt 0) {
                $why = if ($c.Label -ne 'Primary' -and $assocErr) { " ($assocErr)" } else { '' }
                $notes.Add("$($c.Label) NOT LINKED: $(Format-LinkNames $miss)$why")
                $problem = $true
            }
        }

        $attEntries = @($plan.Attachments | Where-Object { $_ })
        if ($attEntries.Count -gt 0) {
            $attNow = Get-ItemAttachmentInfo -ItemId $item.Id
            if ($attNow.Readable) {
                $attHave = @($attNow.Items | Where-Object { $_ } | ForEach-Object { Get-FileMasterId $_.FileId })
                $okA     = @($attEntries | Where-Object { $attHave -contains    $_.File.MasterId })
                $missA   = @($attEntries | Where-Object { $attHave -notcontains $_.File.MasterId })
                if ($okA.Count   -gt 0) { $notes.Add("Attached: $(Format-LinkNames $okA)") }
                if ($missA.Count -gt 0) { $notes.Add("NOT ATTACHED: $(Format-LinkNames $missA)"); $problem = $true }
            }
            elseif ($w.itemCreated) { $notes.Add("Attachments sent (could not read back): $(Format-LinkNames $attEntries)") }
        }

        $w.itemLinkComment = $notes -join ' | '
        $w.comment = if ($problem) {
                         if ($w.itemCreated) { 'Item created, some files not linked' } else { 'Existing item, some files not linked' }
                     }
                     elseif ($w.itemCreated) { 'Item created and files linked' }
                     else                    { 'Existing item - files linked' }

        if ($problem) { Write-Warning "[$($w.itemNumber)] $($w.itemLinkComment)" }
    }
    catch {
        $msg = "Link failed: $(Get-VaultErrorText $_)"
        $w.errorMessage = if ($w.errorMessage) { "$($w.errorMessage); $msg" } else { $msg }
        $notes.Add('Files not linked (error)')
        $w.itemLinkComment = $notes -join ' | '
        $w.comment         = 'Files not linked (error)'
        Write-Warning "[$($w.itemNumber)] $msg"
    }
}

#endregion

#region ------------------------------------------------------------ Promote, log, summary

if (-not $SkipPromote) {
    # New items, plus existing items that got their primary link in this run
    $numbers = @($workList | Where-Object { $_.itemCreated -or $_.linkedThisRun } |
                 Select-Object -ExpandProperty itemNumber)
    if ($numbers.Count -gt 0 -and $PSCmdlet.ShouldProcess("$($numbers.Count) items", 'Promote components')) {
        Write-Stage "Promoting $($numbers.Count) item(s)..."
        Invoke-ItemPromote -ItemNumbers $numbers
    }
}
else { Write-Stage 'Promote stage skipped ($SkipPromote = $true).' }

Write-Stage 'Writing log...'
foreach ($w in $workList) { Add-LogRow -Row $w -Path $LogFile }

$created  = @($workList | Where-Object itemCreated).Count
$failed   = @($workList | Where-Object errorMessage).Count
$linked   = @($workList | Where-Object { $_.comment -like '*files linked' }).Count
$linkProb = @($workList | Where-Object { $_.comment -like '*not linked*' }).Count
$revSet   = @($workList | Where-Object { $_.revisionComment -like 'Revision set*' }).Count
$existed  = @($workList | Where-Object { $_.itemComment -like 'Item already exists*' }).Count

Write-Host ''
Write-Host '======================= SUMMARY =======================' -ForegroundColor Green
Write-Host ("  Master list rows     : {0}" -f $itemList.Count)
Write-Host ("  Processed            : {0}" -f $workList.Count)
Write-Host ("  No file in Vault     : {0}" -f $noFile)
Write-Host ("  Skipped              : {0}" -f $skipped)
Write-Host ("  Items created        : {0}" -f $created)
Write-Host ("  Items already existed: {0}" -f $existed)
Write-Host ("  Revisions set        : {0}" -f $revSet)
Write-Host ("  Files renamed        : {0}" -f $renameCount)
Write-Host ("  Items fully linked   : {0}" -f $linked)
Write-Host ("  Items with link gaps : {0}" -f $linkProb) -ForegroundColor $(if ($linkProb) { 'Yellow' } else { 'Green' })
Write-Host ("  Rows with errors     : {0}" -f $failed) -ForegroundColor $(if ($failed) { 'Yellow' } else { 'Green' })
Write-Host ("  Log                  : {0}" -f $LogFile)
Write-Host '=======================================================' -ForegroundColor Green

#endregion
