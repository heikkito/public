Connect to a Azure netshare persistently using this Scheduled task that triggers 'on logon'. Now you can use a Azure netshare the same way you would use a local Fileserver. 

It is said Azure shares cannot be set to work like Network shares. This is true -> No GPO policy, logon batch file or PS script can make the 
connection persistent with user contextual login but this system works like a charm as it triggers when user logs on with their ordinary users
logins. Do not use user grants elevation as the script needs to trigger using the logged on users grants and compare them to grants given to the user in Azure. 

Note: .ps1 login script itself is the one Microsoft provides in the their netshare connection blade in Azure. No changes here. 
Note2: modify the scripts. There are some AD related sections with 'yourxxxxxx'. Fill in your URLS & AD accounts here before importing the scheduled task.

