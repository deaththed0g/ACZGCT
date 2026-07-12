{$lua}

--[[
=================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - HANGAR FREECAM SCRIPT ====
=================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v120726

Special thanks to anonymous from CE forums for their debug handling code used in this script.
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

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

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

end

-- Camera freecam controls
local function ACZfreecamHangar_mainFunc(screenWidth, screenWidth_old, screenHeight, screenHeight_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPos, xPos_old, zPos, zPos_old, yPos, yPos_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, hangarParamCoordSet, hangarParamCoordSet_old, hangarParamMisc, hangarParamMisc_old, hangarParamReflect, hangarParamReflect_old, hangarParamRot, hangarParamRot_old)

	-- Calculate factor that will be used for some operations within the scope of this function.
	local factor = distortionFactorW / distortionFactorW_old

	-- Calculate camera rotation speed.
	local rotSpeed = 0.1 / factor

	-- Clamp rotation speed if screen projection is bigger that 0.1.
	-- This will prevent the camera from moving very fast when the screen distortion
	-- leans towards the pincushion type.
	if rotSpeed >= 0.1 then
		rotSpeed = 0.1
	end

	-- The descriptions of the directional movement keys assume
	-- that the camera's current pitch, yaw and roll axis values are {0, 0, 0}.
	if (isKeyPressed(VK_A)) then -- Move left
		writeFloat(xPos, readFloat(xPos) - camera_base_speed)
	elseif (isKeyPressed(VK_D)) then -- Move right
		writeFloat(xPos, readFloat(xPos) + camera_base_speed)
	elseif (isKeyPressed(VK_S)) then -- Move down
		writeFloat(zPos, readFloat(zPos) - camera_base_speed)
	elseif (isKeyPressed(VK_W)) then -- Move up
		writeFloat(zPos, readFloat(zPos) + camera_base_speed)
	elseif (isKeyPressed(VK_Q)) then -- Move backwards
		writeFloat(yPos, readFloat(yPos) + camera_base_speed)
	elseif (isKeyPressed(VK_E)) then -- Move forward
		writeFloat(yPos, readFloat(yPos) - camera_base_speed)
	end

	if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
		writeFloat(pRot, readFloat(pRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
		writeFloat(pRot, readFloat(pRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
		writeFloat(yRot, readFloat(yRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
		writeFloat(yRot, readFloat(yRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
		writeFloat(rRot, readFloat(rRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
		writeFloat(rRot, readFloat(rRot) + rotSpeed)
	end

	-- Camera lens distortion
	if (isKeyPressed(VK_UP)) then -- Pincushion distortion
		if readFloat(screenWidth) >= distortionLimitMaxW then -- Clamp if the screen width exceeds the defined limit.
			writeFloat(screenWidth, distortionLimitMaxW)
			writeFloat(screenHeight, distortionLimitMaxH)
		else
			distortionFactorW = distortionFactorW * 0.99
			distortionFactorH = distortionFactorH * 0.99
			writeFloat(screenWidth, 512.0 / distortionFactorW)
			writeFloat(screenHeight, 448.0 / distortionFactorH)

		end
	elseif (isKeyPressed(VK_DOWN)) then -- Barrel distortion.
		if readFloat(screenWidth) <= distortionLimitMinW then -- Clamp if the screen width exceeds the defined limit.
			writeFloat(screenWidth, distortionLimitMinW)
			writeFloat(screenHeight, distortionLimitMinH)
		else
			distortionFactorW = distortionFactorW * 1.01
			distortionFactorH = distortionFactorH * 1.01
			writeFloat(screenWidth, 512.0 / distortionFactorW)
			writeFloat(screenHeight, 448.0 / distortionFactorH)
		end
	elseif (isKeyPressed(VK_LEFT)) then -- Reset screen resolution and projection scale values.
		writeBytes(screenWidth, screenWidth_old)
		writeBytes(screenHeight, screenHeight_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
	end

	-- Camera movement speed adjustment, reset keys.
	if (isKeyPressed(VK_ADD)) then -- Increase movement speed.
		camera_base_speed = camera_base_speed + 0.1 / factor
	elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease movement speed.
		camera_base_speed = camera_base_speed - 0.1 / factor
	elseif (isKeyPressed(VK_NUMPAD7)) then -- Reset camera position.
		writeBytes(xPos, xPos_old)
		writeBytes(zPos, zPos_old)
		writeBytes(yPos, yPos_old)
	elseif (isKeyPressed(VK_NUMPAD8)) then -- Reset hangar parameters.
		writeBytes(hangarParamMisc, hangarParamMisc_old)
		writeBytes(hangarParamReflect, hangarParamReflect_old)
		writeBytes(hangarParamCoordSet, hangarParamCoordSet_old)
		writeBytes(hangarParamRot, hangarParamRot_old)
	elseif (isKeyPressed(VK_NUMPAD9)) then -- Reset camera axis position.
		writeBytes(pRot, pRot_old)
		writeBytes(yRot, yRot_old)
		writeBytes(rRot, rRot_old)
	elseif (isKeyPressed(VK_SPACE)) then --Panic key (reset !!!EVERYTHING!!!)
		writeBytes(xPos, xPos_old)
		writeBytes(zPos, zPos_old)
		writeBytes(yPos, yPos_old)
		writeBytes(pRot, pRot_old)
		writeBytes(yRot, yRot_old)
		writeBytes(rRot, rRot_old)
		writeBytes(hangarParamMisc, hangarParamMisc_old)
		writeBytes(hangarParamReflect, hangarParamReflect_old)
		writeBytes(hangarParamCoordSet, hangarParamCoordSet_old)
		writeBytes(hangarParamRot, hangarParamRot_old)
		writeBytes(screenWidth, screenWidth_old)
		writeBytes(screenHeight, screenHeight_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
		camera_base_speed = 0.1
	end

	-- Clamp camera movement speed if value is less than zero.
	if (camera_base_speed <= 0) then 
		camera_base_speed = 0.1
	end

	-- Return the modified variables back to the timer.
	return distortionFactorW, distortionFactorH, camera_base_speed
end

-- Switch
function switch(bool)

	if bool then

		-- Disable control input
		writeBytes(ACZfreecamHangar_dataList[9], {0x00, 0x00, 0x00, 0x00})

		-- Disable camera opcodes
		for i = 1, #ACZfreecamHangarAOB_dataList, 2 do

			local tempArray = {}

			for i = 1, #ACZfreecamHangarAOB_dataList[i + 1] do

				-- Fill will NOP bytes (0x90).
				-- The length of the table is equal to the length of bytes in the opcode.
				tempArray[#tempArray + 1] = 0x90

			end

			-- Write NOP bytes.
			writeBytes(ACZfreecamHangarAOB_dataList[i], tempArray)

		end

		-- Remove HUD graphics
		writeBytes(ACZfreecamHangar_dataList[5], 0x01)
		writeBytes(ACZfreecamHangar_dataList[7], {0x00, 0x00, 0x00, 0x00})

	else

		-- Restore camera opcodes
		for i = 1, #ACZfreecamHangarAOB_dataList,2 do

			writeBytes(ACZfreecamHangarAOB_dataList[i], ACZfreecamHangarAOB_dataList[i + 1])

		end

		-- Restore default screen resolution
		writeBytes(ACZfreecamHangar_dataList[17], ACZfreecamHangar_dataList[18])
		writeBytes(ACZfreecamHangar_dataList[19], ACZfreecamHangar_dataList[20])

		-- Restore HUD graphics
		writeBytes(ACZfreecamHangar_dataList[5], ACZfreecamHangar_dataList[6])
		writeBytes(ACZfreecamHangar_dataList[7], ACZfreecamHangar_dataList[8])

		-- Restore default hangar settings.
		writeBytes(ACZfreecamHangar_dataList[3], ACZfreecamHangar_dataList[4])
		writeBytes(ACZfreecamHangar_dataList[11], ACZfreecamHangar_dataList[12])
		writeBytes(ACZfreecamHangar_dataList[13], ACZfreecamHangar_dataList[14])
		writeBytes(ACZfreecamHangar_dataList[15], ACZfreecamHangar_dataList[16])

		-- Restore control input
		writeBytes(ACZfreecamHangar_dataList[9], ACZfreecamHangar_dataList[10])

	end

	return

end

-- Final block trigger (Called ONLY when the queue is completely empty)
function ACZfreecamHangar_detachDebugger()

	local t = createTimer(nil)
	t.Interval = 100
	t.OnTimer = function(timer)

		timer.destroy()
		detachIfPossible()

		IsACZfreecamHangarEnabled = true

		ACZfreecamHangar_mainBlock()

	end

end

-- The core processor function
function ACZfreecamHangar_processNextBreakpoint()

	-- If our index is larger than the queue size, we are done!
	if ACZfreecamHangar_queueIndex > #ACZfreecamHangar_breakpointQueue then

		ACZfreecamHangar_detachDebugger()

		return

	end

	local currentAddr = ACZfreecamHangar_breakpointQueue[ACZfreecamHangar_queueIndex]

	-- We add 'context' as a parameter to safely catch the thread state in CE 7.7+
	debug_setBreakpoint(currentAddr, 4, bptWrite, function(context)

		-- Safely grab the Instruction Pointer (handles 64-bit RIP, 32-bit EIP, and CE 7.7 thread context changes)
		local currentIP = RIP or (context and context.RIP) or EIP or (context and context.EIP)

		-- Safety catch if the IP still fails to load
		if not currentIP then
			showMessage("<< Error: Could not retrieve Instruction Pointer from debugger thread. >>")
			debug_continueFromBreakpoint(co_run)
			return 1
		end

		local targetOpcodeAddr = getPreviousOpcode(currentIP)
		local instrSize = currentIP - targetOpcodeAddr

		ACZfreecamHangarAOB_dataList[#ACZfreecamHangarAOB_dataList + 1] = targetOpcodeAddr
		ACZfreecamHangarAOB_dataList[#ACZfreecamHangarAOB_dataList + 1] = readBytes(targetOpcodeAddr, instrSize, true)

		debug_removeBreakpoint(currentAddr)

		-- Advance and process next
		ACZfreecamHangar_queueIndex = ACZfreecamHangar_queueIndex + 1
		ACZfreecamHangar_processNextBreakpoint()

		-- EXPLICITLY TELL CE TO RESUME SILENTLY
		debug_continueFromBreakpoint(co_run)

		return 1

	end)

end

------------------+
---- [TABLES] ----+
------------------+
ACZfreecamHangar_dataList = {}
ACZfreecamHangarAOB_dataList = {}
ACZfreecamHangar_breakpointQueue = {}

-----------------+
---- [CHECK] ----+
-----------------+
-- Check if there are not conflicting scripts active at the moment.
if not IsACZfreecamGameplayEnabled and not IsACZadjustTPSviewCamEnabled and not IsACZfreeMoveEnabled then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_ACZfreecamHangar = pcsx2_version_check()

	if (EERAMver_ACZfreecamHangar[3] == nil) then

		-- Check if the emulator has the right game loaded.
		local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZfreecamHangar[2] + 0x300000, EERAMver_ACZfreecamHangar[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

		if #SLUS_21346_check ~= 0 then

			-- Check if the player is currently in any of the hangars available in the game.
			if value_exists({39, 40, 41, 42}, readBytes(EERAMver_ACZfreecamHangar[2] + 0x3FDF2C, 1)) then

				-- Check if the game has the [QUICK SELECTION] option enabled. If yes, warn the player and exit script.
				if readBytes(EERAMver_ACZfreecamHangar[2] + 0x3FDF2C, 1) ~= 1 then

					-- Look for the XZY/PYR coordinates address
					ACZcoord_temp = memscan_func(soExactValue, vtByteArray, nil, "00 00 ?? 44 00 00 ?? 43 00 00 00 44 00 00 80 3F", nil, EERAMver_ACZfreecamHangar[2] + 0x800000, EERAMver_ACZfreecamHangar[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

					-- Variables are defined and reset right here, exactly when needed
					ACZfreecamHangar_queueIndex = 1

					-- Populate the queue
					ACZfreecamHangar_breakpointQueue[#ACZfreecamHangar_breakpointQueue + 1] = ACZcoord_temp[1] + 0x30
					ACZfreecamHangar_breakpointQueue[#ACZfreecamHangar_breakpointQueue + 1] = ACZcoord_temp[1] + 0x40
					ACZfreecamHangar_breakpointQueue[#ACZfreecamHangar_breakpointQueue + 1] = ACZcoord_temp[1] + 0x4

					-- Kick off the queue
					ACZfreecamHangar_processNextBreakpoint()

				else

					showMessage("<< Disable the [QUICK SELECTION] setting in ACZ's options menu before activating this script. >>")

				end

			else

				showMessage("<< Please enter a hangar before activating this script. >>")


			end

		else

			showMessage("<< This script is not compatible with the game you're currently emulating. >>")


		end

	else

		if EERAMver_ACZfreecamHangar[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_ACZfreecamHangar[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_ACZfreecamHangar[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end

	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [GAMEPLAY]".."\n- [ADJUST THIRD PERSON CAMERA DISTANCE]".."\n- [FREE MOVEMENT MODE]".."\n".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+

-- Since the main block of the code is a huge function I should move it to its right section
-- but I'll leave it here for consistency.
function ACZfreecamHangar_mainBlock()

	if IsACZfreecamHangarEnabled then

		-- //[BACKUP]//
		-- Look for the current hangar parameters address.
		local ACZhangar_temp = memscan_func(soExactValue, vtByteArray, nil, "00 00 CA 42 00 00 DC C2 00 00 A0 42 00 00 A0 42 00 00 9E 42 00 00 F0 C0 00 00 04 42 7F 7F 7F 7F 7F 7F 7F 7F 00 00 00 46 00 00 57 43 04 00 00 00 00 00 00 40 00 00 20 C1 00 00 F0 41 00 00 F0 C1 00 00 3E 43 00 00 02 43 00 00 0C 42 00 00 20 41 00 00 08 43 00 00 48 C3 00 00 B6 42 00 00 AA 42 00 00 A0 42 00 00 F0 C0 00 00 B6 42 7F 7F 7F 7F 7F 7F 7F 7F 00 00 40 46 00 00 07 43 04 00 00 00 00 00 00 40 00 00 82 43 00 00 F0 41 00 00 B4 C2 00 00 61 43 00 00 40 42 00 00 96 C2 00 00 20 41 00 00 0C 43 00 00 52 C3 00 00 B6 42 00 00 A4 42 00 00 A0 42 00 00 F0 C0 00 00 B6 42 7F 7F 7F 7F 7F 7F 7F 7F 00 00 00 46 00 00 61 43 04 00 00 00 00 00 00 40 00 80 93 C3 00 00 48 42 00 00 00 41 00 00 2F C3 00 00 C8 42 00 00 D2 C2 00 00 20 41 00 00 C8 42 33 33 47 C2 00 00 A0 42 00 00 9E 42 00 00 9C 42 00 00 F0 C0 00 00 E0 41 7F 7F 7F 7F 7F 7F 7F 7F 00 00 00 46 00 00 57 43 04 00 00 00 00 00 00 40 00 00 20 42 00 00 F0 41 00 00 F0 C1 00 00 70 43 00 00 02 43 00 00 0C 42 00 00 20 41", nil, EERAMver_ACZfreecamHangar[2] + 0x800000, EERAMver_ACZfreecamHangar[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

		-- 1 XZY/PYR coordinates: read and backup data
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = {ACZcoord_temp[1] + 0x30, ACZcoord_temp[1] + 0x34, ACZcoord_temp[1] + 0x38, ACZcoord_temp[1] + 0x40, ACZcoord_temp[1] + 0x44, ACZcoord_temp[1] + 0x48}
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = {readBytes(ACZcoord_temp[1] + 0x30, 0x4, true), readBytes(ACZcoord_temp[1] + 0x34, 0x4, true), readBytes(ACZcoord_temp[1] + 0x38, 0x4, true), readBytes(ACZcoord_temp[1] + 0x40, 0x4, true), readBytes(ACZcoord_temp[1] + 0x44, 0x4, true), readBytes(ACZcoord_temp[1] + 0x48, 0x4, true)}

		-- 3 Current hangar parameters: read and backup data.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = ACZhangar_temp[1]
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(ACZhangar_temp[1], 0x160, true)

		-- 5 Read and backup HUD graphic parameters.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = EERAMver_ACZfreecamHangar[2] + 0x3F7E8C
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(EERAMver_ACZfreecamHangar[2] + 0x3F7E8C, 1, true)

		-- 7 Read and backup HUD graphic parameters.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = EERAMver_ACZfreecamHangar[2] + 0x3F7EB0
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(EERAMver_ACZfreecamHangar[2] + 0x3F7EB0, 4, true)

		-- 9 Read and backup control input bytes.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = EERAMver_ACZfreecamHangar[2] + 0x3F70B8
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(EERAMver_ACZfreecamHangar[2] + 0x3F70B8, 4, true)

		-- 11 Read and backup the current hangar's reflection effect state.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = ACZfreecamHangar_dataList[3] + 0x11D
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(ACZfreecamHangar_dataList[3] + 0x11D, 1, true)

		-- 13 Read and backup the current coordinate set ID.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = ACZcoord_temp[1] + 0x1826
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(ACZcoord_temp[1] + 0x1826, 1, true)

		-- 15 Read and backup object rotation value.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = EERAMver_ACZfreecamHangar[2] + 0x3F7A54
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(EERAMver_ACZfreecamHangar[2] + 0x3F7A54, 4, true)

		-- //[PROJECTION SCALE STUFF]//
		-- 17/19 Store current foreground/background addresses and current resolutions.
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = ACZcoord_temp[1]
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(ACZcoord_temp[1], 4, true)
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = ACZcoord_temp[1] + 0x4
		ACZfreecamHangar_dataList[#ACZfreecamHangar_dataList + 1] = readBytes(ACZcoord_temp[1] + 0x4, 4, true)

		-- //[MEMREC HANDLING]//
		-- Create a global header to attach the other sub-header and memory records that will be created on script activation.
		ACZfreecamHangar_mainHeader = create_header("[CAMERA] HANGAR FREECAM", nil, nil)

		-- Create header and memory records to display the camera's current XYZ/PYR coordinates.
		local cameraCoordinates_header = create_header("Current camera coordinates", ACZfreecamHangar_mainHeader, true)
		local offset_list = {0x0, 0x4, 0x8, 0x10, 0x14, 0x18}
		local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
		local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

		create_memory_record(ACZfreecamHangar_dataList[1][1], offset_list, vt_list, description_list, cameraCoordinates_header)

		-- Create header and memory records to display the player/wingman/SpW's position.
		local hangarPlacement_mainHeader = create_header("Coordinate sets", ACZfreecamHangar_mainHeader, true)

		-- Create header and memory records to display the current coordinate set and the yaw value for set ID 3.
		create_memory_record(ACZfreecamHangar_dataList[13], {0x0}, {vtByte}, {"Current coordinate set ID"}, hangarPlacement_mainHeader)

		local offset_list = {0x0, 0x4, 0x50, 0x54, 0xA0, 0xA4, 0xF0, 0xF4}
		local header_list = {"[ID 0] VALAIS", "[ID 1] HEIERLARK", "[ID 2] KIRWIN ISLAND", "[ID 3] VALAIS SP"}

		for i = 1, #header_list do

			local hangarObjectPlacement_mainHeader = create_header(header_list[i], hangarPlacement_mainHeader, true)

			create_memory_record(ACZfreecamHangar_dataList[3], {offset_list[i * 2]}, {vtSingle}, {"Player object position"}, hangarObjectPlacement_mainHeader)
			create_memory_record(ACZfreecamHangar_dataList[3], {offset_list[(i * 2) - 1]}, {vtSingle}, {"SpW/Wingman object position"}, hangarObjectPlacement_mainHeader)

			if i == 4 then

				create_memory_record(EERAMver_ACZfreecamHangar[2] + 0x3F7A54, {0x0}, {vtSingle}, {"Aircraft rotation value"}, hangarObjectPlacement_mainHeader)

			end

		end

		-- //[AIRCRAFT ANIMATION FLAG]//
		-- Create a header and a memory record to display the current animation flag value for the player's plane.
		local ACZanimFlag_mainHeader = create_header("Aircraft animation flags", ACZfreecamHangar_mainHeader, true)
		create_memory_record(ACZcoord_temp[1] + 0xA04, {0x0}, {vtByte}, {"Player"}, ACZanimFlag_mainHeader)

		-- //[WINGMAN]//
		-- Check if the LoD cheat is enabled.
		if readBytes(EERAMver_ACZfreecamHangar[2] + 0x13C664) == 1 then

			-- Check if the wingman is present in the hangar.
			if readByte(ACZcoord_temp[1] + 0x1876) == 1 then

				-- Create memory record for wingman's animation flag.
				create_memory_record(ACZcoord_temp[1] + 0x1344, {0x0}, {vtByte}, {"Wingman"}, ACZanimFlag_mainHeader)

				-- Toggle wingman's aircraft animation to "closed"
				writeBytes(ACZcoord_temp[1] + 0x1344, 1)

			end

		else

			-- Show a message suggesting the user to enable the loD cheat for the hangar.
			showMessage("<< You might want to enable the [ACZGCT: FORCE MAXIMUM LOD FOR HANGAR PLANES] cheat to get the most out of this script. >>")

		end

		-- //[HANGAR GROUND REFLECTION EFFECT]//
		-- Create header and memory record for the ground reflection effect flag.
		create_memory_record(ACZhangar_temp[1] + 0x11D, {0x0}, {vtByte}, {"Ground reflection effect"}, ACZfreecamHangar_mainHeader)

		-- //[INITIALIZE VARIABLES AND FUNCTIONS]//
		-- Read and store addresses and variables, initialize wrapper closure and freecam functions.
		local function ACZfreecamHangar_init()

			-- Get current screen resolution.
			local screenWidth = ACZfreecamHangar_dataList[17]
			local screenWidth_old = ACZfreecamHangar_dataList[18]
			local screenHeight = ACZfreecamHangar_dataList[19]
			local screenHeight_old = ACZfreecamHangar_dataList[20]

			-- Get current projection scale values.
			local distortionFactorW = readFloat(ACZcoord_temp[1] + 0x198)
			local distortionFactorW_old = distortionFactorW
			local distortionFactorH = readFloat(ACZcoord_temp[1] + 0x19C)
			local distortionFactorH_old = distortionFactorH

			-- Set projection scale limits.
			local distortionLimitMaxW = (512.0 // distortionFactorW) * 4
			local distortionLimitMaxH = (448.0 // distortionFactorH) * 4
			local distortionLimitMinW = (512.0 // distortionFactorW) // 16
			local distortionLimitMinH = (448.0 // distortionFactorH) // 16

			-- Camera coordinates.
			local xPos = ACZfreecamHangar_dataList[1][1]
			local xPos_old = ACZfreecamHangar_dataList[2][1]
			local zPos = ACZfreecamHangar_dataList[1][2]
			local zPos_old = ACZfreecamHangar_dataList[2][2]
			local yPos = ACZfreecamHangar_dataList[1][3]
			local yPos_old = ACZfreecamHangar_dataList[2][3]
			local pRot = ACZfreecamHangar_dataList[1][4]
			local pRot_old = ACZfreecamHangar_dataList[2][4]
			local yRot = ACZfreecamHangar_dataList[1][5]
			local yRot_old = ACZfreecamHangar_dataList[2][5]
			local rRot = ACZfreecamHangar_dataList[1][6]
			local rRot_old = ACZfreecamHangar_dataList[2][6]

			-- Hangar parameters.
			local hangarParamMisc = ACZfreecamHangar_dataList[3]
			local hangarParamMisc_old = ACZfreecamHangar_dataList[4]
			local hangarParamReflect = ACZfreecamHangar_dataList[11]
			local hangarParamReflect_old = ACZfreecamHangar_dataList[12]
			local hangarParamCoordSet = ACZfreecamHangar_dataList[13]
			local hangarParamCoordSet_old = ACZfreecamHangar_dataList[14]
			local hangarParamRot = ACZfreecamHangar_dataList[15]
			local hangarParamRot_old = ACZfreecamHangar_dataList[16]

			-- Camera movement speed.
			local camera_base_speed = 0.1

			-- Create timer object and wrapper closure function.
			ACZfreecamHangar_timer = createTimer()
			ACZfreecamHangar_timer.Interval = 50

			ACZfreecamHangar_timer.OnTimer = function(ACZfreecamHangar_timerObj)

				-- If the emulator has exited abruptly, disable script.
				if readInteger(EERAMver_ACZfreecamHangar[2]) == nil then

					ACZfreecamHangar_timerObj.destroy()
					ACZfreecamHangar_timer = nil

					getAddressList().getMemoryRecordByDescription("Hangar").Active = false

					return

				end

				-- Ignore key input if PCSX2 is not on focus.
				if getForegroundProcess() ~= getOpenedProcessID() then

					return

				end

				-- Send arguments and/or update dynamic variables.
				distortionFactorW, distortionFactorH, camera_base_speed = ACZfreecamHangar_mainFunc(screenWidth, screenWidth_old, screenHeight, screenHeight_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPos, xPos_old, zPos, zPos_old, yPos, yPos_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, hangarParamCoordSet, hangarParamCoordSet_old, hangarParamMisc, hangarParamMisc_old, hangarParamReflect, hangarParamReflect_old, hangarParamRot, hangarParamRot_old)

			end

		end

		-- Call function above.
		ACZfreecamHangar_init()

		-- Disable camera opcodes and remove HUD graphics.
		switch(true)

	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZfreecamHangarEnabled then

	if ACZfreecamHangar_timer then

		ACZfreecamHangar_timer.destroy()
		ACZfreecamHangar_timer = nil

	end

	if readInteger(EERAMver_ACZfreecamHangar[2]) ~= nil then

		-- // Debugger cleanup
		-- Process exists: Clean cleanup
		local bplist = debug_getBreakpointList()

		if bplist then

			for i = 1, #bplist do debug_removeBreakpoint(bplist[i]) end

		end

		-- Use a quick timer to detach so the script can finish the current 'Disable' cycle first
		local t = createTimer(nil)
		t.Interval = 100
		t.OnTimer = function(timer)

			timer.destroy()
			detachIfPossible()

		end

		-- Restore controls, HUD, etc.
		switch(false)

	else

		-- Process is DEAD:
		-- We can't remove specific breakpoints because the memory is gone,
		-- but we call this to tell CE the debugger is now "Free".
		-- Use a quick timer to detach so the script can finish the current 'Disable' cycle first
		local t = createTimer(nil)
		t.Interval = 100
		t.OnTimer = function(timer)

			timer.destroy()
			detachIfPossible()

		end

	end

	ACZfreecamHangar_mainHeader.destroy()

	ACZfreecamHangarAOB_dataList = nil
	ACZfreecamHangar_dataList = nil
	ACZfreecamHangar_breakpointQueue = nil

	IsACZfreecamHangarEnabled = nil

end

EERAMver_ACZfreecamHangar = nil
