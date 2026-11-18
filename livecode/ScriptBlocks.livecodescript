script "ScriptBlocks"
######################################################################################
## SCRIPTBLOCKS: harvest, manage and export script blocks  (LIB_SCRIPTBLOCKS, 13 11 2026)
## Harvest: tools/harvest_blocks.py cuts any XTJSON harvest into blocks (GAD's categories).
## Manage: browse and edit every generic script example in LIB_GENERICA/Data/Example: GAD's script
## blocks (handlers by category) and the generic object scripts (button, card, field,
## graphic, group, ...). They are plain text and INACTIVE: nothing here runs or becomes the
## script of anything unless you press Apply and confirm.
##   click a file on the left    its text on the right (the header above it stays read-only)
##   Save      write the file back           Revert   read it again
##   Check     compile the text on a hidden scratch button (nothing runs, nothing kept)
##   Apply     make it the real script of an object you name (asks, then confirms)
##   Find      show only the files that contain a word
##   Replace in all   change a word or line in EVERY example at once (all files backed up
##                    first to Data/Example/_backup/<seconds>/)
##   Export    the open example, or whole blocks by category, into a script-only library file
##             in LIB_SCRIPTBLOCKS/exports/<name>.livecodescript (inactive until used)
## Open this file in LiveCode (IDE or the LIB_MCP standalone): the window builds itself.
######################################################################################

local sRoot, sIndex, sShown, sFile, sHeader, sExports

on preOpenStack
   Ed.Paths
   Ed.BuildUI
   Ed.LoadIndex
end preOpenStack

on Ed.Paths
   local tPath
   put the effective filename of me into tPath
   replace "\" with "/" in tPath
   set the itemDel to "/"
   -- <projects>/LIB_SCRIPTBLOCKS/livecode/ScriptBlocks.livecodescript
   put item 1 to -4 of tPath & "/LIB_GENERICA/Data/Example" into sRoot
   put item 1 to -3 of tPath & "/exports" into sExports
end Ed.Paths

-------------------------------------------------------------------- window

on Ed.BuildUI
   lock screen
   set the title of me to "FOR OWNER | ScriptBlocks: click a script on the left, edit it, Save writes the file (nothing runs)"
   dispatch "Users.TitleStack" with the short name of me, "ScriptBlocks: click a script on the left, edit it, Save writes the file (nothing runs)"   -- LIB_USERS words it, when in use
   set the rect of me to 60, 60, 1260, 860
   Ed.Field "List", "10,44,330,790", true, true
   set the listBehavior of field "List" to true
   set the textSize of field "List" to 11
   Ed.Field "Header", "340,44,1190,104", true, false
   set the textColor of field "Header" to "#707070"
   Ed.Field "Body", "340,110,1190,790", false, false
   set the textFont of field "Body" to "Courier New"
   set the textSize of field "Body" to 12
   set the dontWrap of field "Body" to true
   set the hScrollbar of field "Body" to true
   set the vScrollbar of field "Body" to true
   Ed.Field "Status", "10,796,1190,816", true, false
   set the showBorder of field "Status" to false
   Ed.Button "Save", 10, "Ed.Save"
   Ed.Button "Revert", 100, "Ed.Revert"
   Ed.Button "Check", 190, "Ed.Check"
   Ed.Button "Apply", 280, "Ed.Apply"
   Ed.Button "Find", 370, "Ed.Find"
   Ed.Button "Replace in all", 460, "Ed.ReplaceAll"
   Ed.Button "Export", 590, "Ed.Export"
   Ed.Button "Reload list", 680, "Ed.LoadIndex"
   unlock screen
end Ed.BuildUI

on Ed.Field pName, pRect, pLocked, pVScroll
   if there is not a field pName then
      reset the templateField
      create field pName
   end if
   set the rect of field pName to pRect
   set the lockText of field pName to pLocked
   set the vScrollbar of field pName to pVScroll
end Ed.Field

on Ed.Button pName, pLeft, pMsg
   if there is not a button pName then
      reset the templateButton
      create button pName
      set the script of button pName to "on mouseUp" & cr & "   " & pMsg & cr & "end mouseUp"
   end if
   set the rect of button pName to pLeft, 10, pLeft + 84 + (the number of chars of pName > 8) * 40, 34
end Ed.Button

on Ed.Say pText
   if there is a field "Status" then put pText into field "Status"
end Ed.Say

-------------------------------------------------------------------- the list

-- Data/Example/index.tsv: file, kind, category, handlers, source, users
on Ed.LoadIndex pFilter
   local tText, tLine, tOut, n
   if there is not a file (sRoot & "/index.tsv") then
      Ed.Say "no examples at" && sRoot & " (run tools/extract_script_examples.py)"
      exit Ed.LoadIndex
   end if
   put URL ("file:" & sRoot & "/index.tsv") into tText
   replace numToChar(13) with empty in tText
   delete line 1 of tText
   put empty into sShown
   set the itemDel to tab
   repeat for each line tLine in tText
      if tLine is empty then next repeat
      if pFilter is not empty and not (URL ("file:" & sRoot & "/" & item 1 of tLine) contains pFilter) then next repeat
      put item 1 of tLine & cr after sShown
      if item 2 of tLine is "block" then
         put "BLOCK " & item 3 of tLine & " (" & item 4 of tLine & ")" & cr after tOut
      else
         put item 1 of tLine into n
         replace "objects/" with empty in n
         put n & " (" & item 4 of tLine & " h, " & item 6 of tLine & " use)" & cr after tOut
      end if
   end repeat
   set the itemDel to comma
   put tOut into field "List"
   put empty into sFile
   Ed.Say (the number of lines of sShown) && "examples" & (" containing" && quote & pFilter & quote) & ". Click one."
end Ed.LoadIndex

on mouseUp
   local n
   if the short name of the target is not "List" then pass mouseUp
   put the hilitedLine of field "List" into n
   if n is a number then Ed.Open line n of sShown
end mouseUp

-------------------------------------------------------------------- one file

on Ed.Open pRel
   local tText
   put pRel into sFile
   put URL ("file:" & sRoot & "/" & pRel) into tText
   replace numToChar(13) with empty in tText
   put Ed.SplitHeader(tText) into tText
   put sHeader into field "Header"
   put tText into field "Body"
   Ed.Say pRel && "-" && the number of lines of tText && "lines (inactive text)"
end Ed.Open

-- the '--' header up to the INACTIVE line goes to sHeader; returns the rest
function Ed.SplitHeader pText
   local n
   put empty into sHeader
   put lineOffset("(INACTIVE example", pText) into n
   if n is 0 then return pText
   put line 1 to n of pText into sHeader
   delete line 1 to n of pText
   if line 1 of pText is empty then delete line 1 of pText
   return pText
end Ed.SplitHeader

on Ed.Save
   if sFile is empty then exit Ed.Save
   put sHeader & cr & cr & field "Body" & cr into URL ("file:" & sRoot & "/" & sFile)
   Ed.Say "saved" && sFile
end Ed.Save

on Ed.Revert
   if sFile is not empty then Ed.Open sFile
end Ed.Revert

-- compile only: the text becomes the script of a hidden scratch button for a moment
on Ed.Check
   local tErr
   if there is not a button "ed_check" then
      reset the templateButton
      create invisible button "ed_check"
   end if
   set the script of button "ed_check" to field "Body"
   put the result into tErr
   set the script of button "ed_check" to empty
   if tErr is empty then
      Ed.Say "compiles OK:" && sFile
   else
      Ed.Say "does not compile:" && line 1 of tErr && "(error, line, column)"
   end if
end Ed.Check

-- the only way an example becomes active: you name the object, then confirm
on Ed.Apply
   global gEdApplyScript
   local tRef, tOK
   if sFile is empty then exit Ed.Apply
   ask "Make this example the script of which object?" & cr & "(e.g.  button " & quote & "Go" & quote & " of card 1 of stack " & quote & "MyStack" & quote & ")"
   put it into tRef
   if tRef is empty then exit Ed.Apply
   try
      do "put exists(" & tRef & ") into tOK"
   catch tErr
      put false into tOK
   end try
   if tOK is not true then
      Ed.Say "no such object:" && tRef
      exit Ed.Apply
   end if
   answer warning "Replace the script of" && tRef && "with" && sFile & "?" & cr & "It becomes ACTIVE." with "Cancel" or "Apply"
   if it is not "Apply" then exit Ed.Apply
   put field "Body" into gEdApplyScript
   do "set the script of" && tRef && "to gEdApplyScript"
   if the result is empty then
      Ed.Say "applied" && sFile && "to" && tRef
   else
      Ed.Say "not applied:" && the result
   end if
end Ed.Apply

-- a script-only library from the open example, or from whole blocks (comma list of categories)
on Ed.Export
   local tWhich, tName, tBody, tCat, tText, tFile
   ask "Export which blocks? Categories, comma between (e.g. Math,String,List)," & cr & "or leave empty for the example that is open:"
   if the result is "Cancel" then exit Ed.Export
   put it into tWhich
   if tWhich is empty and sFile is empty then exit Ed.Export
   ask "Name of the library (no spaces):" with "lib_blocks"
   if it is empty then exit Ed.Export
   put it into tName
   replace space with "_" in tName
   if tWhich is empty then
      put "-- exported from" && sFile & cr & field "Body" into tBody
   else
      repeat for each item tCat in tWhich
         put word 1 to -1 of tCat into tCat
         put sRoot & "/scriptBlocks/" & tCat & ".txt" into tFile
         if there is not a file tFile then
            put "-- (no block" && tCat & ")" & cr & cr after tBody
            next repeat
         end if
         put URL ("file:" & tFile) into tText
         replace numToChar(13) with empty in tText
         put "-- ======== block" && tCat && "(from LIB_GENERICA/Data/Example)" & cr & Ed.SplitHeader(tText) & cr after tBody
      end repeat
   end if
   Ed.MakeFolders sExports & "/" & tName & ".livecodescript"
   put "script" && quote & tName & quote & cr & "-- LIB_SCRIPTBLOCKS export," && the long date && the long time & cr & tBody into URL ("file:" & sExports & "/" & tName & ".livecodescript")
   Ed.Say "exported to" && sExports & "/" & tName & ".livecodescript (inactive until someone uses it)"
end Ed.Export

on Ed.Find
   ask "Show only examples containing:"
   if the result is "Cancel" then exit Ed.Find
   Ed.LoadIndex it
end Ed.Find

-------------------------------------------------------------------- every file at once

-- change one text in every example's body (headers untouched), after backing all of them up
on Ed.ReplaceAll
   local tFind, tWith, tBackup, tRel, tText, tBody, tCount, tFiles, tAll
   ask "Replace in ALL examples. Find:"
   if it is empty then exit Ed.ReplaceAll
   put it into tFind
   ask "Replace" && quote & tFind & quote && "with:"
   if the result is "Cancel" then exit Ed.ReplaceAll
   put it into tWith
   put sRoot & "/_backup/" & the seconds into tBackup
   put Ed.AllFiles(sRoot, empty) into tAll
   answer "Change" && quote & tFind & quote && "to" && quote & tWith & quote && "in" && the number of lines of tAll && "files?" & cr & "(backup first:" && tBackup & ")" with "Cancel" or "Replace"
   if it is not "Replace" then exit Ed.ReplaceAll
   put 0 into tCount
   put 0 into tFiles
   repeat for each line tRel in tAll
      put URL ("file:" & sRoot & "/" & tRel) into tText
      Ed.MakeFolders tBackup & "/" & tRel
      put tText into URL ("file:" & tBackup & "/" & tRel)
      replace numToChar(13) with empty in tText
      put Ed.SplitHeader(tText) into tBody
      if tBody contains tFind then
         add Ed.Occurrences(tBody, tFind) to tCount
         replace tFind with tWith in tBody
         put sHeader & cr & cr & tBody into URL ("file:" & sRoot & "/" & tRel)
         add 1 to tFiles
      end if
   end repeat
   if sFile is not empty then Ed.Open sFile
   Ed.Say "replaced" && tCount && "times in" && tFiles && "files; backup:" && tBackup
end Ed.ReplaceAll

function Ed.Occurrences pText, pFind
   local n, p
   put 0 into n
   put offset(pFind, pText) into p
   repeat while p > 0
      add 1 to n
      delete char 1 to p + the number of chars of pFind - 1 of pText
      put offset(pFind, pText) into p
   end repeat
   return n
end Ed.Occurrences

-- every .txt example below the root (not the backups), relative paths
function Ed.AllFiles pFolder, pRel
   local tOut, tF, tSub
   repeat for each line tF in files(pFolder)
      if char -4 to -1 of tF is ".txt" then put pRel & tF & cr after tOut
   end repeat
   repeat for each line tSub in folders(pFolder)
      if tSub is "." or tSub is ".." or tSub is "_backup" then next repeat
      put Ed.AllFiles(pFolder & "/" & tSub, pRel & tSub & "/") after tOut
   end repeat
   return tOut
end Ed.AllFiles

on Ed.MakeFolders pFile
   local tSoFar, tPart, n, tCount
   set the itemDel to "/"
   put the number of items of pFile into tCount
   put 0 into n
   repeat for each item tPart in pFile
      add 1 to n
      if n is tCount then exit repeat     -- the file name itself
      put tPart after tSoFar
      if n > 4 and tPart is not empty and there is not a folder tSoFar then create folder tSoFar
      put "/" after tSoFar
   end repeat
end Ed.MakeFolders
