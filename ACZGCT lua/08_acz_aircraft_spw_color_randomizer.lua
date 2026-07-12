{$lua}

--[[
================================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - AIRCRAFT/SpW/COLOR RANDOMIZER SCRIPT ====
================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
Written and best viewed in Notepad ++.
v010726
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

math.randomseed(os.time()) -- Grab seed

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- Check current version and amount of active instances of PCSX2, set working RAM region.
local function pcsx2_version_check()

	version_id = nil
	pcsx2_id_ram_start = nil
	error_flag = nil
	local process_found = {}

	for processID, processName in pairs(getProcessList()) do

		if processName == "pcsx2.exe" or processName == "pcsx2-qt.exe" then

			process_found[#process_found + 1] = processName
			process_found[#process_found + 1] = processID

		end

	end

	if process_found[1] ~= nil then -- Check if there's an instance of PCSX2 up.

		if #process_found <= 2 then -- If CE is using AutoAttach then check how many instances of PCSX2 are up.

			if (process_found[2] == getOpenedProcessID()) then -- Check if CE is attached to PCSX2.

				-- Set memory region according to the version of the emulator.
				-- Check if there's a game loaded, too.
				if process_found[1] == "pcsx2.exe" then

					version_id = 1
					pcsx2_id_ram_start = getAddress(0x20000000)

					if readInteger(pcsx2_id_ram_start) == nil then

						error_flag = 3

					end

				elseif process_found[1] == "pcsx2-qt.exe" then

					version_id = 2
					pcsx2_id_ram_start = getAddress(readPointer("pcsx2-qt.EEmem"))

					if readInteger(pcsx2_id_ram_start) == 0 then

						error_flag = 3

					end

				end

			else

				error_flag = 1

			end

		else

			error_flag = 2

		end

	else

		error_flag = 1

	end

	return {version_id, pcsx2_id_ram_start, error_flag}

end

-- Memory scanner function
local function memscan_func(scanoption, vartype, roundingtype, input1, input2, startAddress, stopAddress, protectionflags, alignmenttype, alignmentparam, isHexadecimalInput, isNotABinaryString, isunicodescan, iscasesensitive)

	local memory_scan = createMemScan()
	memory_scan.firstScan(scanoption, vartype, roundingtype, input1, input2 ,startAddress ,stopAddress ,protectionflags ,alignmenttype, alignmentparam, isHexadecimalInput, isNotABinaryString, isunicodescan, iscasesensitive)
	memory_scan.waitTillDone()
	local found_list = createFoundList(memory_scan)
	found_list.initialize()
	local address_list = {}

	if (found_list ~= nil) then

		for i = 0, found_list.count - 1 do

			table.insert(address_list, getAddress(found_list[i]))

		end

	end

	found_list.deinitialize()
	found_list.destroy()
	found_list = nil

	return address_list

end

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

end

-- Aircraft/COLOR/SpW randomizer function
function ACZaircraftSpwRandomizer_outSortieCheck(ACZaircraftSpwRandomizer_outSortieCheckTimer)

	-- Check if PCSX2 is up and running. if not, disable script.
	if EERAMver_ACZaircraftSpwRandomizer[2] ~= nil then

		-- Check if the player is NOT in a multiplayer match.
		if readBytes(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3ACEA0, 1) == 13 then

			-- Check if the player is in or out of a sortie by reading a byte at address 0x203AC61C.
			-- If the byte flag is anything other than 0 then it means that the game is currently in a sortie (or loading the assets of it).
			-- This mean that we can proceed with the RNG function.
			if (readBytes(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3AC61C, 1) ~= 0) then

				-- Pause the emulator. This is done to give the script to check for existent items in the table.
				-- Also the whole thing must be done before starting the mission, duh.
				pause(getOpenedProcessID())

				-- Pause the timer that checks if the player is outside of a sortie.
				ACZaircraftSpwRandomizer_outSortieCheckTimer.enabled = false

				-- Draw a number from the RNG function then check if it already exists in the table.
				-- If not repeat until a unused number is drawn.
				while true do

					new_aircraft_value = math.random(0, 35)

					if not value_exists(ACZaircraftSpwRandomizer_aircraftUsed, new_aircraft_value) then

						ACZaircraftSpwRandomizer_aircraftUsed[#ACZaircraftSpwRandomizer_aircraftUsed + 1] = new_aircraft_value

						break

					end

				end

				-- Both the F-15C and F-16C have one extra livery than the usual five available for the rest of the
				-- aircraft roster (STANDARD, MERCENARY, SOLDIER, KNIGHT, SPECIAL). These are the PIXY and PJ colors. So if
				-- the number drawn for the aircraft ID is either 5 (F-15C ID's value) or 10 (F-16C's ID value) set the
				-- MAX limit to 5.
				if (new_aircraft_value == 5) or (new_aircraft_value == 10) then

					new_aircraft_color_value = math.random(0, 5)

				else

					new_aircraft_color_value = math.random(0, 4)

				end

				-- If the "ACZaircraftSpwRandomizer_aircraftUsed" table has 36 numbers stored in it
				-- then clear it and add the last drawn number.
				-- There are 36 playable aircraft in the game in total, btw.
				if #ACZaircraftSpwRandomizer_aircraftUsed == 36 then

					for k, v in pairs(ACZaircraftSpwRandomizer_aircraftUsed) do ACZaircraftSpwRandomizer_aircraftUsed[k] = nil end
					ACZaircraftSpwRandomizer_aircraftUsed[#ACZaircraftSpwRandomizer_aircraftUsed + 1] = new_aircraft_value

				end

				-- Write the drawn values to their respective addresses.
				-- Different gameplay modes have different addresses where the aircraft ID value is read from.

				-- FREE MISSION/FLIGHT mode
				writeShortInteger(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3B9A40, new_aircraft_value) -- aircraft ID
				writeShortInteger(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3B9A50, math.random(0, 2)) -- aircraft SpW ID
				writeShortInteger(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3B9A48, new_aircraft_color_value) -- aircraft COLOR ID

				-- CAMPAIGN/STORY mode
				writeShortInteger(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3B3AAC, new_aircraft_value) -- aircraft ID
				writeShortInteger(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3B3ABC, math.random(0, 2)) -- aircraft SpW ID
				writeShortInteger(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3B3AB4, new_aircraft_color_value) -- aircraft COLOR ID

				-- Begin the "in-mission" function checker.
				function ACZaircraftSpwRandomizer_inSortieCheck(ACZaircraftSpwRandomizer_inSortieCheckTimer)

					-- Run function as long PCSX2 is up.
					if readInteger(EERAMver_ACZaircraftSpwRandomizer[2]) ~= nil then

						if (readBytes(EERAMver_ACZaircraftSpwRandomizer[2] + 0x3AC61C, 1) == 0) then

							ACZaircraftSpwRandomizer_inSortieCheckTimer.enabled = false

							ACZaircraftSpwRandomizer_outSortieCheckTimer.enabled = true

						end

					else

						-- Disable script on emulator crash or exit.
						getAddressList().getMemoryRecordByDescription("Aircraft/SpW/COLOR randomizer").Active = false

					end

				end

				-- Start the "in-sortie" checker function or unpause if there's a timer object active already.
				-- Resume emulation.
				if ACZaircraftSpwRandomizer_inSortieCheck_Timer == nil then

					ACZaircraftSpwRandomizer_inSortieCheck_Timer = createTimer()
					ACZaircraftSpwRandomizer_inSortieCheck_Timer.Interval = 300
					ACZaircraftSpwRandomizer_inSortieCheck_Timer.onTimer = ACZaircraftSpwRandomizer_inSortieCheck
					ACZaircraftSpwRandomizer_inSortieCheck_Timer.Enabled = true

					unpause(getOpenedProcessID())

				else

					ACZaircraftSpwRandomizer_inSortieCheck_Timer.Enabled = true

					unpause(getOpenedProcessID())

				end

			end

		end

	else

		-- Self disable script on emulator crash or exit.
		getAddressList().getMemoryRecordByDescription("Aircraft/SpW/COLOR randomizer").Active = false

	end

	return

end


-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EERAMver_ACZaircraftSpwRandomizer = pcsx2_version_check()

if (EERAMver_ACZaircraftSpwRandomizer[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZaircraftSpwRandomizer[2] + 0x300000, EERAMver_ACZaircraftSpwRandomizer[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_21346_check ~= 0 then

		-- Enable script if the check was passed.
		IsACZaircraftSpwRandomizerEnabled = true

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EERAMver_ACZaircraftSpwRandomizer[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EERAMver_ACZaircraftSpwRandomizer[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EERAMver_ACZaircraftSpwRandomizer[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZaircraftSpwRandomizerEnabled then

	-- Initialize a table to store backup data, used later for restoration.
	ACZaircraftSpwRandomizer_aircraftUsed = {}

	-- Begin the "out-of-sortie" checker function.
	ACZaircraftSpwRandomizer_outSortieCheck_Timer = createTimer()
	ACZaircraftSpwRandomizer_outSortieCheck_Timer.Interval = 300
	ACZaircraftSpwRandomizer_outSortieCheck_Timer.onTimer = ACZaircraftSpwRandomizer_outSortieCheck
	ACZaircraftSpwRandomizer_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear tables, flags and stray debug breakpoints on script deactivation.
	if ACZaircraftSpwRandomizer_inSortieCheck_Timer ~= nil then

		ACZaircraftSpwRandomizer_inSortieCheck_Timer.destroy()
		ACZaircraftSpwRandomizer_inSortieCheck_Timer = nil

	end

	if ACZaircraftSpwRandomizer_outSortieCheck_Timer ~= nil then

		ACZaircraftSpwRandomizer_outSortieCheck_Timer.destroy()
		ACZaircraftSpwRandomizer_outSortieCheck_Timer = nil

	end

for k, v in pairs(ACZaircraftSpwRandomizer_aircraftUsed) do ACZaircraftSpwRandomizer_aircraftUsed[k] = nil end

IsACZaircraftSpwRandomizerEnabled = nil
EERAMver_ACZaircraftSpwRandomizer = nil