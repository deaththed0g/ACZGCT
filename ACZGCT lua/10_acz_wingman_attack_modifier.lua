{$lua}

--[[
==========================================================================
==== ACE COMBAT ZERO: THE UNSUNG WAR - WINGMAN ATTACK MODIFIER SCRIPT ====
==========================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v260326
]]

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- Retrieve Table of Contents of a container file.
local function retrieve_toc(base_address)

	local table_name = {}
	local n = readBytes(base_address, 1)

	for i = 1, n do

		table_name[#table_name + 1] = base_address + (readInteger(base_address + (i * 4)))

	end

	return table_name
end

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

-- Wingman attack modifier function
function ACZadjustWingmanAttack_outSortieCheck(ACZadjustWingmanAttack_outSortieCheckTimer)

	-- Execute function while PCSX2 is up.
	if readInteger(EERAMver_ACZadjustWingmanAttack[2]) ~= nil then

		-- Check if the player is NOT in a multiplayer match.
		if readBytes(EERAMver_ACZadjustWingmanAttack[2] + 0x3ACEA0, 1) == 13 then

			--If the player is currently in a mission, modify data.
			if (readBytes(EERAMver_ACZadjustWingmanAttack[2] + 0x3FFD1C, 1) == 3) and (readSmallInteger(EERAMver_ACZadjustWingmanAttack[2] + 0x7651A8) <= 1) then

				-- Pause "outer" timer
				ACZadjustWingmanAttack_outSortieCheckTimer.enabled = false

				-- Empty this script's main global table for reuse.
				for k, v in pairs(ACZadjustWingmanAttack_dataList) do ACZadjustWingmanAttack_dataList[k] = nil end

				-- Scan for the file asset's address containing the current wingman's parameters.
				local ACZ_wingmanDat = memscan_func(soExactValue, vtByteArray, nil, "08 00 00 00 30 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00", nil, EERAMver_ACZadjustWingmanAttack[2] + 0x700000, EERAMver_ACZadjustWingmanAttack[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

				-- Extract ToC from said file then get the wingman's attack parameter data.
				-- Back up said data.
				local dat_file_toc = retrieve_toc(ACZ_wingmanDat[1])
				ACZadjustWingmanAttack_dataList[#ACZadjustWingmanAttack_dataList + 1] = dat_file_toc[5]
				ACZadjustWingmanAttack_dataList[#ACZadjustWingmanAttack_dataList + 1] = readBytes(dat_file_toc[5], 0xC0, true)

				-- Write custom attack parameters.
				writeBytes(dat_file_toc[5], {0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x7A, 0x44, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9A, 0x99, 0x19, 0x3E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9A, 0x99, 0x99, 0x3E, 0xCD, 0xCC, 0x1C, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x0F, 0x00, 0x00, 0x01, 0x0C, 0x2D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0xC8, 0x44, 0x00, 0x80, 0x3B, 0x45, 0x00, 0x00, 0x80, 0x3F, 0xCD, 0xCC, 0xCC, 0x3D, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x42, 0x00, 0x00, 0x00, 0x00, 0xCD, 0xCC, 0x1C, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE8, 0x03, 0x00, 0x00, 0x02, 0x28, 0x1E, 0x00, 0x00, 0x00, 0x00, 0x00})

				-- Scan for the current wingman's altitude limit value's address.
				local ACZadjustWingmanAttack_IFF = {"CC CC 4C 42 70 69 78 79", "CC CC 4C 42 70 6A"}

				for i = 1, #ACZadjustWingmanAttack_IFF do

					local tempScan = memscan_func(soExactValue, vtByteArray, nil, ACZadjustWingmanAttack_IFF[i], nil, EERAMver_ACZadjustWingmanAttack[2] + 0x700000, EERAMver_ACZadjustWingmanAttack[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

					if #tempScan ~= 0 then

						for i = 1, #tempScan do

							-- Back up default value + address.
							ACZadjustWingmanAttack_dataList[#ACZadjustWingmanAttack_dataList + 1] = tempScan[i] - 0x18C
							ACZadjustWingmanAttack_dataList[#ACZadjustWingmanAttack_dataList + 1] = readBytes(tempScan[i] - 0x18C, 4, true)

							-- Write new minimum altitude limit value.
							writeFloat(tempScan[i] - 0x18C, 1025.0)

						end

					end

				end

				-- Create a function to check if player IS currently in a mission.
				function ACZadjustWingmanAttack_inSortieCheck(ACZadjustWingmanAttack_inSortieCheckTimer)

					-- Exit script if the emulator closes abruptly.
					if readInteger(EERAMver_ACZadjustWingmanAttack[2]) ~= nil then

						-- Stop "inner" timer, clear flag value and resume the "outer" timer.
						if readBytes(EERAMver_ACZadjustWingmanAttack[2] + 0x3FFD1C, 1) ~= 3 then

							ACZadjustWingmanAttack_inSortieCheckTimer.enabled = false

							ACZadjustWingmanAttack_outSortieCheckTimer.enabled = true

						end

					else

						-- Self disable script on emulator crash or exit.
						getAddressList().getMemoryRecordByDescription("Wingman attack modifier").Active = false

					end

				end

				-- Start "in-mission" checker function.
				if ACZadjustWingmanAttack_inSortieCheck_Timer == nil then

					ACZadjustWingmanAttack_inSortieCheck_Timer = createTimer()
					ACZadjustWingmanAttack_inSortieCheck_Timer.Interval = 300
					ACZadjustWingmanAttack_inSortieCheck_Timer.onTimer = ACZadjustWingmanAttack_inSortieCheck
					ACZadjustWingmanAttack_inSortieCheck_Timer.Enabled = true

					unpause(getOpenedProcessID())

				else

					ACZadjustWingmanAttack_inSortieCheck_Timer.Enabled = true

					unpause(getOpenedProcessID())

				end

			end

		end

	else

		-- Self disable script on emulator crash or exit.
		getAddressList().getMemoryRecordByDescription("Wingman attack modifier").Active = false

	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EERAMver_ACZadjustWingmanAttack = pcsx2_version_check()

if (EERAMver_ACZadjustWingmanAttack[3] == nil) then

	-- Check if the emulator has the right game loaded.
	   local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZadjustWingmanAttack[2] + 0x300000, EERAMver_ACZadjustWingmanAttack[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	   if #SLUS_21346_check ~= 0 then

		-- If the "[ACZGCT] WINGMAN: engagement range mod" is not enabled suggest the user to enable it.
		if readInteger(EERAMver_ACZadjustWingmanAttack[2] + 0x3FAAAC) ~= 1198522368 then

			showMessage("<< You might want to enable the [[ACZGCT] WINGMAN: engagement range modifier] cheat. >>")

		end

		-- Activate script if all checks were successfully passed.
		IsACZadjustWingmanAttackEnabled = true

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EERAMver_ACZadjustWingmanAttack[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EERAMver_ACZadjustWingmanAttack[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EERAMver_ACZadjustWingmanAttack[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZadjustWingmanAttackEnabled then

	-- Initialize a table to backup data so it can be restored on deactivation.
	ACZadjustWingmanAttack_dataList = {}

	-- Create a function check if the player is NOT in a mission.
	ACZadjustWingmanAttack_outSortieCheck_Timer = createTimer()
	ACZadjustWingmanAttack_outSortieCheck_Timer.Interval = 300
	ACZadjustWingmanAttack_outSortieCheck_Timer.onTimer = ACZadjustWingmanAttack_outSortieCheck
	ACZadjustWingmanAttack_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZadjustWingmanAttackEnabled then

	if ACZadjustWingmanAttack_inSortieCheck_Timer ~= nil then

		ACZadjustWingmanAttack_inSortieCheck_Timer.destroy()
		ACZadjustWingmanAttack_inSortieCheck_Timer = nil

	end

	if ACZadjustWingmanAttack_outSortieCheck_Timer ~= nil then

		ACZadjustWingmanAttack_outSortieCheck_Timer.destroy()
		ACZadjustWingmanAttack_outSortieCheck_Timer = nil

	end

	if readInteger(EERAMver_ACZadjustWingmanAttack[2]) ~= nil then

		if readBytes(EERAMver_ACZadjustWingmanAttack[2] + 0x3FFD1C, 1) == 3 then

			for i = 1, #ACZadjustWingmanAttack_dataList, 2 do

				writeBytes(ACZadjustWingmanAttack_dataList[i], ACZadjustWingmanAttack_dataList[i + 1])

			end

		end

	end

	ACZadjustWingmanAttack_dataList = nil
	IsACZadjustWingmanAttackEnabled = nil

end

EERAMver_ACZadjustWingmanAttack = nil