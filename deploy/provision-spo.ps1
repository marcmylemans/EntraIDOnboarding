# provision-spo.ps1  — SharePoint Online Mgmt Shell (SPO) version
# Requires: Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
Import-Module Microsoft.Online.SharePoint.PowerShell

# ==== CONFIG ====
$AdminUrl     = "https://contoso-admin.sharepoint.com"
$SiteUrl      = "https://contoso.sharepoint.com/sites/HR-Onboarding"
$SiteOwnerUpn = "itadmin@contoso.com"

Connect-SPOService -Url $AdminUrl

# Create site (modern team site without M365 group) if missing
try {
    Get-SPOSite -Identity $SiteUrl -ErrorAction Stop | Out-Null
    Write-Host "Site exists: $SiteUrl"
} catch {
    New-SPOSite -Url $SiteUrl -Owner $SiteOwnerUpn -StorageQuota 1024 -Title "HR Onboarding" -Template "STS#3"
    Write-Host "Created site: $SiteUrl"
}

# ---- Site Script JSON (single-quoted here-string so $schema isn't expanded) ----
$siteScript = @'
{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/site-design-script-actions.schema.json",
  "actions": [
    {
      "verb": "createSPList",
      "listName": "New Hires",
      "templateType": 100,
      "subactions": [
        { "verb": "setDescription", "description": "HR intake for onboarding/offboarding" },
        { "verb": "addSPField", "fieldType": "Text", "displayName": "First Name", "isRequired": true, "internalName": "FirstName" },
        { "verb": "addSPField", "fieldType": "Text", "displayName": "Last Name",  "isRequired": true, "internalName": "LastName"  },
        { "verb": "addSPField", "fieldType": "Text", "displayName": "Job Title",  "isRequired": false, "internalName": "JobTitle"  },
        { "verb": "addSPField", "fieldType": "Text", "displayName": "Department","isRequired": false, "internalName": "Department"},
        { "verb": "addSPField", "fieldType": "User", "displayName": "Manager",   "isRequired": false, "internalName": "Manager"   },
        { "verb": "addSPField", "fieldType": "DateTime", "displayName": "Start Date","isRequired": true,"internalName": "StartDate" },
        { "verb": "addSPField", "fieldType": "Choice", "displayName": "Request Type","isRequired": true,"internalName": "RequestType",
          "addToDefaultView": true,
          "choices": ["Onboard","Offboard"]
        },
        { "verb": "addSPField", "fieldType": "Note", "displayName": "Notes", "isRequired": false, "internalName": "Notes" }
      ]
    }
  ],
  "version": 1
}
'@

# Register script and apply design
$scriptObj = Add-SPOSiteScript -Title "HR Intake Script" -Content $siteScript
$design    = Add-SPOSiteDesign -Title "Apply HR Intake" -WebTemplate "64" -SiteScripts $scriptObj.Id
Invoke-SPOSiteDesign -Identity $design.Id -WebUrl $SiteUrl
Write-Host "Provisioned 'New Hires' list on $SiteUrl"
