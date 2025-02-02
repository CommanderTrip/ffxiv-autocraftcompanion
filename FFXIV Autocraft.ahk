#Requires AutoHotkey v2.0
#HotIf WinActive("FINAL FANTASY XIV")

/*
Usage:
	Intended to be a fully AFK macro for FFXIV. Set FFXIV to windowed mode, move it to another monitor, then do not touch it.
	Macro will take control when needed so you can continue to use your PC <-- still in testing.

	To make a new hotkey, follow the below examples to by calling "ffxivPenumbraAutoCraft" with the duration in seconds of your macro
	and the title you'd like. Then click into FFXIV, move your cursor over the "Synthesize" button of the craft, and hit the macro hotkey!
*/

NUM_OF_CRAFTS := 2
FFXIV_CRAFT_BUTTON := "V"

; Right Shift + C
>+c::
{
	; Assumed to be 28 steps (13 -- /micon and /nextmacro -- + 15)
	; each with 3 seconds of wait time for each step
	ffxivPenumbraAutoCraft(84, "Worst-case, Two-step Macro with Penumbra Active")
}

; Right Ctrl + C
>^c::
{
	; Assumed to be 15 steps each with 3 seconds of wait time for each step
	ffxivPenumbraAutoCraft(45, "Worst-case, One-step Macro with Penumbra Active")
}

; Right Shift + M. Timing tailored to the "Moqueca" macro with Penumbra active
>+m::
{
	ffxivPenumbraAutoCraft(55, "Moqueca")
}

; singleCraftDuration - time in seconds for a single craft
ffxivPenumbraAutoCraft(singleCraftDuration, msgBoxTitle) {
	killOnCompletion := false
	macroDuration := singleCraftDuration * NUM_OF_CRAFTS
	MouseGetPos &ffxivXPos, &ffxivYPos

	response := displayMacroCraftTime(macroDuration, msgBoxTitle)
	if (response = "No")
		return
	else if (response = "Cancel")
		killOnCompletion := true

	Loop NUM_OF_CRAFTS {
		MouseGetPos &userXPos, &userYPos
		ffxivClickSynthesize(ffxivXPos, ffxivYPos, userXPos, userYPos)
		Sleep singleCraftDuration * 1000
	}

	; NOT FULLY TESTED
	if (killOnCompletion = true) {
		BlockInput true
		WinActivate "FINAL FANTASY XIV"
		WinGetPos ,,&W,&H, "A"
		WinClose "FINAL FANTASY XIV"
		MouseMove W/2 - 10, H/2 ; Move the cursor to confirm exit
		Click "Down"
		Sleep 25
		Click "Up"
		Sleep 25
		BlockInput false
	}

	MsgBox(
		Format(
			"Your {1} crafts of {2} are done! 😊",
			NUM_OF_CRAFTS, msgBoxTitle
		),
		"Done!",
	)
}

; Spaces the press and release because "Click" seems to be too fast.
; Now minimizes taking control from the user
ffxivClickSynthesize(ffxivXPos, ffxivYPos, userXPos, userYPos) {

	; Take control from user
	BlockInput true
	WinActivate "FINAL FANTASY XIV"
	Sleep 50
	MouseMove ffxivXPos, ffxivYPos
	Click "Down"
	Sleep 25
	Click "Up"
	Sleep 25

	; Restore control briefly
	MouseMove userXPos, userYPos
	BlockInput false

	Sleep 1000 ; Wait for craft window to appear

	; Take Control again
	BlockInput true
	WinActivate "FINAL FANTASY XIV"
	Sleep 50
	Send FFXIV_CRAFT_BUTTON

	; Restore control
	MouseMove userXPos, userYPos
	BlockInput false
}

; Duration in seconds
displayMacroCraftTime(macroDuration, msgBoxTitle){
	completionTime := DateAdd(A_Now, macroDuration, "Seconds")
	return response := MsgBox(
		Format(
			"Your {1} crafts will complete at {2} ({3} minutes).`nWould you like to continue?`n(cancel means to close FFXIV after crafts complete)",
			NUM_OF_CRAFTS, FormatTime(completionTime, "h:m:ss tt"), Round(macroDuration/60, 2)
		),
		msgBoxTitle,
		0x23 ; YesNoCancel AND Question Icon
	)
}
