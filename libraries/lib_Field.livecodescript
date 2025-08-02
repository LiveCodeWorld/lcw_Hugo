script "lib_Field"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Field
type: library
version: 0.1


--> Working on
-


--> Field
-
command field_SetLinkedText newLinkText, startChar, endChar, someField
   if startChar is empty then
      put the selectedChunk into someChunk
      put the selectedField into someField 
      put word 2 of someChunk into startChar
      put word 4 of someChunk into endChar
   end if
   
   put the linkText of someChunk into someLink
   put the textStyle of someChunk into oStyle
   
   set the field_Text [startChar,endChar] of someField to newLinkText
   
   put startChar + the number of chars of newLinkText into endChar
   set the textStyle of char startChar to endChar of someField to oStyle
   set the linkText of char startChar to endChar of someField to someLink
end field_SetLinkedText

command field_ScrollToLine lineNum, fieldObject, pSelectLine
   -- does not seem accurate for large line numbers (it's an underestimate) ???
   
   if lineNum = 0 then
      put 0 into someScroll
   else if lineNum is a number then
      put the effective textHeight of fieldObject into lineHeight
      put ((lineNum - 1) * lineHeight) - 0 * the height of fieldObject into someScroll
   else -- any text = "bottom"
      -- bit of a hack (but works :)
      put the effective textHeight of fieldObject into lineHeight
      put the number of lines of the text of fieldObject into lineNum
      put ((lineNum - 1) * lineHeight) - 0 * the height of fieldObject into someScroll
   end if
   set the scroll of fieldObject to someScroll
   if pSelectLine is not false then
      select line lineNum of fieldObject
   end if
end field_ScrollToLine

getprop field_AutoScrollBar
   put the long ID of the target into someField
   if word 1 of someField is not "field" then return "Error: target is not a field"
   
   if the formattedHeight of someField > the height of someField then
      set the vScrollbar of someField to true
      return true
   else
      set the vScrollbar of someField to false
      return false
   end if
end field_AutoScrollBar

getprop field_Menu [someType]
   -- more complicated but allows local overriding!
   
   switch someType 
      case "Inside"
         -- a click on an existing selection
         -- set the menu_Title of the target to "Field | Menu"
         put the menu_Title of the target into menuTitle
         return menuTitle
      case "Outside"
         -- a click on a new empty selection
         return "Global | HyperField | Menu"
      case empty
         return "Global | Field | Menu"
   end switch
end field_Menu

getprop field_WrappedText
   put the formattedtext of the target into fText
   repeat for each line someLine in fText
      put word 1 to -1 of someLine & "\n" after nText
   end repeat
   delete char -2 to -1 of nText
   return nText
end field_WrappedText

getprop field_Text [charOffsets]
   put the long ID of the target into someField
   
   if charOffsets is empty then
      put "get the text of someField" into doScript
   else
      put item 1 of charOffsets into startChar
      put item 2 of charOffsets into endChar
      
      -- put "get char startChar to endChar of someField" into doScript	# does not work
      -- put "get the text of char startChar to endChar of" && someField into doScript	# does not work
      put "get char startChar to endChar of" && someField into doScript
      -- put merge("get char [[startChar]] to [[endChar]] of [[someField]]") into doScript
   end if
   do doScript
   return it
end field_Text

setprop field_Text [charOffsets] someText
   put the long ID of the target into someField
   
   if charOffsets is empty then
      put "set the text of someField to someHtml" into doScript
   else
      put item 1 of charOffsets into startChar
      put item 2 of charOffsets into endChar
      put merge("put someText into char [[startChar]] to [[endChar]] of [[someField]]") into doScript
   end if
   do doScript
   return the result
end field_Text

getprop field_HtmlText [charOffsets]
   put the long ID of the target into someField
   
   if charOffsets is empty then
      put "get the htmltext of someField" into doScript
   else
      put item 1 of charOffsets into startChar
      put item 2 of charOffsets into endChar
      put "get the htmltext of char startChar to endChar of someField" into doScript
   end if
   do doScript
   return it
end field_HtmlText

setprop field_HtmlText [charOffsets] someHtml
   put the long ID of the target into someField
   
   if charOffsets is empty then
      put "set the htmltext of someField to someHtml" into doScript
   else
      put item 1 of charOffsets into startChar
      put item 2 of charOffsets into endChar
      put "set the htmltext of char startChar to endChar of someField to someHtml" into doScript
   end if
   do doScript
   return the result
end field_HtmlText

getprop field_LinkVisited [someWord]
   put the short ID of the target into fieldID
   
   put wordOffset(someWord, the text of field ID fieldID) into wordNum
   if wordnum = 0 then return false
   return the visited of word wordNum of field ID fieldID
end field_LinkVisited

setprop field_LinkVisited [someWord] boolean
   put the short ID of the target into fieldID
   
   put wordOffset(someWord, the text of field ID fieldID) into wordNum
   if wordnum = 0 then return empty
   set the visited of word wordNum of field ID fieldID to boolean
   return wordNum
end field_LinkVisited

getprop field_TextAlign
   put the long ID of the target into someField
   if word 1 of someField is "field" then
      return the textAlign of someField
   else
      return empty
   end if
end field_TextAlign

setprop field_TextAlign fieldTextAlign
   put the long ID of the target into someField
   if word 1 of someField is "field" then
      set the textAlign of someField to fieldTextAlign
      return true
   else
      return false
   end if
end field_TextAlign

getprop field_TextAligns
   get "left,center,right"
   replace comma with CR in it
   return it
end field_TextAligns

getprop field_Locked
   return the lockText of the target
end field_Locked

setprop field_Locked [makeList] someBoolean
   -- was "field_LockText"
   
   put the long ID of the target into fieldObject
   
   if word 1 of fieldObject is "field" then
      set the lockText of fieldObject to someBoolean
      if makeList is not empty then set the listBehavior of fieldObject to makeList is true
      
      if the listBehavior of fieldObject is true then
         if someBoolean is true then
            put the uOPN ["listbehavior"] of fieldObject into oBoolean
            put oBoolean is not false into oBoolean
            
            set listBehavior of fieldObject to oBoolean
         else
            set the uOPN ["listbehavior"] of fieldObject to true
            set listBehavior of fieldObject to false
         end if
      else
         set the traversalOn of fieldObject to true
         set the autoHilite of fieldObject to true
      end if
   end if
end field_Locked


--> Deps
-
