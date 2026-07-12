{$lua}

--[[
============================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - PARTICLE EMITTER MODIFIER SCRIPT ====
============================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v120726
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

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

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

end

-- Particle emitter modifier function
function ACZparticleMod_outSortieCheck(ACZparticleMod_outSortieCheckTimer)

	-- Run function and script as long PCSX2 is up
	if readInteger(EERAMver_ACZparticleMod[2]) ~= nil then

		-- Check if the player is currently in a mission and not in multiplayer mode.
		if readBytes(EERAMver_ACZparticleMod[2] + 0x3ACEA0, 1) == 13 then

			if (readBytes(EERAMver_ACZparticleMod[2] + 0x3FFD1C, 1) == 3) then

				-- Bytearray list:
				---- 1: Particle emitter 1: missile smoke-trail parameters
				---- 2: Particle emitter 2: plane's wing trail parameters
				---- 3: Particle emitter 3: destroyed plane burning debris
				---- 4: Particle emitter 4: destroyed plane burning trail
				---- 5: Particle emitter 5: destroyed plane debris
				---- 6: Particle emitter 6: destroyed plane sparks
				---- 7: Particle emitter 7: feather amount

				local bytearrays_to_search = {
					"00 00 00 00 50 00 00 00 31 00 00 00 ?? ?? ?? 00 ?? ?? ?? 00 ?? ?? ?? 00 ?? ?? ?? ?? 00 ?? ?? ?? ?? ?? ?? FF ?? ?? ?? ?? ?? ?? 0? 0? 00 ?? ?? ?? ?? ?? ?? FF ?? ?? ?? ?? ?? ?? ?? ?? 00 ?0 ?? 4? 08 0? 08 0? 00 02 0? 0? 68 00 08 0A 00 02 03 01 ?? ?? ?? 3? 00 0? 0? 00",
					"00 00 00 00 10 00 00 00 09 00 00 00 ?? ?? ?? 00 00 00 70 42 00 00 ?? 4?",
					"?? 00 00 00 30 00 00 00 4F 00 00 00 ?? ?? ?? 00 15 15 15 00 00 00 ?? 40 08 00 08 06 00 02 04 01 08 00 08 04 00 02 04 01 00 00 ?? ?? 00 00 ?? ?? ?? ?? ?? ?? ?? 00 ?? 00",
					"00 00 00 00 40 00 00 00 02 00 00 00 ?? 00 00 00",
					"00 00 00 00 40 00 00 00 53 00 00 00 ?? ?? ?? 00 ?? ?? ?? 00 ?? ?? ?? ?? 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? 00 00 00 00 00 ?? ?? 00 00 ?? ?? 00 00 ?? ?? ?? 00 00 00 00 00 00 00",
					"00 00 00 00 20 00 00 00 42 00 00 00 ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? ?? 00 00 ?? ?? ?? 00 00 00 00 00 00 00", 
					"40 00 00 00 53 00 00 00 46 3F 35 00 46 3F 35 00"
				}

				ACZparticleMod_outSortieCheckTimer.enabled = false

				-- Scan and retrieve the position of the files containing the particle emitter configuration file.
				local ACZparticleMod_stgFileOffset = memscan_func(soExactValue, vtByteArray, nil, "2? 00 00 00 A0 00 00 00 A0 01 00 00", nil, EERAMver_ACZparticleMod[2] + 0x700000, EERAMver_ACZparticleMod[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

				-- Clear table for use.
				for k, v in pairs(ACZparticleMod_dataList) do ACZparticleMod_dataList[k] = nil end

				for i = 1, #ACZparticleMod_stgFileOffset do

					-- Process particle emitter file ToC.
					local ACZparticleMod_tbl = retrieve_toc(ACZparticleMod_stgFileOffset[i])

					-- For every particle effect being modified, read and store the current particle's configuration.
					-- so it can be used for restoration when disabling the script later.

					-- Particle emitter 1: missile smoke-trail parameters
					local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[1], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

					for i = 1, #tbl do

						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i] + 0x18
						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i] + 0x18, 4, true)

						writeFloat(tbl[i] + 0x18, 6)

					end

					-- Particle emitter 2: plane's wing trail parameters
					local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[2], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

					for i = 1, #tbl do

						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i] + 0x10
						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i] + 0x10, 8, true)

						writeFloat(tbl[i] + 0x14, 110)

					end

					-- Particle emitter 3: destroyed plane burning debris
					local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[3], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

					for i = 1, #tbl do

						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i]
						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i], 56, true)

						writeFloat(tbl[i] + 0x14, 3.5) -- Particle escape speed (lower = faster)
						writeBytes(tbl[i] + 0x26, 0xF) -- Particle texture coordinate
						writeFloat(tbl[i] + 0x28, 500) -- Particle spread radius (higher = further distance)
						writeFloat(tbl[i] + 0x2C, 40) -- Particle size (higher = bigger)
						writeFloat(tbl[i] + 0x30, 0.15) -- I forgot what was this
						writeSmallInteger(tbl[i] + 0x34, 31) -- Particle trail length (higher = lengthier trail)
						writeSmallInteger(tbl[i] + 0x36, 15) -- Particle amount

					end

					-- Particle emitter 4: destroyed plane burning trail
					local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[4], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

					for i = 1, #tbl do

						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i]
						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i], 72, true)

						writeSmallInteger(tbl[i] + 0x28, (readSmallInteger(tbl[i] + 0x28) * 2)) -- Trail length
						writeBytes(tbl[i] + 0x3E, 0xFF) -- Texture coordinate

					end

					-- Particle emitter 5: destroyed plane debris
					local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[5], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

					for i = 1, #tbl do

						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i]
						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i], 72, true)

						writeSmallInteger(tbl[i] + 0x28, (readSmallInteger(tbl[i] + 0x28) * 10)) -- Particle amount
						writeFloat(tbl[i] + 0x2C, 0.5) -- Particle gravity?

					end

					-- Particle emitter 6: destroyed plane sparks
					local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[6], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

					for i = 1, #tbl do

						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i]
						ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i], 40, true)

						writeSmallInteger(tbl[i] + 0xC, (readSmallInteger(tbl[i] + 0xC) * 4)) -- Particle amount
						writeFloat(tbl[i] + 0x14, 3) -- Particle speed release
						writeFloat(tbl[i] + 0x1C, 0.75) -- Particle gravity?

					end

				--[[
					-- Particle emitter 7: feather amount
					if readSmallInteger(EERAMver_ACZparticleMod[2] + 0x3BF740) == 40 then

						local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[7], nil, ACZparticleMod_tbl[21], ACZparticleMod_tbl[21] + (ACZparticleMod_tbl[22] - ACZparticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)

						for i = 1, #tbl do

							ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = tbl[i] + 0x24
							ACZparticleMod_dataList[#ACZparticleMod_dataList + 1] = readBytes(tbl[i], 2, true)

							writeSmallInteger(tbl[i] + 0x24, (readSmallInteger(tbl[i] + 0x24) * 2)) -- Particle amount

						end

					end
				]]

				end

				-- Begin "out-of-mission" function checker.
				function ACZparticleMod_inSortieCheck(ACZparticleMod_inSortieCheckTimer)

					-- Run check  as long the emulator is up.
					if readInteger(EERAMver_ACZparticleMod[2]) ~= nil then

						-- If the player has exited the mission, end this function and return to the stand-by one.
						if (readBytes(EERAMver_ACZparticleMod[2] + 0x3FFD1C, 1) ~= 3) then

							ACZparticleMod_inSortieCheckTimer.enabled = false

							ACZparticleMod_outSortieCheckTimer.enabled = true

						end

					else

						-- Self disable script on emulator crash or exit.on emulator closure.
						getAddressList().getMemoryRecordByDescription("Particle emitter modifier").Active = false

					end

				end

				-- Begin "in-sortie/mission" checker function.
				-- If there's a timer object already created, use that one instead.
				if ACZparticleMod_inSortieCheck_Timer == nil then

					ACZparticleMod_inSortieCheck_Timer = createTimer()
					ACZparticleMod_inSortieCheck_Timer.Interval = 300
					ACZparticleMod_inSortieCheck_Timer.onTimer = ACZparticleMod_inSortieCheck
					ACZparticleMod_inSortieCheck_Timer.Enabled = true

				else

					ACZparticleMod_inSortieCheck_Timer.Enabled = true


				end

			end

		end

	else

		-- Self disable script on emulator crash or exit.
		getAddressList().getMemoryRecordByDescription("Particle emitter modifier)").Active = false

	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EERAMver_ACZparticleMod = pcsx2_version_check()

if (EERAMver_ACZparticleMod[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZparticleMod[2] + 0x300000, EERAMver_ACZparticleMod[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_21346_check ~= 0 then

		-- Proceed with the main block of the script if all checks were passed.
		IsACZparticleModEnabled = true

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EERAMver_ACZparticleMod[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EERAMver_ACZparticleMod[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EERAMver_ACZparticleMod[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZparticleModEnabled then

	-- Initialize a table to backup data for restoration on demand or when exiting the script.
	ACZparticleMod_dataList = {}

	-- Begin stand-by/"mission status" checker script.
	ACZparticleMod_outSortieCheck_Timer = createTimer()
	ACZparticleMod_outSortieCheck_Timer.Interval = 300
	ACZparticleMod_outSortieCheck_Timer.onTimer = ACZparticleMod_outSortieCheck
	ACZparticleMod_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and tables on script deactivation.
if IsACZparticleModEnabled then

	if ACZparticleMod_inSortieCheck_Timer ~= nil then

		ACZparticleMod_inSortieCheck_Timer.destroy()
		ACZparticleMod_inSortieCheck_Timer = nil

	end

	if ACZparticleMod_outSortieCheck_Timer ~= nil then

		ACZparticleMod_outSortieCheck_Timer.destroy()
		ACZparticleMod_outSortieCheck_Timer = nil

	end

	if readInteger(EERAMver_ACZparticleMod[2]) ~= nil then

		if (readBytes(EERAMver_ACZparticleMod[2] + 0x3FFD1C, 1) ~= 255) then

			for i = 1, #ACZparticleMod_dataList, 2 do

				writeBytes(ACZparticleMod_dataList[i], ACZparticleMod_dataList[i + 1])

			end

		end

	end


	ACZparticleMod_dataList = nil
	IsACZparticleModEnabled = nil

end

EERAMver_ACZparticleMod = nil