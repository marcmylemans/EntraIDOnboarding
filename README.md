# MO Onboarding/Offboarding — Solution Skeleton (Free, Standard Connectors)

This repo skeleton lets you deploy a reusable onboarding/offboarding setup to any Microsoft 365 tenant using **only Entra ID + SharePoint + Power Automate (standard connectors)**.

## Contents
- `deploy/bootstrap-entra.ps1` — Creates Graph app registration + security groups and outputs IDs for env vars.
- `deploy/provision-spo.ps1` — Creates SharePoint site and the **New Hires** intake list.
- `docs/EnvironmentVariables.md` — List of environment variables you configure in the Power Platform Solution.
- `docs/ImportGuide.md` — Step-by-step to bootstrap a new tenant and import your Managed Solution.
- `solution/` — Put your **Managed Solution zip** here once exported from Power Automate.

> This skeleton does **not** include a pre-built Managed Solution zip (you’ll export that from your tenant after you build the two flows using the env vars listed below).

---

## Quick start
1. **Bootstrap Entra**  
   ```powershell
   pwsh ./deploy/bootstrap-entra.ps1
   ```
   Copy values from the printed object (and `onboarding.env.json`). Make sure a Global Admin grants **admin consent** for the app permissions.

2. **Provision SharePoint**  
   ```powershell
   pwsh ./deploy/provision-spo.ps1
   ```

3. **Create environment variables** in Power Platform (names from `docs/EnvironmentVariables.md`).

4. **Build two flows** (Onboarding + Offboarding) using **standard connectors only**, referencing the env vars.

5. **Export your Solution as Managed** and place it under `solution/` for reuse at customers.

---

## Staying on the free tier
- Use **SharePoint**, **Azure AD**, **Outlook**, **Teams** connectors only.
- Do **group-based licensing** (attach licenses to groups once per tenant) and add the new user to that group in the flow.
- Avoid premium HTTP/Graph steps in Power Automate; the bootstrap PowerShell handles Graph where needed.

