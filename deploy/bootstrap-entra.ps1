# Requires: Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph

# ==== CONFIG (change per tenant as needed) ====
$AppName            = "MO-Onboarding-Automation"
$SecretDisplayName  = "MO-ClientSecret"
$SecretMonths       = 18
$GroupsToCreate     = @("HR-Managers","IT-Joiners-Leavers","All-New-Starters")

# ==== CONNECT ====
Connect-MgGraph -Scopes "Application.ReadWrite.All","AppRoleAssignment.ReadWrite.All","Directory.ReadWrite.All","Group.ReadWrite.All","User.ReadWrite.All"
Select-MgProfile -Name "beta"

# ==== APP REGISTRATION ====
$app = New-MgApplication -DisplayName $AppName `
  -RequiredResourceAccess @(
    @{
      resourceAppId = "00000003-0000-0000-c000-000000000000"; # Microsoft Graph
      resourceAccess = @(
        @{ id = "741f803b-c850-494e-b5df-cde7c675a1ca"; type = "Role" } # User.ReadWrite.All (App)
        @{ id = "62a82d76-70ea-41e2-9197-370581804d09"; type = "Role" } # Group.ReadWrite.All (App)
        @{ id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7"; type = "Role" } # Directory.ReadWrite.All (App)
      )
    }
  )

$sp = New-MgServicePrincipal -AppId $app.AppId
$secret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{
  displayName = $SecretDisplayName
  endDateTime = (Get-Date).AddMonths($SecretMonths)
}

# ==== ADMIN CONSENT NOTE ====
Write-Host "`nIMPORTANT: An Entra admin must grant admin consent to the Graph app permissions." -ForegroundColor Yellow
Write-Host "APP ID: $($app.AppId)" -ForegroundColor Yellow

# ==== GROUPS ====
$createdGroups = foreach($g in $GroupsToCreate){
  New-MgGroup -DisplayName $g -MailEnabled:$false -MailNickname (($g -replace "[^a-zA-Z0-9]","").ToLower()) -SecurityEnabled:$true
}

# ==== OUTPUT .env-like block for your Solution variables ====
$envOut = [PSCustomObject]@{
  TenantId             = (Get-MgContext).TenantId
  Graph_AppId          = $app.AppId
  Graph_ClientSecret   = $secret.SecretText
  HR_Group_ObjectId    = ($createdGroups | Where-Object DisplayName -eq "HR-Managers").Id
  IT_Group_ObjectId    = ($createdGroups | Where-Object DisplayName -eq "IT-Joiners-Leavers").Id
  Starters_Group_Id    = ($createdGroups | Where-Object DisplayName -eq "All-New-Starters").Id
}
$envOut | Format-List
# Save to file for the import step
$envOut | ConvertTo-Json | Out-File -Encoding UTF8 .\onboarding.env.json
Write-Host "`nSaved onboarding.env.json. Paste these into your Power Platform Solution environment variables." -ForegroundColor Green
