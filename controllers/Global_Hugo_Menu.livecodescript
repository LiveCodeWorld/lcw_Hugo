script "Global_Hugo_Menu"
--> MetaData
-
license: GPLv3
name: Global_Hugo_Menu
type: controller
version: 0.1


--> Menu | Props
-
local LocalArray

getprop hugoProject_Param
   put LocalArray ["hugoProject_Param"] into projectName
   if projectName is empty then
      put line -1 of hugo_ListProjectNames() into projectName
      put projectName into LocalArray ["hugoProject_Param"]
   end if
   return projectName
end hugoProject_Param

setprop hugoProject_Param projectName
   put projectName into LocalArray ["hugoProject_Param"]
end hugoProject_Param

getprop hugoProject_Params
   return hugo_ListProjectNames()
end hugoProject_Params

getprop disabled_TrashPublicFolder
   put the hugoProject_Param of me into projectName
   put hugo_GetPublicFolder (projectName) into publicFolder
   if there is a folder publicFolder then
      return false
   else
      return true
   end if
end disabled_TrashPublicFolder

getprop disabled_StartHugoServer
   put LocalArray ["portID"] into portID
   if portID is empty then
      return false
   else
      return true
   end if
end disabled_StartHugoServer

getprop disabled_StopHugoServer
   put LocalArray ["portID"] into portID
   if portID is empty then
      return true
   else
      return false
   end if
end disabled_StopHugoServer


--> Events
-
on mDouble_File arrayView, shortFile, somePath
   put the hugoProject_Param of me into projectName
   put hugo_GetPublicFolder (projectName) into publicFolder
   put publicFolder & somePath into someFile
   --
   put url ("binfile:" & someFile) into fileContents
   atom_DisplayFile someFile
end mDouble_File

on iCommand
   put the params
end iCommand

on NewRequest pSocketID, pRequest
   local tData, pHeaders
   --
   put the hugoProject_Param of me into projectName
   put hugo_GetPublicFolder (projectName) into publicFolder
   --
   put pRequest ["resource"] into rResource
   put pRequest ["method"] into rMethod
   put pRequest ["parameters"] into rParams
   put pRequest ["headers"] into rheaders
   put pRequest ["contents"] into rContents
   --
   delete char 1 of rResource
   set the itemDelimiter to "."
   switch
      case rResource is empty 
         put "index.html" into rResource
         break
      case item -1 of rResource is not among the items of "html.xml"
         if char -1 of rResource is not slash then
            put slash after rResource
         end if
         put "index.html" after rResource
         break
   end switch
   put publicFolder & rResource into tPath
   --
   if there is a file tPath then
      put url ("binfile:" & tPath) into tData
      httpdResponse pSocketID, 200, tData, pHeaders 
   else
      -- not found
      httpdResponse pSocketID, 404
      put tPath
   end if
end NewRequest


--> Global | Hugo | Menu
-
on menu_HugoServer
   put the hugoProject_Param of me into projectName
   --
   -- hugo_BackgroundServer projectName
   -- put hugo_ExtractLocalUrl (shellResult) into localURL
   
   hugo_OpenProcess projectName
   put the result into localURL
   --
   launch url localURL
end menu_HugoServer

on menu_CloseHugoProcess
   hugo_CloseProcess
   put the result into processPath
   -- hugo_KillProcess
   put hugo_GetProcess() into hugoProcesses
   if hugoProcesses is empty then
      lcw_Notify "Killed all hugo processes."
   else
      answer warning the result
   end if
end menu_CloseHugoProcess

on menu_HugoProcesses
   put hugo_GetProcess()
end menu_HugoProcesses

on _
end _

on menu_HugoExport
   put the hugoProject_Param of me into projectName
   hugo_Run projectName
   put the result
end menu_HugoExport

on menu_DisplayFiles
   put the hugoProject_Param of me into projectName
   put hugo_GetPublicFolder (projectName) into projectFolder
   put array_FromFolder (projectFolder, true) into fileArray
   --
   local mTitle, lTitle, iCommand, dCommand
   put "mInspect_File" into iCommand
   put "mDouble_File" into dCommand
   display_Array fileArray, "Files", mTitle, lTitle, iCommand, dCommand
end menu_DisplayFiles

on _
end _

on menu_StartHugoServer indexView
   -- uses Livecode as a server (not finsihed)
   put the hugoProject_Param of me into projectName
   put hugo_GetPublicFolder (projectName) into projectFolder
   set the defaultfolder to projectFolder
   --
   httpdStart "NewRequest"
   put it into portID
   put portID into LocalArray ["portID"]
   --
   launch url ("http://localhost:" & portID)
end menu_StartHugoServer

on menu_StopHugoServer
   -- uses Livecode as a server (not finsihed)
   put LocalArray ["portID"] into portID
   httpdStop portID
   delete variable LocalArray ["portID"]
end menu_StopHugoServer

on _
end _

on menu_TrashPublicFolder
   put the hugoProject_Param of me into projectName
   put hugo_GetPublicFolder (projectName) into publicFolder
   if there is a folder publicFolder then
      revDeleteFolder publicFolder
   end if
end menu_TrashPublicFolder

on _
end _

on menu_HugoProject indexView, projectName
   set the hugoProject_Param of me to projectName
end menu_HugoProject

on _
end _

on menu_ListHugoFolders
   put hugo_ListProjectNames()
end menu_ListHugoFolders
