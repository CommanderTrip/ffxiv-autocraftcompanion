#Requires AutoHotkey v2.0
; #HotIf WinActive("FINAL FANTASY XIV")

FFXIV := "FINAL FANTASY XIV"
PROGRAM_TITLE := "Auto Craft Companion"
PREFERENCES_FILEPATH 	:= "./bin/ffxiv_auto_craft_companion_profiles.ini"
ASSETS_PATH := "./bin/assets/"
HEADING_TEXT_STYLE		:= "cCCCCCC s16 q0 w700"
SUBHEADING_TEXT_STYLE	:= "c828282 s12 q0 w400"
BODY_TEXT_STYLE 		:= " cCCCCCC s12 q0 w400 "
EDIT_STYLE 				:= " cCCCCCC Background262626 Center Border w175 "
SMALL_EDIT_STYLE 		:= " cCCCCCC Background262626 Center Border w30 "

MARGIN_TOP  := " y20 "
MARGIN_LEFT := " x30 "

FFXIV_ACTION_DELAY := 1200 ; in milliseconds
FFXIV_CONSUMABLE_DELAY := 1500 ; in milliseconds

; TODO: Allow these to be set in the GUI
FFXIV_CONFIRM_KEYBIND := "{Numpad0}"
FFXIV_CRAFT_MENU_KEYBIND := "{N}"
FFXIV_CLOSE_UI_KEYBIND := "{Escape}"

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
	inputGui.Add("Picture","w700 h550", ASSETS_PATH . "bg.png")

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
	inputGui.Add("Picture", "BackgroundTrans w650 xs", ASSETS_PATH . "bar.png")

	; MACROS
	inputGui.SetFont(SUBHEADING_TEXT_STYLE, "Meiryo")
	inputGui.Add("Text", "BackgroundTrans Section", "Macro Key and Duration in Seconds")
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
	inputGui.Add("Text", "BackgroundTrans ys Section", "Consumables and Time Remaining")
	inputGui.Add("Picture", "BackgroundTrans xp w315", ASSETS_PATH . "bar.png")

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
	; Food Duration in Minutes = 5 * (buff type from 1 to 4) + 25

	progressBar := inputGui.Add("Progress", "xp x30 y315 w650 Background262626 cA3CC43 Border Smooth", 0)
	completionTimeText := inputGui.Add("Text", "xp w375 Background262626", "Completion Time: 0")
	foodTimeText := inputGui.Add("Text", "yp w200 Background262626",   "Food   Refresh Time: 0")
	potionTimeText := inputGui.Add("Text", "xp w200 Background262626", "Potion Refresh Time: 0")

	; Bottom Section
	killOnComplete := inputGui.Add("CheckBox", "vKillOnComplete xp x30 y385 Background262626", "Close FFXIV when Complete?")

	startButton := inputGui.Add("Button", "Section Default w100 h64 xp", "Start Autocraft")
	startButton.OnEvent("Click", ffxivPenumbraAutoCraft)
	inputGui.Add("Button", "w100 h57 xp", "Save`nProfile").OnEvent("Click", savePreferences)
	infoLog  := inputGui.Add("Edit", "ys ReadOnly Background262626 r6 w550", "Welcome to the Auto Craft Companion!")

	updatePreferencesDropDown(true) ; Load the whole gui before we try setting anything

	completionTime := ""
	macroDuration := ""
	craftsCompleted := 0
	singleCraftDuration := 0
	memento := ""
	foodRefreshDate := ""
	potRefreshDate := ""

	SetKeyDelay 50
	OnMessage(0x0201, (*) => PostMessage(0x00A1, 2, 0, inputGui)) ;Move the Gui while the left mouse button is down
	inputGui.Show()

	; Callback function when the Main Gui is finished
	ffxivPenumbraAutoCraft(*) {

		memento := inputGui.Submit(false) ; Do not hide the window when start is hit
		log(Format("Starting Craft Profile: {1}", memento.ProfileName))

		craftsCompleted := 0
		singleCraftDuration := memento.Macro1Duration + memento.Macro2Duration * memento.Macro2Enabled
		macroDuration := singleCraftDuration * memento.NumOfCrafts

		; Don't do date math if we don't need to
		foodRefreshDate := memento.FoodEnabled ? DateAdd(A_Now, memento.FoodDuration * 60, "Seconds") : 0
		potRefreshDate := memento.PotionEnabled ? DateAdd(A_Now, memento.PotionDuration * 60, "Seconds") : 0

		; TODO: This time is not precise
		completionTime := DateAdd(A_Now, macroDuration, "Seconds")

		; Start Timers
		SetTimer(updateTimers, 1)
		SetTimer(craftingLoop, 1)
	}

	craftingLoop() {
		; Finished the crafts
		if (craftsCompleted = numOfCraftsEdit.Value) {
			SetTimer(, 0)
			progressBar.Value := 100
			log(Format("{1} crafts of {2} complete! 😊", craftsCompleted, profilesList.Text))
			closeFfxiv(memento.KillOnComplete)
			return
		}

		; Set the timer sleep based on the actions we will need to perform
		; TODO: Should there be a buffer for the refresh?
		; the current time is 1 second before the refresh time
		needFoodRefresh := memento.FoodEnabled ? DateDiff(A_Now, foodRefreshDate, "Seconds") >= -1 : 0
		needPotionRefresh := memento.PotionEnabled ? DateDiff(A_Now, potRefreshDate, "Seconds") >= -1 : 0

		SetTimer(, (singleCraftDuration + FFXIV_ACTION_DELAY/1000 * 2 + FFXIV_CONSUMABLE_DELAY/1000 * (needPotionRefresh*2 + needFoodRefresh*2)) * 1000)

		; Refresh Food
		if (memento.FoodEnabled && needFoodRefresh) {
			log("Refreshing food buff")
			ControlSend(FFXIV_CLOSE_UI_KEYBIND, , FFXIV)
			Sleep FFXIV_CONSUMABLE_DELAY ; Wait for user to stand up
			ControlSend(memento.FoodButton, , FFXIV)
			Sleep FFXIV_CONSUMABLE_DELAY ; Wait for consumable animation to apply buff
			ControlSend(FFXIV_CRAFT_MENU_KEYBIND, , FFXIV)
			foodRefreshDate := DateAdd(A_Now, (5 * memento.FoodBuff + 25) * 60, "Seconds")
		}

		; Refresh Potion
		if (memento.PotionEnabled && needPotionRefresh) {
			log("Refreshing potion buff")
			Sleep 50 ; Not sure why this is needed :(
			ControlSend(FFXIV_CLOSE_UI_KEYBIND, , FFXIV)
			Sleep FFXIV_CONSUMABLE_DELAY ; Wait for user to stand up
			ControlSend(memento.PotionButton, , FFXIV)
			Sleep FFXIV_CONSUMABLE_DELAY ; Wait for consumable animation to apply buff
			ControlSend(FFXIV_CRAFT_MENU_KEYBIND, , FFXIV)
			potRefreshDate := DateAdd(A_Now, 15 * 60, "Seconds")
		}

		log(Format("Starting craft #{1}/{2}",
			craftsCompleted + 1,
			numOfCraftsEdit.Value
		))

		ffxivClickSynthesizeWithoutMouse(memento.Macro1Button, needFoodRefresh || needPotionRefresh)

		progressBar.Value := craftsCompleted++/numOfCraftsEdit.Value * 100
	}

		; The Craft MUST be in your favorites.
		ffxivClickSynthesizeWithoutMouse(macroKey, consumableRefreshed) {
			if (consumableRefreshed) {
				ControlSend(FFXIV_CONFIRM_KEYBIND, , FFXIV)
				ControlSend(FFXIV_CONFIRM_KEYBIND, , FFXIV)
			}

			ControlSend(FFXIV_CONFIRM_KEYBIND, , FFXIV)
			; ControlSend("{Numpad6}", , FFXIV) ; Trial Synthesis for Testing
			ControlSend(FFXIV_CONFIRM_KEYBIND, , FFXIV)

			Sleep FFXIV_ACTION_DELAY ; Wait for craft window to appear
			ControlSend(macroKey, , FFXIV)

			if (memento.Macro2Enabled) {
				Sleep memento.Macro1Duration * 1000
				ControlSend(memento.Macro2Button, , FFXIV)
			}
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
	}

	deleteProfile(*) {
		log(Format("Deleting {1} Profile", profilesList.Text))
		IniDelete(PREFERENCES_FILEPATH, profilesList.Text)
		updatePreferencesDropDown(true)
	}

	updateTimers() {
		SetTimer(, 1000)

		; Completion Time
		if (macroDuration < 1) {
			SetTimer(, 0)
		}

		if (macroDuration > 60) {
			completionTimeText.Text := Format(
				"Completion Time: {1} ({2} Minutes)",
				FormatTime(completionTime, "hh:mm:ss tt"),
				Round(macroDuration--/60, 2)
			)
		} else {
			completionTimeText.Text := Format(
				"Completion Time: {1} ({2} Seconds)",
				FormatTime(completionTime, "hh:mm:ss tt"),
				Round(macroDuration--, 2)
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

	closeFfxiv(killGame) {
		if !killGame {
			return
		}

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

