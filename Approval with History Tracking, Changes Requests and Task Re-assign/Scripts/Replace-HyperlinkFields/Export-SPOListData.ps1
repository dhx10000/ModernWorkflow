# ******************* Config Variables - DO NOT CHANGE (unless required) ***************************

$configFile = "Config.json"
$listDataFilePathTemplate = "Output/listData-<ListName>-<encodedURL>.json"

# ******************************* End Config Variables ***************************************

# Run script from its current location
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$dir = $dir.ToString() + "\"
Set-Location $dir

try
{
    $msg = "Obtaining config data..."
    Write-Output $msg

    # Get config data
    $configData = Get-Content $configFile | Out-String | ConvertFrom-Json

    $msg = "Retrieveing information: " + $configData
    Write-Output $msg    

    Connect-PnPOnline -Url $configData.SiteUrl -UseWebLogin

    foreach ($list in $configData.Lists)
    {        
        $encodedURL = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($configData.SiteUrl))        
        $filePath = $listDataFilePathTemplate.Replace("<ListName>", $list.ListName).Replace(" ", "_").Replace("<encodedURL>", $encodedURL)

        $data = @()

        try
        {
            # export column data
            $items = Get-PnPListItem -List $list.ListName -Fields "Id", $list.FieldName -PageSize 2000

            $value = ""

            foreach ($i in $items)
            {
                if($i[$list.FieldName].GetType().Name -eq "FieldUrlValue")
                {
                    $value = $i[$list.FieldName].Url
                }
                else
                {
                    $value = $i[$list.FieldName]
                }

                $itemObj = New-Object -TypeName psobject
    
                # add more properties here as needed
                $itemObj | Add-Member -MemberType NoteProperty -Name Id -Value $i.Id
                $itemObj | Add-Member -MemberType NoteProperty -Name $list.FieldName -Value $value

                $data += $itemObj
            }

            ConvertTo-Json -InputObject $data | Out-File $filePath -Force

            $msg = "Data from field '" + $list.FieldName + "' of list '" + $list.ListName + "' has been successfully exported to file: " + $filePath
            Write-Output $msg
        }
        catch
        {
            $msg = "ERROR while processing list '" + $list.ListName + "': " + $_.Exception.Message
            Write-Output $msg
        }

        Write-Output ""
    }    

    Disconnect-PnPOnline 
}
catch
{
    $msg = "ERROR: " + $_.Exception.Message
    Write-Output $msg
}

