#Requires AutoHotkey v2.0
#HotIf WinActive("FINAL FANTASY XIV")

PREFERENCES_FILENAME := "ffxiv_autocraft_preferences.txt"

; Right Ctrl + K.
>^k::
{
	MouseGetPos &ffxivXPos, &ffxivYPos ; Save where the Synthesize button is in the FFXIV window
	inputGui := Gui(, "FFXIV Autocraft")

	inputGui.Add("Text","Section", "Number of Crafts:")
	inputGui.Add("Text",, "Time per one craft in seconds: ")
	inputGui.Add("Text",, "Key to press: ")
	inputGui.AddCheckBox("vSaveAsDefault", "Save as defaults?")

	crafts := inputGui.Add("Edit", "vNumOfCrafts Number Limit2 ys w100", 1)
	time   := inputGui.Add("Edit", "vSingleCraftDuration Number w100", 10)
	key    := inputGui.Add("Edit", "vFfxivMacroKey Limit1 w100", "V")

	inputGui.Add("Text",, "`n`n")

	inputGui.AddCheckBox("vKillOnComplete xm", "Close FFXIV when Complete?")
	inputGui.Add("Button", "Section Default w100 x50", "Start Autocraft").OnEvent("Click", ffxivPenumbraAutoCraft)
	inputGui.Add("Button", "w100 ys", "Cancel Autocraft").OnEvent("Click", closeWindow(*) => inputGui.Destroy())

	try {
		preferencesFile := FileOpen(PREFERENCES_FILENAME, "r-d")
		preferences := preferencesFile.ReadLine()
		prefArray := StrSplit(preferences, ",")
		crafts.Value := prefArray[1]
		time.Value := prefArray[2]
		key.Value := prefArray[3]
	} catch as Err {
		; file doesn't exist or some other error but that's okay
	}

	inputGui.Show()

	; Callback function when the Main Gui is finished
	ffxivPenumbraAutoCraft(*) {
		data := inputGui.Submit()

		; Save Preferences
		if (data.SaveAsDefault) {
			try {
				preferencesFile := FileOpen(PREFERENCES_FILENAME, "w")
				preferencesFile.Write(Format("{1},{2},{3}", data.NumOfCrafts, data.SingleCraftDuration, data.FfxivMacroKey))
				preferencesFile.Close()
			} catch as Err {
				MsgBox "Can't open '" PREFERENCES_FILENAME "' for writing."
					. "`n`n" Type(Err) ": " Err.Message
				return
			}
		}

		macroDuration := data.SingleCraftDuration * data.NumOfCrafts

		displayMacroCraftProgress(macroDuration, data.NumOfCrafts)

		Loop data.NumOfCrafts {
			MouseGetPos &userXPos, &userYPos ; Get the user's current mouse pos to restore to later
			ffxivClickSynthesize(data.FfxivMacroKey, ffxivXPos, ffxivYPos, userXPos, userYPos)
			; Insert here for the second key if enabled
			Sleep data.SingleCraftDuration * 1000
		}

		if (data.KillOnComplete) {
			BlockInput "MouseMove"
			WinActivate "FINAL FANTASY XIV"
			WinGetPos ,,&W,&H, "A"
			WinClose "FINAL FANTASY XIV"
			MouseMove W/2 - 50, H/2 - 10 ; Move the cursor to confirm exit
			Click "Down"
			Sleep 25
			Click "Up"
			Sleep 1000
			BlockInput "MouseMoveOff"
		}

		MsgBox(
			Format(
				"Your {1} crafts are done! 😊",
				data.NumOfCrafts,
			),
			"Done!",
		)
	}
}


; Spaces the press and release because "Click" seems to be too fast.
ffxivClickSynthesize(macroKey, ffxivXPos, ffxivYPos, userXPos, userYPos) {

	; Take control from user
	BlockInput "On"
	BlockInput "SendAndMouse"
	BlockInput "MouseMove"

	; Click Synthesize
	WinActivate "FINAL FANTASY XIV"
	Sleep 50
	MouseMove ffxivXPos, ffxivYPos
	Click "Down"
	Sleep 25
	Click "Up"
	Sleep 25

	; Too many issues if we restore control in the middle

	Sleep 1000 ; Wait for craft window to appear
	WinActivate "FINAL FANTASY XIV"
	Sleep 50
	Send macroKey
	Sleep 25

	; Restore control
	MouseMove userXPos, userYPos

	BlockInput "MouseMoveOff"
	BlockInput "Default"
	BlockInput "Off"
}

; Duration in seconds
; Change to a progress bar for a visual indication of progress over time???
displayMacroCraftProgress(macroDuration, numOfCrafts){
	completionTime := DateAdd(A_Now, macroDuration, "Seconds")
	MsgBox(
		Format(
			"Your {1} crafts will complete at {2} ({3} minutes).",
			numOfCrafts, FormatTime(completionTime, "h:m:ss tt"), Round(macroDuration/60, 2)
		), "Autocraft Progress", "Iconi"
	)
}
