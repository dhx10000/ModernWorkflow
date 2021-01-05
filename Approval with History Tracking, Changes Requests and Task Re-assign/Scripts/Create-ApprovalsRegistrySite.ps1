# *************************  CONFIG VALUES ***************************

# SPO Admin site URL
$adminUrl = "https://m365x867142-admin.sharepoint.com"

# Approval Registry site URL (to be created). Recommended to only adjust the tenant URL and leave "/sites/ApprovalRegistry" intact
$siteUrl = "https://m365x867142.sharepoint.com/sites/ApprovalsRegistry"

# user running the script
$currentUser = "dmitryvo@m365x867142.onmicrosoft.com"

# Power Platform Service account
$ppServiceAccount = "ppservice@m365x867142.onmicrosoft.com"

# ********* DO NOT CHANGE (Unless necessary) *********

$templateFileName = "ApprovalsRegistrySite.pnp"
$siteName = "Approvals Registry"
$description = "A service site to manage custom Power Platform-based Approvals"

# ******* END DO NOT CHANGE *******

#****************************  END CONFIG ****************************

#Run script for its current location
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$dir = $dir.ToString() + "\"
Set-Location $dir

# Connect to SharePoint Online
# This command will prompt the sign-in UI to authenticate
Connect-PnPOnline $adminUrl -UseWebLogin

$msg = "Creating new Communication site: " + $siteName + " <" + $siteUrl + ">"
write-output $msg

try
{
    # Create the new communication site
    New-PnPSite -Type CommunicationSite -Title $siteName -Url $siteUrl -Description $description -Owner $currentUser -ErrorAction Stop
}
catch
{
    $msg = "Looks like Approval Registry site already exists. Proceeding..."
    Write-Output $msg
}

$msg = "Connecting to site: " + $siteUrl
write-output $msg

Connect-PnPOnline $siteUrl -UseWebLogin

$ctx = Get-PnPContext

$web = Get-PnPWeb -Includes WebTemplate, Configuration

$msg = "Registering Power Platform service account (" + $ppServiceAccount + ") as Site Owner."
write-output $msg

Add-PnPUserToGroup -Identity $web.AssociatedOwnerGroup -EmailAddress $ppServiceAccount

$msg = "Granting Read access to Everyone except external users..."
write-output $msg

#Resolve User Name by Display Name
$Principal = [Microsoft.SharePoint.Client.Utilities.Utility]::ResolvePrincipal($ctx, $web, "Everyone except external users", "All", "All", $Null, $True)
$ctx.ExecuteQuery()
$everyoneLoginName = $Principal.Value.LoginName

Add-PnPUserToGroup -LoginName $everyoneLoginName -Identity $web.AssociatedVisitorGroup

$msg = "Creating lists: Approvals Registry, Approval Instances..."
write-output $msg

# Creating Approvals Registry list...
Apply-PnPProvisioningTemplate -Path $templateFileName

Disconnect-PnPOnline

$msg = "All done!"
write-output $msg