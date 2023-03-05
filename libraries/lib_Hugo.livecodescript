script "lib_Hugo"
--> MetaData
-
license: GPLv3
name: lib_Hugo
type: library
version: 0.1

--> Vairables
-
local LocalArray

--> Hugo
-
function hugo_GetPublicFolder projectName
   put hugo_GetConfig ("publishdir", projectName) into shortPublicFolder
   put env_GetFolder (projectName) into projectFolder
   put projectFolder & shortPublicFolder & "/" into publicFolder
   return publicFolder
end hugo_GetPublicFolder

function hugo_GetConfig someKey, projectName
   put hugo_GetConfigArray (projectName) into configArray
   put configArray [someKey] into someValue
   text_TopAndTail someValue, quote
   return someValue
end hugo_GetConfig

function hugo_GetConfigArray projectName
   -- array values are quoted
   put env_GetFolder (projectName) into projectFolder
   set the defaultfolder to projectFolder
   --
   get shell ("hugo config")
   split it with CR and " = "
   return it
end hugo_GetConfigArray

command hugo_Run projectName
   put env_GetFolder (projectName) into projectFolder
   set the defaultfolder to projectFolder
   --
   get shell ("hugo")
   return it
end hugo_Run

/*
-- put shell ("hugo server &>/dev/null &") into launchResult

-- does not work
-- put shell ("hugo server 2>&1 &") into launchResult
-- put shell ("hugo server &>out &") into launchResult
-- put shell ("hugo server")
-- put shell ("nohup hugo server >&/dev/null") into launchResult
-- puut shell ("screen hugo server") into launchResult
-- put shell ("bash bg_hugo_server.sh") into launchResult
-- open process "bash bg_hugo_server.sh"
-- launch "bg_hugo_server.sh"
-- put the result into launchResult
*/

function hugo_GetProcessPath
   -- return "/usr/local/bin/hugo server"
   put shell ("which hugo") into hugoPath
   if hugoPath is empty then return empty
   
   return line 1 of hugoPath && "server" 
end hugo_GetProcessPath

command hugo_OpenProcess projectName
   put env_GetFolder (projectName) into projectFolder
   set the defaultfolder to projectFolder
   --
   put hugo_GetProcessPath() into tProcess
   open process tProcess for read
   put the result into tResult
   --
   switch tResult
      case empty
         hugo_MonitorProcess tProcess
         put the result into localURL
         return localURL
      case "process is already open"
      case "access denied"
      default
         return "Error," && tResult
   end switch
end hugo_OpenProcess

command hugo_MonitorProcess tProcess
   repeat forever
      -- If the slave process has gone away unexpectedly, dispatch a finished.
      put the openProcesses into tOpenProcesses
      if tProcess is not among the lines of tOpenProcesses then
         return "Error, Hugo is not among the lines of the openProcesses"
      end if
      
      -- Attempt to read a line from the installer process
      read from process tProcess for 1 line in 0 millisecs
      put the result into tResult
      put it into someLine
      put someLine after serverInfo
      --
      switch tResult
         case empty
            -- If there was no error, process the line
            if someLine begins with "Web Server is available at" then
               -- Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
               put word 6 of someLine into localURL
               put localURL into LocalArray ["localURL"]
               -- could return now ???
            else if line 1 of someLine = "Press Ctrl+C to stop" then -- eliminate the return char at end
               -- about to end
               -- let's return without exiting process
               return localURL
            end if
            break
         case "timed out"
            exit repeat -- let's try again in 20ms
            -- return "Error, timed out" & CR&CR & serverInfo  
         case "process is not open for read"
         case "eof"
            -- return "Error, eof" & CR&CR & serverInfo  
         default
            -- If there was an eof or unexpected error, close the process and dispatch
            -- finished
            if line 1 of someLine = "Press Ctrl+C to stop" then
               -- about to end
               -- let's return without exiting process
               return localURL
            else
               close process tProcess
               return "Error," && tResult & CR&CR & serverInfo  
            end if
      end switch
   end repeat
   
   -- We still have a process, then send an update message in a short period of time
   send "hugo_MonitorProcess tProcess" to me in 20 millisecs
   put the result into msgID
   --
   return LocalArray ["localURL"]
end hugo_MonitorProcess

command hugo_CloseProcess
   put hugo_GetProcessPath() into tProcess
   kill process tProcess
   return tProcess
end hugo_CloseProcess

function hugo_ExtractLocalUrl shellResult
   -- defaults to "http://localhost:1313/"
   -- Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
   get line -2 of shellResult
   put word 6 of it into localURL
   return localURL
end hugo_ExtractLocalUrl

private command _ReadFromFile someFile
   repeat 20
      wait 2 ticks
      put url ("file:" & someFile) into fileContents
      if line -1 of fileContents is "Press Ctrl+C to stop" then
         return fileContents
      end if
   end repeat
   return fileContents
end _ReadFromFile

function hugo_ListProjectNames
   put env_ListProjectFolders(true) into pFolders
   set the itemdelimiter to slash
   repeat for each line pFolder in pFolders
      if hugo_IsFolder (pFolder) then
         put item -1 of pFolder & CR after pNames
      end if
   end repeat
   delete char -1 of pNames
   return pNames
end hugo_ListProjectNames

function hugo_ListFolders
   put env_ListProjectFolders(true) into pFolders
   repeat for each line pFolder in pFolders
      if hugo_IsFolder (pFolder) then
         put pFolder & CR after hugoFolders
      end if
   end repeat
   delete char -1 of hugoFolders
   return hugoFolders
end hugo_ListFolders

function hugo_IsFolder projectFolder
   -- look for config.toml
   switch
      case there is a file (projectFolder & "config/_default/config.toml")
      case there is a file (projectFolder & "config.toml")
         return true
         break
      default
         return false
   end switch
end hugo_IsFolder


--> Hugo | Shell Server
-
/*
Calling hugo server using shell is possible 
but not as elegant as using hugo_OpenProcess (which uses open processs) 
*/

command hugo_ShellServer projectName
   put env_GetFolder (projectName) into projectFolder
   set the defaultfolder to projectFolder
   --
   put the tempname & ".txt" into someFile
   put "hugo server >" && someFile && "2>&1 &" into tShell
   put shell (tShell) into shellResult
   
   -- can take some time to start up so let's read from file till the end
   _ReadFromFile someFile
   put the result into fileContents
   return fileContents
end hugo_ShellServer

command hugo_KillProcess
   -- will kill all hugo processes
   put shell ("pkill hugo") into emptyResult
   return hugo_GetProcess() -- should be empty
end hugo_KillProcess

function hugo_GetProcess
   -- can be an index of several processes
   return shell ("pgrep hugo")
end hugo_GetProcess

command process_KillAll
   repeat for each line processPath in the openprocesses
      if the platform = "MacOS" then
         kill process processPath
      else
         close process processPath
      end if
   end repeat
end process_KillAll
