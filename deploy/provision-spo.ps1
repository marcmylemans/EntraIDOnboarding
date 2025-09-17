# Requires: Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
Import-Module Microsoft.Online.SharePoint.PowerShell

# ==== CONFIG ====
$AdminUrl     = "https://contoso-admin.sharepoint.com"
$SiteUrl      = "https://contoso.sharepoint.com/sites/HR-Onboarding"
$SiteOwnerUpn = "itadmin@contoso.com"

Connect-SPOService -Url $AdminUrl

# Create site if missing
Try {
  Get-SPOSite -Identity $SiteUrl -ErrorAction Stop | Out-Null
  Write-Host "Site exists: $SiteUrl"
} Catch {
  New-SPOSite -Url $SiteUrl -Owner $SiteOwnerUpn -StorageQuota 1024 -Title "HR Onboarding" -Template "STS#3"
  Write-Host "Created site: $SiteUrl"
}

# Create list via Site Script (columns for HR intake)
$siteScript = @"
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
        { "verb": "addSPField", "fieldType": "Text", "displayName": "Job Title",  "isRequired": true, "internalName": "JobTitle"  },
        { "verb": "addSPField", "fieldType": "Text", "displayName": "Department","isRequired": true, "internalName": "Department"},
        { "verb": "addSPField", "fieldType": "User", "displayName": "Manager",   "isRequired": false,"internalName": "Manager"   },
        { "verb": "addSPField", "fieldType": "DateTime", "displayName": "Start Date","isRequired": true,"internalName": "StartDate" },
        { "verb": "addSPField", "fieldType": "Choice", "displayName": "Request Type","isRequired": true,"internalName": "RequestType",
          "addToDefaultView": true,
          "choices": ["Onboard","Offboard"]
        }
      ]
    }
  ],
  "version": 1
}
"@

# Register & apply the script
$scriptObj = Add-SPOSiteScript -Title "HR Intake Script" -Content $siteScript
Add-SPOSiteDesign -Title "Apply HR Intake" -WebTemplate "64" -SiteScripts $scriptObj.Id | Out-Null
Invoke-SPOSiteDesign -Identity (Get-SPOSiteDesign | Where-Object Title -eq "Apply HR Intake").Id -WebUrl $SiteUrl
Write-Host "Provisioned 'New Hires' list on $SiteUrl"
