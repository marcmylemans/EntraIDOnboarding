# Environment Variables

Create these as **Environment Variables** in your Power Platform Solution (type: Text).

| Name | Example | Purpose |
|---|---|---|
| `EV_SPO_SiteUrl` | `https://contoso.sharepoint.com/sites/HR-Onboarding` | SharePoint site used by HR intake |
| `EV_SPO_ListName_NewHires` | `New Hires` | Intake list name |
| `EV_Tenant_Domain` | `contoso.com` | UPN domain for new accounts |
| `EV_Email_From` | *(optional)* | Sender address for notifications |
| `EV_Group_HR_ObjectId` | GUID | HR Managers security group |
| `EV_Group_IT_ObjectId` | GUID | IT Joiners/Leavers group |
| `EV_Group_License_Base_ObjectId` | GUID | Group with base license assignment |
| `EV_Group_Dept_Default_ObjectId` | GUID | Default department/new starters group |
| `EV_UPN_Format` | `{first}.{last}@{tenant}` | UPN pattern |
| `EV_Sam_Format` | `{first}{last:1}` | Alias pattern (if needed) |

> Store the actual values from `onboarding.env.json` output by the bootstrap script.
