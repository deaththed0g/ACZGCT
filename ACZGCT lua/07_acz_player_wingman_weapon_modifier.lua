{$lua}

--[[
=================================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - PLAYER/WINGMAN WEAPON MODIFIER SCRIPT ====
=================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v120626
]]

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

ACZplayerWingmanWpn_dataList = {}

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- Create header
local function create_header(header_name, header_appendtoentry, header_options)

	local header_memory_record_name = getAddressList().createMemoryRecord()
	header_memory_record_name.Description = header_name
	header_memory_record_name.isGroupHeader = true

	if header_appendtoentry ~= nil then

		header_memory_record_name.appendToEntry(header_appendtoentry)

	end

	if header_options then

		header_memory_record_name.options = "[moHideChildren, moAllowManualCollapseAndExpand, moManualExpandCollapse]"

	end

	return header_memory_record_name

end

-- Create memory record
local function create_memory_record(base_address, offset_list, vt_list, description_list, append_to_entry)

	for i = 1, #offset_list do

		local memory_record = getAddressList().createMemoryRecord()
		memory_record.Description = description_list[i]
		memory_record.setAddress(base_address + offset_list[i])

		if type(vt_list[i]) == "table" then

			if vt_list [i][1] == vtByteArray then

				memory_record.Type = vtByteArray
				memory_record.Aob.Size = vt_list[i][2]
				memory_record.ShowAsHex = true

			elseif vt_list [i][1] == vtString then

				memory_record.Type = vtString
				memory_record.String.Size = vt_list[i][2]

			end

		else

			memory_record.Type = vt_list[i]

		end

		memory_record.appendToEntry(append_to_entry)

	end

	return

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

-- Player/wingman weapon parameters printer function.
local function generate_mr(dat_base_address, header_name, parent_header_name, val)

	-- Generate ToC from Player/wingman file asset.
	local dat_file_toc = retrieve_toc(dat_base_address)
	local base_address = dat_file_toc[val]

	ACZplayerWingmanWpn_dataList[#ACZplayerWingmanWpn_dataList + 1] = readBytes(base_address, 0x110, true)

	-- Create header.
	local entity_header = create_header(header_name, parent_header_name, true)

	-- Create child records and attach them to the main header.
	local header_list = {"Ammo parameters", "SpW loadout", "GUN parameters", "Missile parameters"}
	local start_offset = {0x0, 0x30, 0x50, 0xB0}
	local offset_list = {{0x18, 0x1A, 0x1B, 0x1C, 0x1D}, {0x14, 0x15, 0x16}, {0x20, 0x24, 0x30, 0x34, 0x38, 0x40, 0x59}, {0x20, 0x24, 0x2C, 0x30, 0x34, 0x3C, 0x59} } local vt_list = { {vtWord, vtByte, vtByte, vtByte, vtByte}, {vtByte, vtByte, vtByte}, {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtByte}, {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtByte} } local description_list = { {"GUN starting amount", "Standard missile starting amount", "SpW 1 starting amount", "SpW 2 starting amount", "SpW 3 starting amount"}, {"SpW slot 1", "SpW slot 2", "SpW slot 3"}, {"Pipper range visibility", "Bullet travel distance", "Attack interval (affects wingman only)", "Fire rate", "Attack duration (affects wingman only)", "Fire dispersion", "Damage"}, {"Lock-on range", "Missile travel distance", "Launch delay (affects wingman only)", "Launch rate 1 (affects wingman only)", "Launch rate 2", "Accuracy", "Damage"}}

	for i = 1, 4 do

		local header = create_header(header_list[i], entity_header, true)
		create_memory_record(base_address + start_offset[i], offset_list[i], vt_list[i], description_list[i], header)

	end

	return

end

-- PCSX2 status checker function.
function ACZplayerWingmanWpn_outSortieCheck(ACZplayerWingmanWpn_outSortieCheckTimer)

	-- If the emulator is NOT running then disable the script.
	if readInteger(EERAMver_ACZplayerWingmanWpn[2]) == nil then

		getAddressList().getMemoryRecordByDescription("Edit player/wingman weapon parameters").Active = false

	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EERAMver_ACZplayerWingmanWpn = pcsx2_version_check()

if (EERAMver_ACZplayerWingmanWpn[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZplayerWingmanWpn[2] + 0x300000, EERAMver_ACZplayerWingmanWpn[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_21346_check ~= 0 then

		-- Check if the player is currently in a mission.
		if (readBytes(EERAMver_ACZplayerWingmanWpn[2] + 0x3FFD1C, 1) ~= 255) then

			-- Check if the player is NOT in a multiplayer match.
			if readBytes(EERAMver_ACZplayerWingmanWpn[2] + 0x3ACEA0, 1) == 13 then

				-- Scan for the the Player/wingman file asset address.
				local found_list = memscan_func(soExactValue, vtByteArray, nil, "11 00 00 00 50 00 00 00 ?0 0? 00 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 ?0 ?? ?? 00 00 00 00 00 00 00 00 00 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 60 00 00 00 B0 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", nil, EERAMver_ACZplayerWingmanWpn[2] + 0x700000, EERAMver_ACZplayerWingmanWpn[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

				if #found_list ~= 0 then

					-- Backup found address(es).
					ACZplayerWingmanWpn_dataList[#ACZplayerWingmanWpn_dataList + 1] = found_list[1]

					-- Enable script.
					IsACZplayerWingmanWpnEnabled = true

				else

					showMessage("<< Unable to activate this script (memscan_func returned nil). >>")

				end

			else

				showMessage("<< The script won't work here. >>")

			end

		else

			showMessage("<< You'll need to be in a mission to use this script. >>")

		end

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EERAMver_ACZplayerWingmanWpn[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EERAMver_ACZplayerWingmanWpn[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EERAMver_ACZplayerWingmanWpn[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZplayerWingmanWpnEnabled then

	-- Create a global header to hold this script's memory records.
	ACZplayerWingmanWpn_headerMain = create_header("[MISC] WEAPON AND ATTACK SETTINGS", nil, nil)

	-- [Player]
	-- Create memory records to display the Player's weapon parameters and backup its data.
	generate_mr(ACZplayerWingmanWpn_dataList[1], "Player", ACZplayerWingmanWpn_headerMain, 8)

	-- [Wingman]
	---- Check if the player is flying with a wingman.
	if readBytes(EERAMver_ACZplayerWingmanWpn[2] + 0x404E60, 1) == 3 then

		-- Look for the current wingman's file asset address.
		local found_list = memscan_func(soExactValue, vtByteArray, nil, "08 00 00 00 30 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00 00 00 00 00 04 00 00 00 20 00 00 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 ?0 ?? 0? 00 00 00 00 00 00 00 00 00", nil, EERAMver_ACZplayerWingmanWpn[2] + 0x700000, EERAMver_ACZplayerWingmanWpn[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

		if #found_list ~= nil then

			-- Backup address.
			ACZplayerWingmanWpn_dataList[#ACZplayerWingmanWpn_dataList + 1] = found_list[1]

			-- Create memory records to display the wingman's weapon parameters and backup its data.
			if readBytes(EERAMver_ACZplayerWingmanWpn[2] + 0x3B9A44, 1) == 5 then -- If Pixy is the wingman.

				generate_mr(found_list[1], "Pixy", ACZplayerWingmanWpn_headerMain, 3)

			elseif readBytes(EERAMver_ACZplayerWingmanWpn[2] + 0x3B9A44, 1) == 10 then -- If PJ is the wingman.

				generate_mr(found_list[1], "PJ", ACZplayerWingmanWpn_headerMain, 3)

			end

		end

	end

	-- Create a timer to check if the emulator is running.
	ACZplayerWingmanWpn_outSortieCheck_Timer = createTimer()
	ACZplayerWingmanWpn_outSortieCheck_Timer.Interval = 300
	ACZplayerWingmanWpn_outSortieCheck_Timer.onTimer = ACZplayerWingmanWpn_outSortieCheck
	ACZplayerWingmanWpn_outSortieCheck_Timer.Enabled = true

	showMessage("<< Restart the mission once you've made your changes so they can take effect. >>")

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZplayerWingmanWpnEnabled then

	if ACZplayerWingmanWpn_outSortieCheck_Timer ~= nil then

		ACZplayerWingmanWpn_outSortieCheck_Timer.destroy()
		ACZplayerWingmanWpn_outSortieCheck_Timer = nil

	end

	ACZplayerWingmanWpn_headerMain.destroy()

	if readInteger(EERAMver_ACZplayerWingmanWpn[2]) ~= nil then

		if (readBytes(EERAMver_ACZplayerWingmanWpn[2] + 0x3FFD1C, 1) ~= 255) then

			for i = 1, #ACZplayerWingmanWpn_dataList, 2 do

				writeBytes(ACZplayerWingmanWpn_dataList[i], ACZplayerWingmanWpn_dataList[i + 1])

			end

			showMessage("<< Restart the mission to fully revert the changes made. >>")

		end

	end

	ACZplayerWingmanWpn_dataList = nil
	IsACZplayerWingmanWpnEnabled = nil

end

EERAMver_ACZplayerWingmanWpn = nil