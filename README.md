# Microsoft Store App Update Troubleshooter

Created by **Dewald Pretorius**.

This repository now contains two PowerShell 5.1 tools:

- `Troubleshooter.ps1` for the original Store update diagnostics.
- `Repair.ps1` for read-only diagnosis, Microsoft Store cache reset, required-service readiness, and DNS cache repair.

```powershell
.\Repair.ps1 -Action Diagnose
.\Repair.ps1 -Action ResetStoreCache -WhatIf
.\Repair.ps1 -Action StartRequiredServices -Confirm
```

Repair actions use PowerShell confirmation, save pre-change evidence, write a timestamped log, and verify the resulting state. Administrative rights may be required for service actions. The workflow is source-reviewed and has not been runtime-tested on every Windows build.
