$siteUrl = "https://m365x867142.sharepoint.com/sites/ApprovalsTest1"
$libName = "Documents"
$ppServiceAccount = "ppservice@m365x867142.onmicrosoft.com"

$templateFileName = "ApprovalLists.pnp"

#****************************  END CONFIG ****************************

# Run script for its current location
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$dir = $dir.ToString() + "\"
Set-Location $dir
  
$msg = "Connecting to the destination site: " + $siteUrl
Write-Output $msg
Write-Output ""

# Connect to target site
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Grant ppservice account site owner permissions
$web = Get-PnPWeb -Includes WebTemplate, Configuration

$msg = "Registering Power Platform service account (" + $ppServiceAccount + ") as Site Owner."
write-output $msg

Add-PnPUserToGroup -Identity $web.AssociatedOwnerGroup -EmailAddress $ppServiceAccount


$ctx = Get-PnPContext

$lib = Get-PnPList -Identity $libName
$fields = $lib.Fields
$ctx.Load($fields)
$ctx.ExecuteQuery()

$msg = "Setting up document library: " + $libName + "..."    
Write-Output $msg

#adding fields to the library if they do not exist already
if (($fields | ? {$_.InternalName -eq "ApprovalOutcome"}).Count -eq 0)
{
    $msg = "  Adding field to '" + $libName + "' library: Approval Outcome"    
    Write-Output $msg

    Add-PnPField -List $libName -Type Text -DisplayName "Approval Outcome" -InternalName "ApprovalOutcome" -AddToDefaultView | Out-Null
}
else
{
    $msg = "  Field 'Approval Outcome' already exists in library '" + $libName + "'"    
    Write-Output $msg
}

if (($fields | ? {$_.InternalName -eq "ApprovalSummary"}).Count -eq 0)
{
    $msg = "  Adding field to '" + $libName + "' library: Approval Summary"    
    Write-Output $msg

    Add-PnPField -List $libName -Type Note -DisplayName "Approval Summary" -InternalName "ApprovalSummary" -AddToDefaultView | Out-Null
}
else
{
    $msg = "  Field 'Approval Summary' already exists in library '" + $libName + "'"    
    Write-Output $msg
}

if (($fields | ? {$_.InternalName -eq "PreviousApproval"}).Count -eq 0)
{
    $msg = "  Adding field to '" + $libName + "' library: Previous Approval"    
    Write-Output $msg

    Add-PnPField -List $libName -Type Note -DisplayName "Previous Approval" -InternalName "PreviousApproval" | Out-Null
}
else
{
    $msg = "  Field 'Previous Approval' already exists in library '" + $libName + "'"    
    Write-Output $msg
}

$msg = "Importing template... "
Write-Output $msg

# Apply provisioning template
Apply-PnPProvisioningTemplate -Path $templateFileName -Handlers Lists

$msg = "  Done."
Write-Output $msg
Write-Output ""

$approvalTasksGuid = (Get-PnPList -Identity "Approval Tasks").Id.ToString()
$approvalhistoryGuid = (Get-PnPList -Identity "Approval History").Id.ToString()

$msg = "
Lists created: 
    Title: Approval Tasks
    Guid: " + $approvalTasksGuid + "

    Title: Approval History
    Guid: " + $approvalHistoryGuid

Write-Output $msg          

Disconnect-PnPOnline