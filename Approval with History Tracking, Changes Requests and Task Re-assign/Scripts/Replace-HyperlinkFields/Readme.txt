Follow the steps below to replace existing "Hyperlink" fields for Approval Tasks and Approval History lists with "Multiple lines of text" (aka. "Note"):

1. Open Config.json file and specify your site URL. Only modify values in the "Lists" array if you have changed default list names.

2. Run Export-SPOListData.ps1. The script will read the data in Config.json and generate two .json files in the Output folder, containing data stored in Hyperlink columns in the specified lists. 

The file names will be formatted as follows: listData-<List_Name>-<Encoded site URL>.json.

3. Run Replace-SPOField.ps1. The script will also read Config.json and will then do the following for each list:
+ Replace Hyperlink field with identically named Note field. At this point the new field will be empty.
+ Retrieve data from corresponding .json file and populate each cell of the column with the same value it had before being replaced.
