#Requires AutoHotkey v2.0
#HotIf WinActive(FFXIV_PROGRAM_NAME)

FFXIV_PROGRAM_NAME := "FINAL FANTASY XIV"
PROGRAM_TITLE := "Auto Craft Companion"
WINDOW_SIZE := "w700 h625"
PREFERENCES_FILEPATH 	:= "./bin/ffxiv_auto_craft_companion_profiles.ini"
ASSETS_PATH := "./bin/assets/"
HEADING_TEXT_STYLE		:= "cCCCCCC s16 q0 w700"
SUBHEADING_TEXT_STYLE	:= "c828282 s12 q0 w400"
BODY_TEXT_STYLE 		:= " cCCCCCC s12 q0 w400 "
EDIT_STYLE 				:= " cCCCCCC Background262626 Center Border w175 "
SMALL_EDIT_STYLE 		:= " cCCCCCC Background262626 Center Border w30 "

MARGIN_TOP  := " y20 "
MARGIN_LEFT := " x30 "

; Delays in milliseconds
FFXIV_ACTION_DELAY := 2000
FFXIV_CONSUMABLE_DELAY := 2500
FFXIV_INPUT_DELAY := 100

ENUM_CONSUMABLE_FOOD := "FOOD"
ENUM_CONSUMABLE_POTION := "POTION"

; Right Ctrl + K.
>^k::
{
	; No duplicate copies
	if (WinExist(PROGRAM_TITLE)) {
		return
	}

	MouseGetPos &ffxivXPos, &ffxivYPos ; Save where the Synthesize button is in the FFXIV window
	inputGui := Gui("-Caption", PROGRAM_TITLE)
	inputGui.OnEvent("Close", (*) => ExitApp())

	inputGui.SetFont("cWhite", "Meiryo")
	WinSetTransColor((inputGui.BackColor := "010101") ' 255', inputGui)

	; Adding the image here because doing it the other way makes all the other units have transparent backgrounds
	inputGui.Add("Picture", WINDOW_SIZE, ASSETS_PATH . "bg.png")

	; HEADER
	inputGui.SetFont(HEADING_TEXT_STYLE, "Meiryo")
	inputGui.AddText("Section BackgroundTrans" . MARGIN_LEFT . MARGIN_TOP, PROGRAM_TITLE)
	inputGui.Add("Picture","BackgroundTrans ys x660", ASSETS_PATH . "quit.png").OnEvent("Click", (*) => ExitApp())
	inputGui.Add("Picture","BackgroundTrans w650 xs",  ASSETS_PATH . "bar.png")

	; PROFILES
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans Section", "Profile")
	profilesList := inputGui.Add("DropDownList", "vProfile Background262626 ys h100 w270", [])
	profilesList.OnEvent("Change", loadPreferences)
	inputGui.Add("Button", "ys", "Delete Profile").OnEvent("Click", deleteProfile)
	inputGui.Add("Button", "ys", "Save Profile").OnEvent("Click", savePreferences)
	inputGui.Add("Picture", "BackgroundTrans w650 xs", ASSETS_PATH . "bar.png")

	; MACROS
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans Section", "Macro Key and Duration (sec)")
	inputGui.Add("Picture", "BackgroundTrans w315 xs", ASSETS_PATH . "bar.png")

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
	inputGui.Add("Text", "BackgroundTrans ys Section", "Consumables and Time Remaining (min)")
	inputGui.Add("Picture", "BackgroundTrans xp w315", ASSETS_PATH . "bar.png")

	inputGui.SetFont(BODY_TEXT_STYLE, "Meiryo")

	inputGui.Add("Text", "BackgroundTrans xs", "Food:   ")
	foodButtonEdit := inputGui.Add("Edit", "vFoodButton yp Center" . EDIT_STYLE, "{Numpad1}")
	foodDurationEdit := inputGui.Add("Edit", "vFoodDuration Number Limit2 yp" . SMALL_EDIT_STYLE, 10)
	foodEnabledCheckbox := inputGui.Add("Checkbox", "vFoodEnabled Checked Background262626 yp h25", "")

	inputGui.Add("Text", "BackgroundTrans Section xs", "Potion: ")
	potionButtonEdit := inputGui.Add("Edit", "vPotionButton yp" . EDIT_STYLE, "{Numpad2}")
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
	; Food Duration in Minutes = 5 * (buff type from 1 to 4) + 25

	progressBar := inputGui.Add("Progress", "xp x30 y315 w650 Background262626 cA3CC43 Border Smooth", 0)
	completionTimeText := inputGui.Add("Text", "xp w375 Background262626", "Completion Time: 0")
	foodTimeText := inputGui.Add("Text", "yp w200 Background262626",   "Food   Refresh Time: 0")
	potionTimeText := inputGui.Add("Text", "xp w200 Background262626", "Potion Refresh Time: 0")

	; Bottom Section
	killOnComplete := inputGui.Add("CheckBox", "vKillOnComplete xp x30 y385 Background262626", "Close FFXIV when Complete?")

	startButton := inputGui.Add("Button", "Section Default w100 h64 xp", "Start Autocraft")
	startButton.OnEvent("Click", ffxivAutocraft)
	cancelButton := inputGui.Add("Button", "w100 h57 xp +Disabled", "Cancel`nAutocraft")
	cancelButton.OnEvent("Click", cancelAutocraft)
	infoLog  := inputGui.Add("Edit", "ys ReadOnly Background262626 r6 w550", "Welcome to the Auto Craft Companion!")

	; Optional editable key binds
	inputGui.Add("Text", "BackgroundTrans Section xp x30", "FFXIV System Confirm Keybind:")
	ffxivConfirmEdit := inputGui.Add("Edit", "vFFXIVConfirm yp Center" . EDIT_STYLE . "w100", "{Numpad0}")
	inputGui.Add("Text", "BackgroundTrans xs", "FFXIV System CloseUI Keybind:")
	ffxivCloseUiEdit := inputGui.Add("Edit", "vFFXIVCloseUI yp Center" . EDIT_STYLE . "w100", "{Esc}")
	inputGui.Add("Text", "BackgroundTrans ys", "FFXIV Craft Menu Keybind:")
	ffxivCraftMenuEdit := inputGui.Add("Edit", "vFFXIVCraftMenu yp Center" . EDIT_STYLE . "w100", "N")

	updatePreferencesDropDown(true) ; Load the whole gui before we try setting anything

	completionTime := ""
	macroDurationSeconds := 0
	memento := ""
	foodRefreshDate := ""
	potRefreshDate := ""
	isCancelled := false
	ffxivWindowPos := {}
	autocraftWindowPos := {}

	OnMessage(0x0201, (*) => PostMessage(0x00A1, 2, 0, inputGui)) ; Move the Gui while the left mouse button is down
	inputGui.Show()
	WinSetAlwaysOnTop 1, PROGRAM_TITLE

	log("Be sure to be in the starting position before crafting.")

	; Callback function when the Main Gui is finished
	ffxivAutocraft(*) {
		memento := inputGui.Submit(false) ; Do not hide the window when start is hit
		isCancelled := false
		startButton.Opt("+Disabled")
		cancelButton.Opt("-Disabled")

		; Allow the crafting to run asynchronously
		SetTimer(crafting, 1)
	}

	crafting() {
		SetKeyDelay FFXIV_INPUT_DELAY

		; Get window Positions
		WinGetPos &X, &Y, &W, &H, FFXIV_PROGRAM_NAME
		ffxivWindowPos := {X: X, Y: Y, W: W, H: H}
		WinGetPos &X, &Y, &W, &H, PROGRAM_TITLE
		autocraftWindowPos := {X: X, Y: Y, W: W, H: H}

		craftsCompleted := 0
		progressBar.Value := 0

		; Don't do date math if we don't need to
		foodRefreshDate := memento.FoodEnabled ? DateAdd(A_Now, memento.FoodDuration * 60, "Seconds") : 0
		potRefreshDate := memento.PotionEnabled ? DateAdd(A_Now, memento.PotionDuration * 60, "Seconds") : 0

		; TODO: This is still not accurate
		; Calculate completion time
		idealMacroDurationSec := (memento.Macro1Duration + FFXIV_ACTION_DELAY/1000 + memento.Macro2Duration * memento.Macro2Enabled) * memento.NumOfCrafts
		numOfFoodNeeded := memento.FoodEnabled ? idealMacroDurationSec / foodDurationSec() : 0
		numOfPotionsNeeded := memento.FoodEnabled ? idealMacroDurationSec / 900  : 0 ; Potions always last 15 minutes = 900 seconds
		refreshFoodDelaySec := (FFXIV_ACTION_DELAY/1000 * 3 + FFXIV_CONSUMABLE_DELAY/1000) * numOfFoodNeeded
		refreshPotionDelaySec := (FFXIV_ACTION_DELAY/1000 * 3 + FFXIV_CONSUMABLE_DELAY/1000) * numOfPotionsNeeded
		macroDurationSeconds := idealMacroDurationSec + refreshFoodDelaySec + refreshPotionDelaySec

		completionTime := DateAdd(A_Now, macroDurationSeconds, "Seconds")
		SetTimer(updateTimers, 1)

		log(Format("Starting Craft Profile: {1}`nBe careful of interacting with FFXIV while the autocraft processes.", memento.ProfileName))

		while (craftsCompleted != memento.NumOfCrafts && !isCancelled) {
			consumableRefreshed := false

			if (windowMoved(ffxivWindowPos, FFXIV_PROGRAM_NAME) || windowMoved(autocraftWindowPos, PROGRAM_TITLE)) {
				log("Window has moved... resetting cursor")
				ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
			}

			; Check if we need to refresh consumables
			if (memento.FoodEnabled && DateDiff(A_Now, foodRefreshDate, "Seconds") >= -1) {
				foodRefreshDate := refreshConsumable(ENUM_CONSUMABLE_FOOD, craftsCompleted = 0)
				consumableRefreshed := true
			}

			if (memento.PotionEnabled && DateDiff(A_Now, potRefreshDate, "Seconds") >= -1) {
				potRefreshDate := refreshConsumable(ENUM_CONSUMABLE_POTION, craftsCompleted = 0)
				consumableRefreshed := true
			}

			if (consumableRefreshed && craftsCompleted != 0) {
				; Reset the cursor
				ControlSend(memento.FFXIVCraftMenu, , FFXIV_PROGRAM_NAME)
				Sleep FFXIV_ACTION_DELAY
				ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
				Sleep FFXIV_INPUT_DELAY * 2
			}

			; Start the craft
			log(Format("Starting craft #{1} of {2}", craftsCompleted + 1, numOfCraftsEdit.Value))
			startSynthesis(memento.Macro1Button, memento.Macro2Button)

			if (!isCancelled) {
				progressBar.Value := ++craftsCompleted/numOfCraftsEdit.Value * 100
			}
		}

		if (isCancelled) {
			log("Autocraft cancelled.")
		} else {
			log(Format("{1} crafts of {2} complete! 😊`nPlease reset to the starting position before next autocraft!", craftsCompleted, profilesList.Text))

			if (memento.KillOnComplete) {
				closeFfxiv()
				SetTimer(, 0)
				return
			}
		}

		startButton.Opt("-Disabled")
		cancelButton.Opt("+Disabled")
		SetTimer(, 0)
	}

	startSynthesis(macro1Button, macro2Button) {
		ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
		Sleep FFXIV_ACTION_DELAY / 2
		ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
		; ControlSend("{Numpad6}", , FFXIV_PROGRAM_NAME) ; Trial Synthesis for Testing
		Sleep FFXIV_ACTION_DELAY / 2
		ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)

		Sleep FFXIV_ACTION_DELAY ; Wait for craft window to appear
		ControlSend(macro1Button, , FFXIV_PROGRAM_NAME)
		Sleep memento.Macro1Duration * 1000 + FFXIV_ACTION_DELAY

		if (windowMoved(ffxivWindowPos, FFXIV_PROGRAM_NAME) || windowMoved(autocraftWindowPos, PROGRAM_TITLE)) {
			log("Window has moved... resetting cursor")
			ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
		}

		if (memento.Macro2Enabled && !isCancelled) {
			ControlSend(macro2Button, , FFXIV_PROGRAM_NAME)
			Sleep memento.Macro2Duration * 1000 + FFXIV_ACTION_DELAY
		}
	}

	refreshConsumable(consumableType, isOnFirstCraft) {
		if (!isOnFirstCraft) {
			; If we haven't done any crafts yet we can go ahead and refresh the consumable
			ControlSend(memento.FFXIVCloseUI, , FFXIV_PROGRAM_NAME)
			Sleep FFXIV_ACTION_DELAY ; Wait for user to stand up
		}

		if (consumableType = ENUM_CONSUMABLE_FOOD) {
			log("Refreshing food buff")
			ControlSend(memento.FoodButton, , FFXIV_PROGRAM_NAME)
			Sleep FFXIV_CONSUMABLE_DELAY
			return DateAdd(A_Now, (5 * memento.FoodBuff + 25) * 60, "Seconds")
		} else if (consumableType = ENUM_CONSUMABLE_POTION) {
			log("Refreshing potion buff")
			ControlSend(memento.PotionButton, , FFXIV_PROGRAM_NAME)
			Sleep FFXIV_CONSUMABLE_DELAY
			return DateAdd(A_Now, 15 * 60, "Seconds")
		}
	}

	foodDurationSec() {
		return (5 * memento.FoodBuff + 25) * 60
	}

	cancelAutocraft(*) {
		log("Cancelling autocraft... current macro will still execute till completion.")
		isCancelled := true
	}

	windowMoved(windowPos, windowName) {
		WinGetPos &X, &Y, &W, &H, windowName

		; The window has changed in some way, this will mess up the in-game cursor so we need to include an extra click
		; and save the new position
		if (
			X != windowPos.X ||
			Y != windowPos.Y ||
			W != windowPos.W ||
			H != windowPos.H
		) {
			windowPos.X := X
			windowPos.Y := Y
			windowPos.W := W
			windowPos.H := H
			return true
		}
		return false
	}


	; Default behavior is to choose the first option in the list
	updatePreferencesDropDown(resetOption, selectProfile := "") {
		profiles := IniRead(PREFERENCES_FILEPATH,,, 0)
		if (!profiles) {
			; Create the file and save the default settings as a profile
			file := FileOpen(PREFERENCES_FILEPATH, "w")
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
		IniWrite(data.Macro1Button, 	PREFERENCES_FILEPATH, data.ProfileName,	"MACRO_1_BIND")
		IniWrite(data.Macro1Duration,	PREFERENCES_FILEPATH, data.ProfileName,	"MACRO_1_DURATION")
		IniWrite(data.Macro2Button,		PREFERENCES_FILEPATH, data.ProfileName,	"MACRO_2_BIND")
		IniWrite(data.Macro2Duration, 	PREFERENCES_FILEPATH, data.ProfileName,	"MACRO_2_DURATION")
		IniWrite(data.Macro2Enabled, 	PREFERENCES_FILEPATH, data.ProfileName,	"MACRO_2_ENABLED")
		IniWrite(data.NumOfCrafts, 		PREFERENCES_FILEPATH, data.ProfileName, "NUMBER_OF_CRAFTS")
		IniWrite(data.FoodButton, 		PREFERENCES_FILEPATH, data.ProfileName, "FOOD_BIND")
		IniWrite(data.FoodDuration, 	PREFERENCES_FILEPATH, data.ProfileName, "FOOD_TIME_REMAINING")
		IniWrite(data.FoodEnabled, 		PREFERENCES_FILEPATH, data.ProfileName, "FOOD_MACRO_ENABLED")
		IniWrite(data.FoodBuff, 		PREFERENCES_FILEPATH, data.ProfileName, "FOOD_DURATION_BUFFS")
		IniWrite(data.PotionButton, 	PREFERENCES_FILEPATH, data.ProfileName, "POTION_BIND")
		IniWrite(data.PotionDuration, 	PREFERENCES_FILEPATH, data.ProfileName,	"POTION_TIME_REMAINING")
		IniWrite(data.PotionEnabled, 	PREFERENCES_FILEPATH, data.ProfileName, "POTION_MACRO_ENABLED")
		IniWrite(data.KillOnComplete, 	PREFERENCES_FILEPATH, data.ProfileName, "CLOSE_FFXIV_WHEN_DONE")
		IniWrite(data.FFXIVConfirm, 	PREFERENCES_FILEPATH, data.ProfileName, "FFXIV_CONFIRM")
		IniWrite(data.FFXIVCloseUI, 	PREFERENCES_FILEPATH, data.ProfileName, "FFXIV_CLOSE_UI")
		IniWrite(data.FFXIVCraftMenu, 	PREFERENCES_FILEPATH, data.ProfileName, "FFXIV_CRAFT_MENU")
		updatePreferencesDropDown(false, data.ProfileName)
	}

	loadPreferences(*) {
		log(Format("Loading {1} Profile", profilesList.Text))
		profileNameEdit.Value 		:= profilesList.Text
		macro1ButtonEdit.Value		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "MACRO_1_BIND")
		macro1DurationEdit.Value 	:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "MACRO_1_DURATION")
		macro2ButtonEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "MACRO_2_BIND")
		macro2DurationEdit.Value 	:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "MACRO_2_DURATION")
		macro2EnabledCheckbox.Value := IniRead(PREFERENCES_FILEPATH, profilesList.Text, "MACRO_2_ENABLED")
		numOfCraftsEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "NUMBER_OF_CRAFTS")
		foodButtonEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FOOD_BIND")
		foodDurationEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FOOD_TIME_REMAINING")
		foodEnabledCheckbox.Value 	:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FOOD_MACRO_ENABLED")
		foodBuffDropDown.Choose(Number(IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FOOD_DURATION_BUFFS")))
		potionButtonEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "POTION_BIND")
		potionDurationEdit.Value 	:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "POTION_TIME_REMAINING")
		potionEnabledCheckbox.Value := IniRead(PREFERENCES_FILEPATH, profilesList.Text, "POTION_MACRO_ENABLED")
		killOnComplete.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "CLOSE_FFXIV_WHEN_DONE")
		ffxivConfirmEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FFXIV_CONFIRM")
		ffxivCloseUiEdit.Value 		:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FFXIV_CLOSE_UI")
		ffxivCraftMenuEdit.Value 	:= IniRead(PREFERENCES_FILEPATH, profilesList.Text, "FFXIV_CRAFT_MENU")
	}

	deleteProfile(*) {
		log(Format("Deleting {1} Profile", profilesList.Text))
		IniDelete(PREFERENCES_FILEPATH, profilesList.Text)
		updatePreferencesDropDown(true)
	}

	updateTimers() {
		SetTimer(, 1000)

		; Completion Time
		if (macroDurationSeconds < 1 || isCancelled) {
			SetTimer(, 0)
		}

		if (macroDurationSeconds > 60) {
			completionTimeText.Text := Format(
				"Completion Time: {1} ({2} Minutes)",
				FormatTime(completionTime, "hh:mm:ss tt"),
				Round(macroDurationSeconds--/60, 2)
			)
		} else {
			completionTimeText.Text := Format(
				"Completion Time: {1} ({2} Seconds)",
				FormatTime(completionTime, "hh:mm:ss tt"),
				Round(macroDurationSeconds--, 2)
			)
		}

		; Consumable Timers
		if (memento.FoodEnabled) {
			foodTimer := DateDiff(foodRefreshDate, A_Now, "Seconds")
			foodTimeText.Text := Format("Food   Refresh Time: {1}s", foodTimer > 0 ? foodTimer: "0")
		}

		if (memento.PotionEnabled) {
			potTimer := DateDiff(potRefreshDate, A_Now, "Seconds")
			potionTimeText.Text := Format("Potion Refresh Time: {1}s", potTimer > 0 ? potTimer : "0")
		}
	}

	closeFfxiv() {
		; TODO: Move this to a function
		if (windowMoved(ffxivWindowPos, FFXIV_PROGRAM_NAME) || windowMoved(autocraftWindowPos, PROGRAM_TITLE)) {
			log("Window has moved... resetting cursor")
			ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
		}

		; TODO: Change right move to GUI assignment
		WinClose FFXIV_PROGRAM_NAME
		Sleep FFXIV_ACTION_DELAY
		ControlSend("{Numpad6}", , FFXIV_PROGRAM_NAME) ; Move to ok
		ControlSend(memento.FFXIVConfirm, , FFXIV_PROGRAM_NAME)
	}

	log(text, addToLastLine := false) {
		if (addToLastLine) {
			infoLog.Value := infoLog.Value . " " . text
		} else {
			infoLog.Value := infoLog.Value . '`n' . Format("[{1}] {2}", FormatTime(A_Now, "hh:mm:ss tt"), text)
		}

		; Scroll to the bottom without interrupting the user
		SendMessage(0x0115, 7, 0, infoLog, PROGRAM_TITLE) ; 0x115 is WM_VSCROLL - 7 is SB_BOTTOM
	}
}

