# public
My public script code repository. Finished or otherwise working code along with user menus / docs are placed here. 

I work with Powershell, Python and some command line/.bat files along with Terraform, ARM-templates and helm-charts. No public repositories except this small public repository. 

I only publish fully working code here that compiles but may require to install modules to work. Check readme.txt for each script. 

**CONTENTS**

**Azure Netshare Connect Persistently**: Connect to a Azure netshare persistently and use it like a local fileserver share. Basically a script + scheduled task XML that can be imported to a workstation that triggers 'on logon' once. 

**Ping search for software and delete it**: Pings for machines that are online, searches them for software and deletes the software on machines that are online+have the software package. Simple UI that asks questions and acts acordingly. 

**Push user to admin group**: Adds a local user to local admin group. Simple UI that asks questions and acts acordingly. 

**Read or Modify public calendar settings**: Tools to set public visibility. Support for finnish 'Kalenteri' settings as well. Menu driven UI. 

**Start Service log archiving with JSON config** Checks for service. Start it if not running. Log files + archiving of old files. JSON config file defines paths and log notes.  Basically a stub script to build upon so replace actual payload with whatever you want. The script takes care of log handling.
