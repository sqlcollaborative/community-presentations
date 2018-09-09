break

# Get yo servers
$instance1 = Get-DbaRegisteredServer -SqlInstance localhost\sql2016 -Group Site1
$instance2 = Get-DbaRegisteredServer -SqlInstance localhost\sql2016 -Group Site2

# But for the demo
$instance = "workstation\sql2016"

# See commands
Get-Command -Name *export* -Module dbatools -Type Function
Get-Command -Name *backup* -Module dbatools -Type Function
Get-Command -Name *dbadac* -Module dbatools -Type Function


# First up! Export-DbaScript

# Start with something simple
Get-DbaAgentJob -SqlInstance $instance | Select -First 1 | Export-DbaScript

# Now let's look inside
Get-DbaAgentJob -SqlInstance $instance | Select -First 1 | Export-DbaScript | Invoke-Item

# Raw output and add a batch separator
Get-DbaAgentJob -SqlInstance $instance | Export-DbaScript -Passthru -BatchSeparator GO

# Get crazy
#Set Scripting Options
$options = New-DbaScriptingOption
$options.ScriptSchema = $true
$options.IncludeDatabaseContext  = $true
$options.IncludeHeaders = $false
$Options.NoCommandTerminator = $false
$Options.ScriptBatchTerminator = $true
$Options.AnsiFile = $true

"sqladmin" | clip
Get-DbaDbMailProfile -SqlInstance $instance -SqlCredential sqladmin | 
Export-DbaScript -Path C:\temp\export.sql -ScriptingOptionsObject $options -NoPrefix |
Invoke-Item

# So special
Export-DbaSpConfigure -SqlInstance $instance -Path C:\temp\sp_configure.sql
Export-DbaLinkedServer -SqlInstance $instance -Path C:\temp\linkedserver.sql | Invoke-Item
Export-DbaLogin -SqlInstance $instance -Path C:\temp\logins.sql | Invoke-Item

# Other specials
Backup-DbaDbMasterKey -SqlInstance sql2017 -Credential sup

# What if you just want to script out your restore?
Get-ChildItem -Directory \\workstation\backups\subset\ | Restore-DbaDatabase -SqlInstance localhost\sql2017 -OutputScriptOnly -WithReplace | Out-File -Filepath c:\temp\restore.sql
Invoke-Item c:\temp\restore.sql

# Big ol reveal

# Do it all at once
Export-DbaInstance -SqlInstance $instance -Path \\workstation\backups\DR
Invoke-Item \\workstation\backups\DR

# It ain't a DR plan without testing
Test-DbaLastBackup -SqlInstance $instance

# 1. associate sql with sql
# 2. Delete endpoints on sql2017, audit
# Apply stuff
# delete extra trigger
# turn on presentation mode
Get-ChildItem -Path \\workstation\backups\DR | Invoke-Item

# Use Ola Hallengren's backup script? We can restore an *ENTIRE INSTANCE* with just one line
Get-ChildItem -Directory \\workstation\backups\sql2012 | Restore-DbaDatabase -SqlInstance localhost\sql2017 -WithReplace