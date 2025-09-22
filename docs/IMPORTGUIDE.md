
# Import Guide (Tenant Bootstrap → Solution Import)

## 1) Run Entra bootstrap
- Open PowerShell and run:
  ```powershell
  pwsh ./deploy/bootstrap-entra.ps1
  ```
- Have a Global Admin **grant admin consent** to the app's Graph application permissions.
- Copy the printed values (also saved to `onboarding.env.json`).

## 2) Provision SharePoint
```powershell
pwsh ./deploy/provision-spo.ps1
```
- This creates the site and a **New Hires** list with required columns.

## 3) Create Environment Variables
In Power Platform (make.powerapps.com → Solutions → your solution → **Environment variables**), create the variables listed in `docs/EnvironmentVariables.md` and paste the tenant-specific values.

## 4) Build the flows
- **Onboarding flow**: Trigger = SharePoint *When an item is created* on `EV_SPO_SiteUrl` / `EV_SPO_ListName_NewHires`. Actions: Create user, add to groups, set manager, notify, update item. Use only standard connectors.
- **Offboarding flow**: Trigger on same list with `RequestType = Offboard`. Actions: disable account, remove from groups, notify, update item.

## 5) Export as Managed
- Export the finished Solution as **Managed** and keep the zip under `solution/` when sharing to other tenants.
