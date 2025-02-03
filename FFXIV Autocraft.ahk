#Requires AutoHotkey v2.0
; #HotIf WinActive("FINAL FANTASY XIV")

PROGRAM_TITLE := "Auto Craft Companion"
PREFERENCES_FILENAME 	:= "ffxiv_autocraft_preferences.txt"
HEADING_TEXT_STYLE		:= "cCCCCCC s16 q0 w700"
SUBHEADING_TEXT_STYLE	:= "c828282 s12 q0 w400"
BODY_TEXT_STYLE 		:= " cCCCCCC s12 q0 w400 "
EDIT_STYLE 				:= " cCCCCCC Background262626 Center Border w175 "
SMALL_EDIT_STYLE 		:= " cCCCCCC Background262626 Center Border w30 "

MARGIN_TOP := " y20 "
MARGIN_LEFT := " x30 "

; Right Ctrl + K.
>^k::
{
	MouseGetPos &ffxivXPos, &ffxivYPos ; Save where the Synthesize button is in the FFXIV window
	inputGui := Gui("-Caption", PROGRAM_TITLE)

	inputGui.SetFont("cWhite", "Meiryo")
	WinSetTransColor((inputGui.BackColor := "010101") ' 255', inputGui)

	; Adding the image here because doing it the other way makes all the other units have transparent backgrounds
	inputGui.Add("Picture","w700 h550", "bg.png")

	; HEADER
	inputGui.SetFont(HEADING_TEXT_STYLE, "Meiryo")
	inputGui.AddText("Section BackgroundTrans" . MARGIN_LEFT . MARGIN_TOP, PROGRAM_TITLE)
	inputGui.Add("Picture","BackgroundTrans ys x660", "quit.png").OnEvent("Click", (*) => ExitApp())
	inputGui.Add("Picture","BackgroundTrans w650 xs", "bar.png")

	; PROFILES
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans Section", "Profile")
	inputGui.Add("DropDownList", "vProfile Background262626 ys h100 w270", [])
	inputGui.Add("Button", "ys", "Delete Profile")
	inputGui.Add("Picture", "BackgroundTrans w650 xs", "bar.png")

	; MACROS
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans Section", "Macro Key and Duration in Seconds")
	inputGui.Add("Picture", "BackgroundTrans w315 xs", "bar.png")

	inputGui.SetFont(BODY_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans xp", "Profile Name:")
	inputGui.Add("Edit", "vProfileName yp" . EDIT_STYLE . "Left w182", "")
	inputGui.Add("Text", "BackgroundTrans xs", "Macro 1: ")
	inputGui.Add("Edit", "vMacro1Button yp Center" . EDIT_STYLE, "V")
	inputGui.Add("Edit", "vMacro1Duration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)

	inputGui.Add("Text", "BackgroundTrans xs" . MARGIN_LEFT, "Macro 2: ")
	inputGui.Add("Edit", "vMacro2Button yp" . EDIT_STYLE, "T")
	inputGui.Add("Edit", "vMacro2Duration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	inputGui.Add("Checkbox", "Checked Background262626 yp h25", "")

	inputGui.Add("Text", "BackgroundTrans xs", "Number of Crafts:")
	crafts := inputGui.Add("Edit", "vNumOfCrafts Number Limit2 yp" . EDIT_STYLE, 1)

	; CONSUMABLES
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans ys Section", "Consumables and Time Remaining")
	inputGui.Add("Picture", "BackgroundTrans xp w315", "bar.png")

	inputGui.SetFont(BODY_TEXT_STYLE, "Meiryo")

	inputGui.Add("Text", "BackgroundTrans xs", "Food:   ")
	inputGui.Add("Edit", "vFoodButton yp Center" . EDIT_STYLE, "Num2")
	inputGui.Add("Edit", "vFoodDuration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	inputGui.Add("Checkbox", "Checked Background262626 yp h25", "")


	inputGui.Add("Text", "BackgroundTrans Section xs", "Potion: ")
	inputGui.Add("Edit", "vPotionButton yp" . EDIT_STYLE, "Num1")
	inputGui.Add("Edit", "vPotionDuration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	inputGui.Add("Checkbox", "Checked Background262626 yp h25", "")

	inputGui.Add("Text", "BackgroundTrans xs", "Any Food Duration Buffs?")
	inputGui.Add("DropDownList", "vFoodBuff Background262626 xp w270 Choose1", [
		"No Buffs (30 min)",
		"Meat and Mead (35 min)",
		"Meat and Mead II (40 min)",
		"Squadron Rationing Manual (45 min)"
		]
	)

	progressBar := inputGui.Add("Progress", "xp x30 y315 w650 Background262626 cA3CC43 Border", 10)
	completionTimeText := inputGui.Add("Text", "xp  Background262626", "Time to completion: 0")

	; Bottom Section
	inputGui.Add("CheckBox", "vKillOnComplete xp x30 y385 Background262626", "Close FFXIV when Complete?")

	synthBtn := inputGui.Add("Button", "Section Default w100 h64 xp", "Start Autocraft").OnEvent("Click", ffxivPenumbraAutoCraft)
	synthBtn := inputGui.Add("Button", "w100 h57 xp", "Save as`nNew Profile").OnEvent("Click", (*) => log("Saved Profile"))
	infoLog  := inputGui.Add("Edit", "ys ReadOnly Background262626 r6 w550", "Welcome to the Auto Craft Companion!")

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

	;Move the Gui while the left mouse button is down
	OnMessage(0x0201, (*) => PostMessage(0x00A1, 2, 0, inputGui))

	; Callback function when the Main Gui is finished
	ffxivPenumbraAutoCraft(*) {
		log("Starting Craft")
		data := inputGui.Submit(false) ; Do not hide the window when start is hit

		macroDuration := data.SingleCraftDuration * data.NumOfCrafts
		completionTime := DateAdd(A_Now, macroDuration, "Seconds")

		completionTimeText.Value := Format(
			"Completion Time:`n{1}`n({2} Minutes)",
			FormatTime(completionTime, "hh:mm:ss tt"),
			Round(macroDuration/60, 2)
		)

		return

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


	log(text) {
		infoLog.Value := infoLog.Value . "`n" . Format("[{1}] {2}", FormatTime(A_Now, "hh:mm:ss tt"), text)
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