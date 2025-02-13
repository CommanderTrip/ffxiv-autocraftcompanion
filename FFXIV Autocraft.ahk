#Requires AutoHotkey v2.0
; #HotIf WinActive("FINAL FANTASY XIV")

PROGRAM_TITLE := "Auto Craft Companion"
PREFERENCES_FILENAME 	:= "ffxiv_auto_craft_companion_profiles.ini"
HEADING_TEXT_STYLE		:= "cCCCCCC s16 q0 w700"
SUBHEADING_TEXT_STYLE	:= "c828282 s12 q0 w400"
BODY_TEXT_STYLE 		:= " cCCCCCC s12 q0 w400 "
EDIT_STYLE 				:= " cCCCCCC Background262626 Center Border w175 "
SMALL_EDIT_STYLE 		:= " cCCCCCC Background262626 Center Border w30 "

MARGIN_TOP  := " y20 "
MARGIN_LEFT := " x30 "

; Right Ctrl + K.
>^k::
{
	if (WinExist(PROGRAM_TITLE)) {
		; Can we allow the user to reset their cursor position here?
		return
	}

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
	profilesList := inputGui.Add("DropDownList", "vProfile Background262626 ys h100 w270", [])
	profilesList.OnEvent("Change", loadPreferences)
	inputGui.Add("Button", "ys", "Delete Profile").OnEvent("Click", deleteProfile)
	inputGui.Add("Picture", "BackgroundTrans w650 xs", "bar.png")

	; MACROS
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans Section", "Macro Key and Duration in Seconds")
	inputGui.Add("Picture", "BackgroundTrans w315 xs", "bar.png")

	inputGui.SetFont(BODY_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans xp", "Profile Name:")
	profileNameEdit := inputGui.Add("Edit", "vProfileName yp" . EDIT_STYLE . "Left w182", "Default")
	inputGui.Add("Text", "BackgroundTrans xs", "Macro 1: ")
	macro1ButtonEdit := inputGui.Add("Edit", "vMacro1Button yp Center" . EDIT_STYLE, "V")
	macro1DurationEdit := inputGui.Add("Edit", "vMacro1Duration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)

	inputGui.Add("Text", "BackgroundTrans xs" . MARGIN_LEFT, "Macro 2: ")
	macro2ButtonEdit := inputGui.Add("Edit", "vMacro2Button yp" . EDIT_STYLE, "T")
	macro2DurationEdit := inputGui.Add("Edit", "vMacro2Duration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	macro2EnabledCheckbox := inputGui.Add("Checkbox", "vMacro2Enabled Checked Background262626 yp h25", "")

	inputGui.Add("Text", "BackgroundTrans xs", "Number of Crafts:")
	numOfCraftsEdit := inputGui.Add("Edit", "vNumOfCrafts Number Limit2 yp" . EDIT_STYLE, 1)

	; CONSUMABLES
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans ys Section", "Consumables and Time Remaining")
	inputGui.Add("Picture", "BackgroundTrans xp w315", "bar.png")

	inputGui.SetFont(BODY_TEXT_STYLE, "Meiryo")

	inputGui.Add("Text", "BackgroundTrans xs", "Food:   ")
	foodButtonEdit := inputGui.Add("Edit", "vFoodButton yp Center" . EDIT_STYLE, "Num2")
	foodDurationEdit := inputGui.Add("Edit", "vFoodDuration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	foodEnabledCheckbox := inputGui.Add("Checkbox", "vFoodEnabled Checked Background262626 yp h25", "")

	inputGui.Add("Text", "BackgroundTrans Section xs", "Potion: ")
	potionButtonEdit := inputGui.Add("Edit", "vPotionButton yp" . EDIT_STYLE, "Num1")
	potionDurationEdit := inputGui.Add("Edit", "vPotionDuration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	potionEnabledCheckbox := inputGui.Add("Checkbox", "vPotionEnabled Checked Background262626 yp h25", "")

	inputGui.Add("Text", "BackgroundTrans xs", "Any Food Duration Buffs?")
	foodBuffDropDown := inputGui.Add("DropDownList", "vFoodBuff Background262626 xp w270 Choose1 AltSubmit", [
		"No Buffs (30 min)",
		"Meat and Mead (35 min)",
		"Meat and Mead II (40 min)",
		"Squadron Rationing Manual (45 min)"
		]
	)

	progressBar := inputGui.Add("Progress", "xp x30 y315 w650 Background262626 cA3CC43 Border", 10)
	completionTimeText := inputGui.Add("Text", "xp  Background262626", "Time to completion: 0")

	; Bottom Section
	killOnComplete := inputGui.Add("CheckBox", "vKillOnComplete xp x30 y385 Background262626", "Close FFXIV when Complete?")

	inputGui.Add("Button", "Section Default w100 h64 xp", "Start Autocraft").OnEvent("Click", ffxivPenumbraAutoCraft)
	inputGui.Add("Button", "w100 h57 xp", "Save`nProfile")			.OnEvent("Click", savePreferences)
	infoLog  := inputGui.Add("Edit", "ys ReadOnly Background262626 r6 w550", "Welcome to the Auto Craft Companion!")

	updatePreferencesDropDown() ; Load the whole gui before we try setting anything

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

		log(Format("Your {1} crafts are done! 😊", data.NumOfCrafts))
	}

	; Default behavior is to choose the first option in the list
	updatePreferencesDropDown(resetOption := true, selectProfile := "") {
		profiles := IniRead(PREFERENCES_FILENAME,,, 0)
		if (!profiles) {
			; Create the file and save the default settings as a profile
			file := FileOpen(PREFERENCES_FILENAME, "w")
			file.Close()
			savePreferences()
			return
		}
		profiles := StrSplit(profiles, "`n")

		oldOption := profilesList.Text
		profilesList.Delete()
		profilesList.Add(profiles)

		if (resetOption) {
			profilesList.Choose(1)
		} else if (StrLen(selectProfile)) {
			profilesList.Choose(selectProfile)
		} else {
			profilesList.Choose(oldOption)
		}
	}

	savePreferences(*) {
		data := inputGui.Submit(false)
		log(Format("Saving {1} Profile", data.ProfileName))
		IniWrite(data.Macro1Button, 	PREFERENCES_FILENAME, data.ProfileName,	"MACRO_1_BIND")
		IniWrite(data.Macro1Duration,	PREFERENCES_FILENAME, data.ProfileName,	"MACRO_1_DURATION")
		IniWrite(data.Macro2Button,		PREFERENCES_FILENAME, data.ProfileName,	"MACRO_2_BIND")
		IniWrite(data.Macro2Duration, 	PREFERENCES_FILENAME, data.ProfileName,	"MACRO_2_DURATION")
		IniWrite(data.Macro2Enabled, 	PREFERENCES_FILENAME, data.ProfileName,	"MACRO_2_ENABLED")
		IniWrite(data.NumOfCrafts, 		PREFERENCES_FILENAME, data.ProfileName, "NUMBER_OF_CRAFTS")
		IniWrite(data.FoodButton, 		PREFERENCES_FILENAME, data.ProfileName, "FOOD_BIND")
		IniWrite(data.FoodDuration, 	PREFERENCES_FILENAME, data.ProfileName, "FOOD_TIME_REMAINING")
		IniWrite(data.FoodEnabled, 		PREFERENCES_FILENAME, data.ProfileName, "FOOD_MACRO_ENABLED")
		IniWrite(data.FoodBuff, 		PREFERENCES_FILENAME, data.ProfileName, "FOOD_DURATION_BUFFS")
		IniWrite(data.PotionButton, 	PREFERENCES_FILENAME, data.ProfileName, "POTION_BIND")
		IniWrite(data.PotionDuration, 	PREFERENCES_FILENAME, data.ProfileName,	"POTION_TIME_REMAINING")
		IniWrite(data.PotionEnabled, 	PREFERENCES_FILENAME, data.ProfileName, "POTION_MACRO_ENABLED")
		IniWrite(data.KillOnComplete, 	PREFERENCES_FILENAME, data.ProfileName, "CLOSE_FFXIV_WHEN_DONE")
		updatePreferencesDropDown(false, data.ProfileName)
	}

	loadPreferences(*) {
		log(Format("Loading {1} Profile", profilesList.Text))
		macro1ButtonEdit.Value		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "MACRO_1_BIND")
		macro1DurationEdit.Value 	:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "MACRO_1_DURATION")
		macro2ButtonEdit.Value 		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "MACRO_2_BIND")
		macro2DurationEdit.Value 	:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "MACRO_2_DURATION")
		macro2EnabledCheckbox.Value := IniRead(PREFERENCES_FILENAME, profilesList.Text, "MACRO_2_ENABLED")
		numOfCraftsEdit.Value 		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "NUMBER_OF_CRAFTS")
		foodButtonEdit.Value 		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "FOOD_BIND")
		foodDurationEdit.Value 		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "FOOD_TIME_REMAINING")
		foodEnabledCheckbox.Value 	:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "FOOD_MACRO_ENABLED")
		foodBuffDropDown.Choose(Number(IniRead(PREFERENCES_FILENAME, profilesList.Text, "FOOD_DURATION_BUFFS")))
		potionButtonEdit.Value 		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "POTION_BIND")
		potionDurationEdit.Value 	:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "POTION_TIME_REMAINING")
		potionEnabledCheckbox.Value := IniRead(PREFERENCES_FILENAME, profilesList.Text, "POTION_MACRO_ENABLED")
		killOnComplete.Value 		:= IniRead(PREFERENCES_FILENAME, profilesList.Text, "CLOSE_FFXIV_WHEN_DONE")
	}

	deleteProfile(*) {
		log(Format("Deleting {1} Profile", profilesList.Text))
		IniDelete(PREFERENCES_FILENAME, profilesList.Text)
		updatePreferencesDropDown()
	}

	log(text, addToLastLine := false) {
		if (addToLastLine) {
			infoLog.Value := infoLog.Value . " " . text
		} else {
			infoLog.Value := infoLog.Value . '`n' . Format("[{1}] {2}", FormatTime(A_Now, "hh:mm:ss tt"), text)
		}
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