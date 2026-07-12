{$lua}

--[[
==============================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - FREE MOVEMENT MODE ====
==============================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v120726
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

ACZfreeMove_dataList = {}

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

-- Memory scanner
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

-- Adjust camera movement speed function.
function AczFreeLook_MoveSpeedControl_function(AczFreeLook_MoveSpeedControl_timer)

	-- Check if PCSX2 is up and running. if not, disable script.
	if readInteger(EERAMver_ACZfreeMove[2]) ~= nil then

		-- Ignore key input if PCSX2 is not on focus.
		if getForegroundProcess() ~= getOpenedProcessID() then

			return

		end

		-- The higher the camera base speed value is the slower the camera will move.
		-- If this value is set to 0 the game/emulator will crash when moving the camera.

		-- Set max/min speed movement value limits
		if readFloat(EERAMver_ACZfreeMove[2] + 0x3F7228) < 127 then

			writeFloat(EERAMver_ACZfreeMove[2] + 0x3F7228, 127)

		elseif readFloat(EERAMver_ACZfreeMove[2] + 0x3F7228) > 1023 then

			writeFloat(EERAMver_ACZfreeMove[2] + 0x3F7228, 1023)

		end

		-- Adjust values on key presses.
		if (isKeyPressed(VK_ADD)) then -- Decrease base movement speed if ADD NUMPAD key is being pressed.

			writeFloat(EERAMver_ACZfreeMove[2] + 0x3F7228, readFloat(EERAMver_ACZfreeMove[2] + 0x3F7228) - 7)

		elseif (isKeyPressed(VK_SUBTRACT)) then -- Increase if SUBSTRACT NUMPAD key is being pressed.

			writeFloat(EERAMver_ACZfreeMove[2] + 0x3F7228, readFloat(EERAMver_ACZfreeMove[2] + 0x3F7228) + 7)

		elseif (isKeyPressed(VK_NUMPAD0)) then -- Set to default base movement speed if NUMPAD 0 key was pressed.

			writeFloat(EERAMver_ACZfreeMove[2] + 0x3F7228, 255)

		end

	else

		-- Self disable script on emulator crash or exit.
		getAddressList().getMemoryRecordByDescription("Free movement mode").Active = false

	end

	return

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if there are not conflicting scripts active at the moment.
if not IsACZfreecamHangarEnabled and not IsACZfreecamGameplayEnabled and not IsACZadjustTPSviewCamEnabled then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_ACZfreeMove = pcsx2_version_check()

	if (EERAMver_ACZfreeMove[3] == nil) then

		-- Check if the emulator has the right game loaded.
		local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZfreeMove[2] + 0x300000, EERAMver_ACZfreeMove[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

		if #SLUS_21346_check ~= 0 then

			-- Check if the player is currently in a mission.
			if (readBytes(EERAMver_ACZfreeMove[2] + 0x3FFD1C, 1) ~= 255) then

				-- Check if the player is NOT in a multiplayer match.
				if readBytes(EERAMver_ACZfreeMove[2] + 0x3ACEA0, 1) == 13 then

					-- Scan for the address where the Player's properties are stored.
					ACZfreeMove_tbl = memscan_func(soExactValue, vtByteArray, nil, "18 00 00 00 70 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 10 00 00 00 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00 20 00 00 00", nil, EERAMver_ACZfreeMove[2] + 0x700000, EERAMver_ACZfreeMove[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

					if #ACZfreeMove_tbl == 1 then

						-- Proceed with he rest of the script if one result was found.
						IsACZfreeMoveEnabled = true

					else

						if ACZfreeMove_tbl == nil then

							showMessage("<< Unable to activate this script (memscan_func returned nil). >>")

						elseif #ACZfreeMove_tbl >= 1 then

							showMessage("<< Unable to activate this script (memscan_func returned more than one result). >>")

						end

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

		if EERAMver_ACZfreeMove[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_ACZfreeMove[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_ACZfreeMove[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end
	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [GAMEPLAY]".."\n- [HANGAR]".."\n- [ADJUST THIRD PERSON CAMERA DISTANCE]".."\n".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZfreeMoveEnabled then

	-- Retrieve the player's properties so they can be modified to give them invincibility
	-- because when the free movement mode is enabled the player is still vulnerable to enemy attacks.

	-- The address we found earlier points to the mission's logic asset file.
	-- Process it and extract the Player's properties.
	local main_file = retrieve_toc(ACZfreeMove_tbl[1])
	local mission_file = retrieve_toc(main_file[1] + 0x20)
	local entity_file = retrieve_toc(mission_file[1] + 0x20)
	local current_entities_group = retrieve_toc(entity_file[1] + 0x50)

	-- Read the address and value of the entity's EMCP property.
	ACZfreeMove_dataList[#ACZfreeMove_dataList + 1] = current_entities_group[2] + 0xBC
	ACZfreeMove_dataList[#ACZfreeMove_dataList + 1] = readBytes(current_entities_group[2] + 0xBC, 1)

	-- Read the address and value of the entity's solid flag property.
	ACZfreeMove_dataList[#ACZfreeMove_dataList + 1] = (current_entities_group[2] + 0xBF)
	ACZfreeMove_dataList[#ACZfreeMove_dataList + 1] = (readBytes(current_entities_group[2] + 0xBF, 1))

	-- Enable EMCP flag.
	writeBytes(ACZfreeMove_dataList[1], 70)

	-- Enable solid state flag (?).
	writeBytes(ACZfreeMove_dataList[3], 2)

	-- Enable free movement!.
	writeBytes(EERAMver_ACZfreeMove[2] + 0x765231, 0)

	-- Create a header and memory records to display the free movement mode's controls
	--ACZfreeMove_main_header = create_header("[FREE MOVEMENT MODE] CONTROLS", nil)
	--local description_list = {"TRIANGLE = move up", "CROSS = move down", "CIRCLE = move right", "SQUARE = move left", "R1 = move forwards", "L1 = move backwards", "L2 = yaw left", "R2 = yaw right", "L-STICK UP = pitch up", "L-STICK DOWN = pitch down", "L-STICK LEFT = roll left", "L-STICK RIGHT = roll right", "D-PAD LEFT = rotate 90° left", "D-PAD RIGHT = rotate 90° right", "D-PAD UP = set rotation to 0º", "D-PAD DOWN = set rotation to -90°", "NUMPAD + = increase speed movement", "NUMPAD - = decrease speed movement", "NUMPAD 0 = reset speed movement"}

	--for i = 1, #description_list do
	--
	--	create_header(description_list[i], ACZfreeMove_main_header, nil)
	--
	--end

	-- Initialize timer object for the hotkey function.
	AczFreeLook_MoveSpeedControl = createTimer(true, nil) -- Create timer object
	AczFreeLook_MoveSpeedControl.Interval = 50 -- Set tick rate
	AczFreeLook_MoveSpeedControl.onTimer = AczFreeLook_MoveSpeedControl_function -- Call this function every Nms value set in the ".Interval" parameter.
	AczFreeLook_MoveSpeedControl.Enabled = true -- Enable the timer object.

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZfreeMoveEnabled then

	if AczFreeLook_MoveSpeedControl then

		AczFreeLook_MoveSpeedControl.destroy()
		AczFreeLook_MoveSpeedControl = nil

	end

	if readInteger(EERAMver_ACZfreeMove[2]) ~= nil then

		if (readBytes(EERAMver_ACZfreeMove[2] + 0x3FFD1C, 1) ~= 255) then

			writeBytes(ACZfreeMove_dataList[1], ACZfreeMove_dataList[2])
			writeBytes(ACZfreeMove_dataList[3], ACZfreeMove_dataList[4])

		end

		writeBytes(EERAMver_ACZfreeMove[2] + 0x765231, 2) -- Restore default free movement flag value.
		writeFloat(EERAMver_ACZfreeMove[2] + 0x3F7228, 255) -- Restore default free movement camera speed.

		--ACZfreeMove_main_header.destroy()

	end

	ACZfreeMove_dataList = nil
	IsACZfreeMoveEnabled = nil

end

ACZfreeMove_tbl = nil
EERAMver_ACZfreeMove = nil