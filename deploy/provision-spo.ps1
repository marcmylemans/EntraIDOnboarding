# provision-spo-pnp.ps1
# Requires: Install-Module PnP.PowerShell -Scope CurrentUser

param(
  [Parameter(Mandatory=$true)][string]$AdminUrl,
  [Parameter(Mandatory=$true)][string]$SiteUrl,
  [Parameter(Mandatory=$true)][string]$OwnerUpn
)

Import-Module PnP.PowerShell

# ---- Ensure site ----
Connect-PnPOnline -Url $AdminUrl -Interactive
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
} catch {
    Write-Host "Creating site $SiteUrl ..."
    New-PnPTenantSite -Url $SiteUrl -Title "HR Onboarding" -Owner $OwnerUpn -TimeZone 4 -Template "STS#3" | Out-Null
    Connect-PnPOnline -Url $SiteUrl -Interactive
}

# ---- Ensure list ----
$listTitle = "New Hires"
if (-not (Get-PnPList -Identity $listTitle -ErrorAction SilentlyContinue)) {
    New-PnPList -Title $listTitle -Template GenericList -OnQuickLaunch -EnableContentTypes:$false | Out-Null
}

function Ensure-PnPField {
    param(
      [string]$InternalName,[string]$DisplayName,[string]$Type,
      [hashtable]$Extra = @{},[switch]$AddToDefaultView
    )
    if (-not (Get-PnPField -List $listTitle -Identity $InternalName -ErrorAction SilentlyContinue)) {
        Add-PnPField -List $listTitle -InternalName $InternalName -DisplayName $DisplayName -Type $Type @Extra | Out-Null
    }
    if ($AddToDefaultView) {
        Add-PnPView -List $listTitle -Identity "All Items" -Fields $InternalName -UpdateViewFields | Out-Null
    }
}

# ---- HR intake columns ----
Ensure-PnPField -InternalName "FirstName"     -DisplayName "First Name"     -Type Text     -AddToDefaultView
Ensure-PnPField -InternalName "LastName"      -DisplayName "Last Name"      -Type Text     -AddToDefaultView
Ensure-PnPField -InternalName "JobTitle"      -DisplayName "Job Title"      -Type Text
Ensure-PnPField -InternalName "Department"    -DisplayName "Department"     -Type Text
Ensure-PnPField -InternalName "Manager"       -DisplayName "Manager"        -Type User     -Extra @{ SelectionMode="PeopleOnly"; AllowMultipleValues=$false } -AddToDefaultView
Ensure-PnPField -InternalName "StartDate"     -DisplayName "Start Date"     -Type DateTime -Extra @{ DisplayFormat="DateOnly" } -AddToDefaultView

# Choice: Request Type
if (-not (Get-PnPField -List $listTitle -Identity "RequestType" -ErrorAction SilentlyContinue)) {
    Add-PnPField -List $listTitle -InternalName "RequestType" -DisplayName "Request Type" -Type Choice `
        -Choices @("Onboard","Offboard") -AddToDefaultView | Out-Null
}
Ensure-PnPField -InternalName "Notes"         -DisplayName "Notes"          -Type Note

# Flow write-back columns
Ensure-PnPField -InternalName "UPN"             -DisplayName "UPN"              -Type Text -AddToDefaultView
Ensure-PnPField -InternalName "ProvisionStatus" -DisplayName "Provision Status" -Type Text -AddToDefaultView
Ensure-PnPField -InternalName "ProvisionedUPN"  -DisplayName "Provisioned UPN"  -Type Text
Ensure-PnPField -InternalName "AadObjectId"     -DisplayName "AAD ObjectId"     -Type Text
Ensure-PnPField -InternalName "ProvisionedAt"   -DisplayName "Provisioned At"   -Type DateTime -Extra @{ DisplayFormat="DateTime" }
Ensure-PnPField -InternalName "OffboardStatus"  -DisplayName "Offboard Status"  -Type Text
Ensure-PnPField -InternalName "DisabledAt"      -DisplayName "Disabled At"      -Type DateTime -Extra @{ DisplayFormat="DateTime" }

Write-Host "✔ SharePoint ready at $SiteUrl — list '$listTitle' provisioned."
