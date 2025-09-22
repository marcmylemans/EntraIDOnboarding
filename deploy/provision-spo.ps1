# provision-spo-pnp.ps1
# Requires: Install-Module PnP.PowerShell -Scope CurrentUser

param(
  [string]$AdminUrl = "https://contoso-admin.sharepoint.com",
  [string]$SiteUrl  = "https://contoso.sharepoint.com/sites/HR-Onboarding",
  [string]$OwnerUpn = "itadmin@contoso.com"
)

Import-Module PnP.PowerShell

# ---- Ensure site exists ----
Connect-PnPOnline -Url $AdminUrl -Interactive
try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
} catch {
    New-PnPTenantSite -Url $SiteUrl -Title "HR Onboarding" -Owner $OwnerUpn -TimeZone 4 -Template "STS#3" | Out-Null
    Connect-PnPOnline -Url $SiteUrl -Interactive
}

# ---- Ensure list ----
$listTitle = "New Hires"
if (-not (Get-PnPList -Identity $listTitle -ErrorAction SilentlyContinue)) {
    New-PnPList -Title $listTitle -Template GenericList -OnQuickLaunch -EnableContentTypes:$false | Out-Null
}

# helper: add field if missing
function Ensure-PnPField {
    param([string]$InternalName,[string]$DisplayName,[string]$Type,[hashtable]$Extra = @{},[switch]$AddToDefaultView)
    if (-not (Get-PnPField -List $listTitle -Identity $InternalName -ErrorAction SilentlyContinue)) {
        Add-PnPField -List $listTitle -InternalName $InternalName -DisplayName $DisplayName -Type $Type @Extra | Out-Null
    }
    if ($AddToDefaultView) { Add-PnPView -List $listTitle -Identity "All Items" -Fields $InternalName -UpdateViewFields | Out-Null }
}

# ---- HR intake columns ----
Ensure-PnPField -InternalName "FirstName" -DisplayName "First Name" -Type Text -AddToDefaultView
Ensure-PnPField -InternalName "LastName"  -DisplayName "Last Name"  -Type Text -AddToDefaultView
Ensure-PnPField -InternalName "JobTitle"  -DisplayName "Job Title"  -Type Text
Ensure-PnPField -InternalName "Department"-DisplayName "Department" -Type Text
Ensure-PnPField -InternalName "Manager"   -DisplayName "Manager"    -Type User -Extra @{ SelectionMode="PeopleOnly"; AllowMultipleValues=$false } -AddToDefaultView
Ensure-PnPField -InternalName "StartDate" -DisplayName "Start Date" -Type DateTime -Extra @{ DisplayFormat="DateOnly" } -AddToDefaultView
# Choice field
if (-not (Get-PnPField -List $listTitle -Identity "RequestType" -ErrorAction SilentlyContinue)) {
    Add-PnPField -List $listTitle -InternalName "RequestType" -DisplayName "Request Type" -Type Choice -AddToDefaultView `
        -Choices @("Onboard","Offboard") | Out-Null
}
Ensure-PnPField -InternalName "Notes" -DisplayName "Notes" -Type Note

# ---- Flow status/outputs (useful for write-back) ----
Ensure-PnPField -InternalName "UPN"             -DisplayName "UPN"              -Type Text -AddToDefaultView
Ensure-PnPField -InternalName "ProvisionStatus" -DisplayName "Provision Status" -Type Text -AddToDefaultView
Ensure-PnPField -InternalName "ProvisionedUPN"  -DisplayName "Provisioned UPN"  -Type Text
Ensure-PnPField -InternalName "AadObjectId"     -DisplayName "AAD ObjectId"     -Type Text
Ensure-PnPField -InternalName "ProvisionedAt"   -DisplayName "Provisioned At"   -Type DateTime -Extra @{ DisplayFormat="DateTime" }
Ensure-PnPField -InternalName "OffboardStatus"  -DisplayName "Offboard Status"  -Type Text
Ensure-PnPField -InternalName "DisabledAt"      -DisplayName "Disabled At"      -Type DateTime -Extra @{ DisplayFormat="DateTime" }

Write-Host "✔ SharePoint ready at $SiteUrl — list '$listTitle' provisioned."
