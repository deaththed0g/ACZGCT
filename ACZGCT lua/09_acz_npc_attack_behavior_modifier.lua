{$lua}

--[[
===============================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - NPC ATTACK BEHAVIOR MODIFIER SCRIPT ====
===============================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v270426
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

end

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

-- NPC attack behavior modifier function
function ACZnpcAttackModifier_outSortieCheck(ACZnpcAttackModifier_outSortieCheckTimer)

	-- Execute function while PCSX2 is up.
	if readInteger(EEMEMver_ACZnpcAttackModifier[2]) ~= nil then

		-- Check if the player is NOT in a multiplayer match.
		if readBytes(EEMEMver_ACZnpcAttackModifier[2] + 0x3ACEA0, 1) == 13 then

			--If the player is currently in a mission, modify data.
			if (readBytes(EEMEMver_ACZnpcAttackModifier[2] + 0x3FFD1C, 1) == 3) and (readSmallInteger(EEMEMver_ACZnpcAttackModifier[2] + 0x7651A8) <= 1) then

				-- Pause function and app.
				ACZnpcAttackModifier_outSortieCheckTimer.enabled = false

				-- Scan for the address containing the current mission's logic file asset.
				local ACZnpcAttackModifier_tbl = memscan_func(soExactValue, vtByteArray, nil, "1800000070000000????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????10000000200000000000000000000000000000000000000000000000000000000500000020000000????????????????", nil, EEMEMver_ACZnpcAttackModifier[2] + 0x700000, EEMEMver_ACZnpcAttackModifier[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

				-- Clear table for reuse.
				for k, v in pairs(ACZnpcAttackModifier_dataList) do ACZnpcAttackModifier_dataList[k] = nil end

				for i = 1, #ACZnpcAttackModifier_tbl do

					-- Get entity ToC from file.
					local main_file_toc = retrieve_toc(ACZnpcAttackModifier_tbl[i])
					local mission_file_toc = retrieve_toc(main_file_toc[1] + 0x20)
					local entity_file_toc = retrieve_toc(mission_file_toc[1] + 0x20)

					for i = 1, #entity_file_toc do

						if i ~= 1 then

							local current_entities_group = retrieve_toc(entity_file_toc[i] + 0x50)

							for i = 1, #current_entities_group do

								if readBytes(current_entities_group[i], 4) ~= 0 then

									if i == 1 then

										local current_script_toc = retrieve_toc(current_entities_group[1] + 0x50)

										for i = 1, #current_script_toc do

											-- Uncomment these if they are causing issues!
											-- Engagement range
											if readInteger(current_script_toc[i] + 0x10) == 2 then

												ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_script_toc[i] + 0x60
												ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_script_toc[i] + 0x60, 4, true)

												writeFloat(current_script_toc[i] + 0x60, 61440.0) -- Increase engagement range
												--writeBytes(current_script_toc[i] + 0x7B, {0x0, 0xFF, 0xFF}) -- Change "attack entity" flags so they will attack any enemy instead of attacking the ones dictated by its script data.

											end

										end

									else

										local current_entity_properties = retrieve_toc(current_entities_group[i] + 0xE0)

										-- Attack flags?
										if readInteger(current_entity_properties[3]) ~= 0 then

											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[3] + 0x10
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[3] + 0x10, 0x10, true)

											for i = 1, 16 do

												writeBytes(current_entity_properties[3] + 0x10 + ((i * 1) - 1), 100)

											end

										end

										-- Gun attack parameters
										if readInteger(current_entity_properties[4]) ~= 0 then

											-- Attack interval
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[4] + 0x30
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[4] + 0x30, 4, true)
											writeFloat(current_entity_properties[4] + 0x30, 3)

											-- Fire rate
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[4] + 0x34
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[4] + 0x34, 4, true)
											writeFloat(current_entity_properties[4] + 0x34, 0.15)

											-- Attack duration
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[4] + 0x38
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[4] + 0x38, 4, true)
											writeFloat(current_entity_properties[4] + 0x38, 1.5)

											-- Fire spread
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[4] + 0x40
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[4] + 0x40, 4, true)
											writeFloat(current_entity_properties[4] + 0x40, 0.3)

											-- Damage per round
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[4] + 0x59
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[4] + 0x59, 1, true)
											writeBytes(current_entity_properties[4] + 0x59,	 8)

										end

										-- Missile attack parameters
										if readInteger(current_entity_properties[5]) ~= 0 then

											-- Missile attack interval
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[5] + 0x2C
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[5] + 0x2C, 4, true)
											writeFloat(current_entity_properties[5] + 0x2C, 0.5)

											-- Missile attack duration
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[5] + 0x30
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[5] + 0x30, 4, true)
											writeFloat(current_entity_properties[5] + 0x30, 14.0)

											-- Missile launch rate
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[5] + 0x34
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[5] + 0x34, 4, true)
											writeFloat(current_entity_properties[5] + 0x34, 4.0)

											-- Missile accuracy
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = current_entity_properties[5] + 0x3C
											ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(current_entity_properties[5] + 0x3C, 4, true)
											writeFloat(current_entity_properties[5] + 0x3C, 40.0)

										end

									end

								end

							end

						end

					end

				end

				-- //[ALTITUDE LIMITS]
				-- Remove altitude limits for all NPCs, including wingmen.

				-- TODO:
				-- I should find a way to read the terrain 3D model data and set its highest point as the minimum altitude limit value
				-- to prevent the wingman from clipping on the ground.
				-- Not all maps have the same elevation.

				-- Scan for the address of the entities that are currently active in the mission.
				local ACZnpcAttackModifier_altitudeLimits = memscan_func(soExactValue, vtByteArray, nil, "CC CC 4C 42", nil, EEMEMver_ACZnpcAttackModifier[2] + 0x800000, EEMEMver_ACZnpcAttackModifier[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

				for i = 1, #ACZnpcAttackModifier_altitudeLimits do

					-- Store current altitude limit values.
					ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = ACZnpcAttackModifier_altitudeLimits[i] - 0x18C
					ACZnpcAttackModifier_dataList[#ACZnpcAttackModifier_dataList + 1] = readBytes(ACZnpcAttackModifier_altitudeLimits[i] - 0x18C, 4, true)

					-- Filter garbage data/non-active entities.
					if readFloat(ACZnpcAttackModifier_altitudeLimits[i] - 0x18C) > 1.0 or ACZnpcAttackModifier_altitudeLimits[i] - 0x18C < 51200.0 then

						-- Write new limit value.
						writeFloat(ACZnpcAttackModifier_altitudeLimits[i] - 0x18C, 1025.0)

					end

				end

				-- Create a function to check if player IS currently in a mission.
				function ACZnpcAttackModifier_inSortieCheck(ACZnpcAttackModifier_inSortieCheckTimer)

					-- Run function as long the emulator is up.
					if readInteger(EEMEMver_ACZnpcAttackModifier[2]) ~= nil then

						-- Stop "in-mission" checker function if the player is out of the mission.
						if readBytes(EEMEMver_ACZnpcAttackModifier[2] + 0x3FFD1C, 1) ~= 3 then

							ACZnpcAttackModifier_inSortieCheckTimer.enabled = false

							ACZnpcAttackModifier_outSortieCheckTimer.enabled = true

						end

					else

						-- Deactivate script on emulator crash or exit.
						getAddressList().getMemoryRecordByDescription("NPC attack behavior modifier").Active = false

					end

				end

				-- Create a function to check if the game is in a mission.
				-- Reuse active timer if any.
				if ACZnpcAttackModifier_inSortieCheck_Timer == nil then

					ACZnpcAttackModifier_inSortieCheck_Timer = createTimer()
					ACZnpcAttackModifier_inSortieCheck_Timer.Interval = 300
					ACZnpcAttackModifier_inSortieCheck_Timer.onTimer = ACZnpcAttackModifier_inSortieCheck
					ACZnpcAttackModifier_inSortieCheck_Timer.Enabled = true

				else

					ACZnpcAttackModifier_inSortieCheck_Timer.Enabled = true

				end

			end

		end

	else

		-- Deactivate script on emulator crash or exit.
		getAddressList().getMemoryRecordByDescription("NPC attack behavior modifier").Active = false

	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EEMEMver_ACZnpcAttackModifier = pcsx2_version_check()

if (EEMEMver_ACZnpcAttackModifier[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EEMEMver_ACZnpcAttackModifier[2] + 0x300000, EEMEMver_ACZnpcAttackModifier[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_21346_check ~= 0 then

		-- Proceed with the rest of the script if every check was passed.
		IsACZnpcAttackModifierEnabled = true

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EEMEMver_ACZnpcAttackModifier[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EEMEMver_ACZnpcAttackModifier[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EEMEMver_ACZnpcAttackModifier[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZnpcAttackModifierEnabled then

	-- Initialize a table to store addresses and values.
	ACZnpcAttackModifier_dataList = {}

	-- Create a function check if the player is NOT in a mission.
	ACZnpcAttackModifier_outSortieCheck_Timer = createTimer()
	ACZnpcAttackModifier_outSortieCheck_Timer.Interval = 300
	ACZnpcAttackModifier_outSortieCheck_Timer.onTimer = ACZnpcAttackModifier_outSortieCheck
	ACZnpcAttackModifier_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and tables on script deactivation.
if IsACZnpcAttackModifierEnabled then

	if ACZnpcAttackModifier_inSortieCheck_Timer ~= nil then

		ACZnpcAttackModifier_inSortieCheck_Timer.destroy()
		ACZnpcAttackModifier_inSortieCheck_Timer = nil

	end

	if ACZnpcAttackModifier_outSortieCheck_Timer ~= nil then

		ACZnpcAttackModifier_outSortieCheck_Timer.destroy()
		ACZnpcAttackModifier_outSortieCheck_Timer = nil

	end

	if readInteger(EEMEMver_ACZnpcAttackModifier[2]) ~= nil then

		if readBytes(EEMEMver_ACZnpcAttackModifier[2] + 0x3FFD1C, 1) ~= 255 then

			for i = 1, #ACZnpcAttackModifier_dataList, 2 do

				writeBytes(ACZnpcAttackModifier_dataList[i], ACZnpcAttackModifier_dataList[i + 1])

			end

		end

	end

	ACZnpcAttackModifier_dataList = nil
	IsACZnpcAttackModifierEnabled = nil

end

EEMEMver_ACZnpcAttackModifier = nil