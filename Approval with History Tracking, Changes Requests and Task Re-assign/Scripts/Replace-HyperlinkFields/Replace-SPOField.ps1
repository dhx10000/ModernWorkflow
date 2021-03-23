# ******************* Config Variables - DO NOT CHANGE (unless required) *********************

$configFile = "Config.json"
$listDataFilePathTemplate = "Output/listData-<ListName>-<encodedURL>.json"

# ******************************* End Config Variables ***************************************

$filePath = $listDataFilePathTemplate.Replace("<ListName>", $listName).Replace(" ", "_")

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

    $msg = "Obtained information: " + $configData
    Write-Output $msg   

    # Connect to target site
    Connect-PnPOnline -Url $configData.SiteUrl -UseWebLogin

    foreach ($list in $configData.Lists)
    {
        try
        {
            $encodedURL = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($configData.SiteUrl))        
            $filePath = $listDataFilePathTemplate.Replace("<ListName>", $list.ListName).Replace(" ", "_").Replace("<encodedURL>", $encodedURL)
           
            $msg = "Deleting field '" + $list.FieldName + "' from list '" + $list.ListName + "'..."
            Write-Output $msg   

            #delete column
            Remove-PnPField -List $list.ListName -Identity $list.FieldName -Force

            $msg = "Creating field of type 'Multi-line text' called '" + $list.FieldName + "' within list '" + $list.ListName + "'"
            Write-Output $msg   

            #recreate column with same name and a different type
            Add-PnPField -List $list.ListName -InternalName $list.FieldName -DisplayName $list.FieldName -Type Note -AddToDefaultView | Out-Null

            $msg = "Retrieving field data from file: " + $filePath
            Write-Output $msg   

            $importData = Get-Content $filePath | Out-String | ConvertFrom-Json

            $msg = "Populating list data..."
            Write-Output $msg

            $itemCount = $importData.Count
            $counter = 0
            $listName = $list.ListName

            #re-populate data
            foreach ($row in $importData) 
            {               
                try
                {
                    $counter++

                    # Compensating in the interest of time to avoid "cosmetic" error messages related to minor progress bar math inconsistencies                    
                    if ($counter -gt $itemCount)
                    {
                        $percentComplete = 100
                    }
                    else
                    {
                        $percentComplete = ($counter/$itemCount) * 100
                    }

                    Write-Progress -Activity "Populating $listName list. Item $counter of $itemCount..." -PercentComplete $percentComplete

                    $value = ($row.($list.FieldName)).ToString()
                    $item = Set-PnPListItem -List $list.ListName -Identity $row.Id -Values @{$list.FieldName = $value}
                }
                catch
                {
                    $msg = "ERROR while processing list item id " + $row.Id + " in list " + $list.ListName + ": " + $_.Exception.Message
                    Write-Output $msg
                }                      
            }

            $msg = "Succesfully updated list: " + $list.ListName
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


