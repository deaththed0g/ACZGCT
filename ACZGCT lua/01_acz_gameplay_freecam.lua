{$lua}

--[[
===================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - GAMEPLAY FREECAM SCRIPT ====
===================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v130726

Credit to anonymous from CE forums for their debugger handling code.
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
local function ACZfreecamGameplay_mainFunc(screenWidthF, screenWidthF_old, screenHeightF, screenHeightF_old, screenWidthB, screenWidthB_old, screenHeightB, screenHeightB_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPosS1, xPosS1_old, zPosS1, zPosS1_old, yPosS1, yPosS1_old, xPosS2, xPosS2_old, zPosS2, zPosS2_old, yPosS2, yPosS2_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, currentEntityID, currentCamView, customCoordSet1, customCoordSet2, lightVal1, lightVal1_old, lightVal2, lightVal2_old, lightVal3, lightVal3_old)

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

	-- Move camera, write movement values according to current camera view.
	-- The descriptions of the directional movement keys assume
	-- that the camera's current pitch, yaw and roll axis values are {0, 0, 0}.

	-- Player is third-person camera view.
	if currentCamView == 1 then

		if (isKeyPressed(VK_A)) then -- Move left
			writeFloat(xPosS1, readFloat(xPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- Move right
			writeFloat(xPosS1, readFloat(xPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- Move down
			writeFloat(zPosS1, readFloat(zPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- Move up
			writeFloat(zPosS1, readFloat(zPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- Move backwards
			writeFloat(yPosS1, readFloat(yPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- Move forward
			writeFloat(yPosS1, readFloat(yPosS1) + camera_base_speed)
		end

		if (isKeyPressed(VK_J)) then -- Move left
			writeFloat(xPosS2, readFloat(xPosS2) + camera_base_speed)
		elseif (isKeyPressed(VK_L)) then -- Move right
			writeFloat(xPosS2, readFloat(xPosS2) - camera_base_speed)
		elseif (isKeyPressed(VK_K)) then -- Move down
			writeFloat(zPosS2, readFloat(zPosS2) + camera_base_speed)
		elseif (isKeyPressed(VK_I)) then -- Move up
			writeFloat(zPosS2, readFloat(zPosS2) - camera_base_speed)
		elseif (isKeyPressed(VK_U)) then -- Move backwards
			writeFloat(yPosS2, readFloat(yPosS2) - camera_base_speed)
		elseif (isKeyPressed(VK_O)) then -- Move forward
			writeFloat(yPosS2, readFloat(yPosS2) + camera_base_speed)
		end

	else -- Cockpit or HUD.

		if (isKeyPressed(VK_A)) then -- Move left
			writeFloat(xPosS1, readFloat(xPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- Move right
			writeFloat(xPosS1, readFloat(xPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- Move down
			writeFloat(zPosS1, readFloat(zPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- Move up
			writeFloat(zPosS1, readFloat(zPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- Move backwards
			writeFloat(yPosS1, readFloat(yPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- Move forward
			writeFloat(yPosS1, readFloat(yPosS1) - camera_base_speed)
		end


	end

	-- Camera rotation movement gets inverted while in HUD or cockpit view
	-- so invert rotSpeed value.
	if currentCamView == 0 or currentCamView == 2 then
		rotSpeed = -rotSpeed
	end

	-- Camera's pitch, yaw and roll control.
	if (isKeyPressed(VK_NUMPAD5)) then -- Pitch up
		writeFloat(pRot, readFloat(pRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD2)) then -- Pitch down
		writeFloat(pRot, readFloat(pRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw left
		writeFloat(yRot, readFloat(yRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw right
		writeFloat(yRot, readFloat(yRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll left
		writeFloat(rRot, readFloat(rRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll right
		writeFloat(rRot, readFloat(rRot) + rotSpeed)
	end

	-- Focus on entity (only available if using the HUD camera view).
	if currentCamView == 0 then
		if (isKeyPressed(VK_1)) then -- Press the "1" key to switch back on the previous one.
			if currentEntityID < 0 then
				currentEntityID = #ACZfreecamGameplay_entityCoordList
			else
				currentEntityID = currentEntityID - 1
			end
			-- Use the current entity's XZY coordinates as anchor point for the camera.
			writeBytes(xPosS1 - 0x418, ACZfreecamGameplay_entityCoordList[currentEntityID])
			writeBytes(pRot, customCoordSet2)
		elseif (isKeyPressed(VK_2)) then -- Press the "2" key to switch focus on the next entity.
			if currentEntityID > #ACZfreecamGameplay_entityCoordList then
				currentEntityID = 2
			else
				currentEntityID = currentEntityID + 1
			end
			writeBytes(xPosS1 - 0x418, ACZfreecamGameplay_entityCoordList[currentEntityID])
			writeBytes(pRot, customCoordSet2)
		end
	end

	-- Camera lens distortion.
	if (isKeyPressed(VK_UP)) then -- Pincushion distortion
		-- Clamp if the screen width exceeds the defined limit.
		if readFloat(screenWidthF) >= distortionLimitMaxW then
			writeFloat(screenWidthF, distortionLimitMaxW)
			writeFloat(screenHeightF, distortionLimitMaxH)
			writeFloat(screenWidthB, distortionLimitMaxW)
			writeFloat(screenHeightB, distortionLimitMaxH)
		else
			distortionFactorW = distortionFactorW * 0.99
			distortionFactorH = distortionFactorH * 0.99
			writeFloat(screenWidthF, 512.0 / distortionFactorW)
			writeFloat(screenHeightF, 448.0 / distortionFactorH)
			writeFloat(screenWidthB, 512.0 / distortionFactorW)
			writeFloat(screenHeightB, 448.0 / distortionFactorH)
		end
	elseif (isKeyPressed(VK_DOWN)) then -- Barrel distortion.
		-- Clamp if the screen width exceeds the defined limit.
		if readFloat(screenWidthF) <= distortionLimitMinW then
			writeFloat(screenWidthF, distortionLimitMinW)
			writeFloat(screenHeightF, distortionLimitMinH)
			writeFloat(screenWidthB, distortionLimitMinW)
			writeFloat(screenHeightB, distortionLimitMinH)
		else
			distortionFactorW = distortionFactorW * 1.01
			distortionFactorH = distortionFactorH * 1.01
			writeFloat(screenWidthF, 512.0 / distortionFactorW)
			writeFloat(screenHeightF, 448.0 / distortionFactorH)
			writeFloat(screenWidthB, 512.0 / distortionFactorW)
			writeFloat(screenHeightB, 448.0 / distortionFactorH)
		end
	elseif (isKeyPressed(VK_LEFT)) then -- Reset screen resolution and projection scale values.
		writeBytes(screenWidthF, screenWidthB_old)
		writeBytes(screenHeightF, screenHeightB_old)
		writeBytes(screenWidthB, screenWidthB_old)
		writeBytes(screenHeightB, screenHeightB_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
	end

	-- Camera movement speed adjustment, reset keys.
	if (isKeyPressed(VK_ADD)) then -- Increase movement speed.
		camera_base_speed = camera_base_speed + 0.1 / factor
	elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease movement speed.
		camera_base_speed = camera_base_speed - 0.1 / factor
	elseif (isKeyPressed(VK_NUMPAD7)) then -- Reset camera position.
		if currentCamView ~= 0 then
			writeBytes(xPosS1, xPosS1_old)
			writeBytes(zPosS1, zPosS1_old)
			writeBytes(yPosS1, yPosS1_old)
		else
			writeBytes(xPosS1, customCoordSet1)
		end
	elseif (isKeyPressed(VK_NUMPAD8)) and currentCamView == 1 then -- Reset camera's point of origin (third-person camera view only).
		writeBytes(xPosS2, xPosS2_old)
		writeBytes(zPosS2, zPosS2_old)
		writeBytes(yPosS2, yPosS2_old)
	elseif (isKeyPressed(VK_NUMPAD9)) then -- Reset camera axis position.
		if currentCamView ~= 0 then
			writeBytes(pRot, pRot_old)
			writeBytes(yRot, yRot_old)
			writeBytes(rRot, rRot_old)
		else
			writeBytes(xPosS1, customCoordSet1)
			writeBytes(pRot, customCoordSet2)
		end
	elseif (isKeyPressed(VK_SPACE)) then --Panic key (reset !!!EVERYTHING!!!).
		if currentCamView ~= 0 then
			writeBytes(xPosS1, xPosS1_old)
			writeBytes(zPosS1, zPosS1_old)
			writeBytes(yPosS1, yPosS1_old)
			writeBytes(pRot, pRot_old)
			writeBytes(yRot, yRot_old)
			writeBytes(rRot, rRot_old)
		else
			writeBytes(xPosS1, customCoordSet1)
			writeBytes(pRot, customCoordSet2)
		end
		if currentCamView == 1 then
			writeBytes(xPosS2, xPosS2_old)
			writeBytes(zPosS2, zPosS2_old)
			writeBytes(yPosS2, yPosS2_old)
		end
		writeBytes(screenWidthF, screenWidthB_old)
		writeBytes(screenHeightF, screenHeightB_old)
		writeBytes(screenWidthB, screenWidthB_old)
		writeBytes(screenHeightB, screenHeightB_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
		writeBytes(lightVal1, lightVal1_old)
		writeBytes(lightVal2, lightVal2_old)
		writeBytes(lightVal3, lightVal3_old)
		camera_base_speed = 0.1
	end

	-- Clamp camera movement speed if value is less than zero.
	if (camera_base_speed <= 0) then 
		camera_base_speed = 0.1
	end

	-- Return the modified variables back to the timer.
	return distortionFactorW, distortionFactorH, camera_base_speed, currentEntityID

end

-- Switch
function switch(bool)

	if bool then

		-- Remove dynamic shadow.
		writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3FC030, 0)

		-- Disable control input
		writeBytes(EERAMver_ACZfreecamGameplay[2] + 0x3F70B8, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

		-- Pause game
		writeBytes(EERAMver_ACZfreecamGameplay[2] + 0x7651E8, 0x05)

		-- Disable camera opcodes
		for i = 1, #ACZfreecamGameplayAOB_dataList, 2 do

			local tempArray = {}

			for i = 1, #ACZfreecamGameplayAOB_dataList[i + 1] do

				tempArray[#tempArray + 1] = 0x90

			end

			writeBytes(ACZfreecamGameplayAOB_dataList[i], tempArray)

		end

		-- Remove HUD and pause menu graphics
		writeBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FFBCF, 0x00)
		writeInteger(EERAMver_ACZfreecamGameplay[2] + 0x3FC7DC, 0)

	else

		-- Restore camera opcodes
		for i = 1, #ACZfreecamGameplayAOB_dataList,2 do

			writeBytes(ACZfreecamGameplayAOB_dataList[i], ACZfreecamGameplayAOB_dataList[i + 1])

		end

		-- Restore screen projection default values.
		writeBytes(ACZfreecamGameplay_dataList[3], ACZfreecamGameplay_dataList[4])
		writeBytes(ACZfreecamGameplay_dataList[5], ACZfreecamGameplay_dataList[6])
		writeBytes(ACZfreecamGameplay_dataList[7], ACZfreecamGameplay_dataList[8])
		writeBytes(ACZfreecamGameplay_dataList[9], ACZfreecamGameplay_dataList[10])

		-- Restore dynamic shadow.
		writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3FC030, 0.5)

		-- Restore default lighting values.
		writeBytes(ACZfreecamGameplay_dataList[11], ACZfreecamGameplay_dataList[12])
		writeBytes(ACZfreecamGameplay_dataList[13], ACZfreecamGameplay_dataList[14])
		writeBytes(ACZfreecamGameplay_dataList[15], ACZfreecamGameplay_dataList[16])

		-- Restore HUD and pause menu graphics
		writeBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FFBCF, 0x01)
		writeInteger(EERAMver_ACZfreecamGameplay[2] + 0x3FC7DC, 7753432)

		-- Restore camera coordinates.
		writeBytes(ACZfreecamGameplay_dataList[1][7], ACZfreecamGameplay_dataList[2][7])
		writeBytes(ACZfreecamGameplay_dataList[1][8], ACZfreecamGameplay_dataList[2][8])
		writeBytes(ACZfreecamGameplay_dataList[1][9], ACZfreecamGameplay_dataList[2][9])
		writeBytes(ACZfreecamGameplay_dataList[1][1], ACZfreecamGameplay_dataList[2][1])
		writeBytes(ACZfreecamGameplay_dataList[1][2], ACZfreecamGameplay_dataList[2][2])
		writeBytes(ACZfreecamGameplay_dataList[1][3], ACZfreecamGameplay_dataList[2][3])
		writeBytes(ACZfreecamGameplay_dataList[1][4], ACZfreecamGameplay_dataList[2][4])
		writeBytes(ACZfreecamGameplay_dataList[1][5], ACZfreecamGameplay_dataList[2][5])
		writeBytes(ACZfreecamGameplay_dataList[1][6], ACZfreecamGameplay_dataList[2][6])
		
		-- Restore control input
		writeBytes(EERAMver_ACZfreecamGameplay[2] + 0x3F70B8, 0x30, 0x7D, 0x69, 0x00, 0xC0, 0x7D, 0x69, 0x00)

		-- Unpause game
		writeBytes(EERAMver_ACZfreecamGameplay[2] + 0x7651E8, 0x04)

	end

	return

end

-- Final block trigger (Called ONLY when the queue is completely empty)
function ACZfreecamGameplay_detachDebugger()

	local t = createTimer(nil)
	t.Interval = 100
	t.OnTimer = function(timer)

		timer.destroy()
		detachIfPossible()

		IsACZfreecamGameplayEnabled = true

		ACZfreecamGameplay_mainBlock()

	end

end

-- The core processor function
function ACZfreecamGameplay_processNextBreakpoint()

	-- If our index is larger than the queue size, we are done!
	if ACZfreecamGameplay_queueIndex > #ACZfreecamGameplay_breakpointQueue then

		ACZfreecamGameplay_detachDebugger()

		return

	end

	local currentAddr = ACZfreecamGameplay_breakpointQueue[ACZfreecamGameplay_queueIndex]

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

		ACZfreecamGameplayAOB_dataList[#ACZfreecamGameplayAOB_dataList + 1] = targetOpcodeAddr
		ACZfreecamGameplayAOB_dataList[#ACZfreecamGameplayAOB_dataList + 1] = readBytes(targetOpcodeAddr, instrSize, true)

		debug_removeBreakpoint(currentAddr)

		-- Advance and process next
		ACZfreecamGameplay_queueIndex = ACZfreecamGameplay_queueIndex + 1
		ACZfreecamGameplay_processNextBreakpoint()

		-- EXPLICITLY TELL CE TO RESUME SILENTLY
		debug_continueFromBreakpoint(co_run)

		return 1

	end)

end

------------------+
---- [TABLES] ----+
------------------+
ACZfreecamGameplay_dataList = {}
ACZfreecamGameplayAOB_dataList = {}
ACZfreecamGameplay_entityCoordList = {}
ACZfreecamGameplay_breakpointQueue = {}

-----------------+
---- [CHECK] ----+
-----------------+
-- Check if there are not conflicting scripts active at the moment.
if not IsACZfreecamHangarEnabled and not IsACZadjustTPSviewCamEnabled and not IsACZfreeMoveEnabled then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_ACZfreecamGameplay = pcsx2_version_check()

	if (EERAMver_ACZfreecamGameplay[3] == nil) then

		-- Check if the emulator has the right game loaded.
		local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EERAMver_ACZfreecamGameplay[2] + 0x300000, EERAMver_ACZfreecamGameplay[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

		if #SLUS_21346_check ~= 0 then

			-- Check if cheat needed by this script is enabled.
			if readBytes(EERAMver_ACZfreecamGameplay[2] + 0x232A34, 1) == 0 then

				-- Check if the player is currently in a mission.
				if readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FFD1C, 1) ~= 255 and not value_exists({39, 40, 41, 42}, readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FDF2C, 1)) then

					-- Check if the player is NOT in a multiplayer match.
					if readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3ACEA0, 1) == 13 then

						-- Check if the player is NOT taking off, landing or a pre-rendered cutscene is playing.
						if value_exists({3, 15, 23}, readBytes(EERAMver_ACZfreecamGameplay[2] + 0x76587C, 1)) and readBytes(EERAMver_ACZfreecamGameplay[2] + 0x7651E8, 1) ~= 0 then

							-- Look for the XZY/PYR coordinates address
							ACZcoord_temp = memscan_func(soExactValue, vtByteArray, nil, "00 00 ?? 44 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 ?? ?? ?? 00 00 00 00 00 02 C0 01 00 00 80 3F FF FF 7F 4B 00 00 00 00 00 02 C0 01 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 3F ?? ?? ?? 43 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 C5 00 00 00 C5 ?? ?? ?? ?? 00 00 80 BF 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? 3F 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ?? ?? 80 BF 00 00 80 BF 00 00 00 00 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 00 45 00 00 00 45 CD CC ?? ?? ?? ?? ?? 3F 03 00 00 00 ?? ?? ?? ?? 01 00 00 ?? ?? ?? ?? ?? 00 00 00 15 00 01 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? 44 00 00 ?? ??", nil, EERAMver_ACZfreecamGameplay[2] + 0x800000, EERAMver_ACZfreecamGameplay[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

							-- Variables are defined and reset right here, exactly when needed
							ACZfreecamGameplay_queueIndex = 1

							-- Populate the queue
							ACZfreecamGameplay_breakpointQueue[#ACZfreecamGameplay_breakpointQueue + 1] = ACZcoord_temp[1] + 0xC20

							-- Kick off the queue
							ACZfreecamGameplay_processNextBreakpoint()

						else

							showMessage("<< Please wait until the pre-rendered cutscene is done playing or the camera panning sequence is complete then activate this script again. >>")

						end

					else

						showMessage("<< This script is not compatible with this mode. >>")


					end

				else

					showMessage("<< This script can be only activated while in a mission. >>")

				end

			else

				showMessage("<< Please activate the [[ACZGCT] 'GAMEPLAY' script camera codes]] cheat before using this script!. >>")

			end

		else

			showMessage("<< This script is not compatible with the game you're currently emulating. >>")

		end

	else

		if EERAMver_ACZfreecamGameplay[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_ACZfreecamGameplay[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_ACZfreecamGameplay[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end

	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [HANGAR]".."\n- [ADJUST THIRD PERSON CAMERA DISTANCE]".."\n- [FREE MOVEMENT MODE]".."\n".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+
-- Since the main block of the code is a huge function I should move it to its right section
-- but I'll leave it here for consistency.
function ACZfreecamGameplay_mainBlock()

	if IsACZfreecamGameplayEnabled then

		-- //[BACKUP]//
		-- 1 XZY camera position/coordinates: read and backup data
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = {ACZcoord_temp[1] + 0xB30, ACZcoord_temp[1] + 0xB34, ACZcoord_temp[1] + 0xB38, ACZcoord_temp[1] + 0xB3C, ACZcoord_temp[1] + 0xB40, ACZcoord_temp[1] + 0xB44, ACZcoord_temp[1] + 0xB48, ACZcoord_temp[1] + 0xB4C, ACZcoord_temp[1] + 0xB50, ACZcoord_temp[1] + 0xC20, ACZcoord_temp[1] + 0xC24, ACZcoord_temp[1] + 0xC28}
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = {readBytes(ACZcoord_temp[1] + 0xB30, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB34, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB38, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB3C, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB40, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB44, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB48, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB4C, 0x4, true), readBytes(ACZcoord_temp[1] + 0xB50, 0x4, true), readBytes(ACZcoord_temp[1] + 0xC20, 0x4, true), readBytes(ACZcoord_temp[1] + 0xC24, 0x4, true), readBytes(ACZcoord_temp[1] + 0xC28, 0x4, true)}

		-- //[MEMREC/CAMERA SETUP]//
		-- Create a global header to attach the other sub-header and memory records that will be create on script activation.
		ACZfreecamGameplay_mainHeader = create_header("[CAMERA] GAMEPLAY FREECAM", nil, nil)

		-- Create a memory record to display the current value of "HUD visibility" flag.
		create_memory_record(EERAMver_ACZfreecamGameplay[2] + 0x3FFBCF, {0x0}, {vtByte}, {"HUD visibility"}, ACZfreecamGameplay_mainHeader)

		-- //[PROJECTION SCALE STUFF]//
		-- Store current foreground/background addresses and current resolutions.
		-- 3 Foreground
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = ACZcoord_temp[1]
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(ACZcoord_temp[1], 4, true)
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = ACZcoord_temp[1] + 0x4
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(ACZcoord_temp[1] + 0x4, 4, true)

		-- 7 Background
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = ACZcoord_temp[1] + 0x1C0 
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(ACZcoord_temp[1] + 0x1C0, 4, true)
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = ACZcoord_temp[1] + 0x1C4
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(ACZcoord_temp[1] + 0x1C4, 4, true)

		-- //[CAMERA XZY/PYR COORDINATES]//
		-- Set record descriptions and offsets according to current camera view.
		-- Create header and memory records to display the camera's current XYZ coordinates.
		-- Store camera's last XYZ coordinates previous to script activation to use it with the restore function.

		-- Camera views values:
		---- 0 = HUD view
		---- 1 = Third-person view
		---- 2 = Cockpit view
		local camera_coordinates_header = create_header("Current camera coordinates", ACZfreecamGameplay_mainHeader, true)

		-- Store current camera view ID.
		local currentCamView = readBytes(ACZfreecamGameplay_dataList[1][1] - 0x2A7, 1)

		-- If camera view is TPS:
		if currentCamView == 1 then

			local offset_list = {0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0xF0, 0xF4, 0xF8}
			local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "X coordinate (anchor)", "Y coordinate (anchor)", "Z coordinate (anchor)", "Pitch", "Yaw", "Roll"}
			local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

			create_memory_record(ACZfreecamGameplay_dataList[1][1], offset_list, vt_list, description_list, camera_coordinates_header)

		-- If camera view is cockpit or HUD:
		else

			local offset_list = {0x18, 0x1C, 0x20, 0xF0, 0xF4, 0xF8}
			local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
			local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

			create_memory_record(ACZfreecamGameplay_dataList[1][1], offset_list, vt_list, description_list, camera_coordinates_header)

		end

		-- //[LIGHTING CONTROL]//
		-- Create a header to hold the addresses of the game lighting values.
		local lighting_values_header = create_header("Lighting values", ACZfreecamGameplay_mainHeader, true)

		-- 11/15 Backup lighting values.
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = EERAMver_ACZfreecamGameplay[2] + 0x38F740
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(EERAMver_ACZfreecamGameplay[2] + 0x38F740, 0x4, true) -- 12
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = EERAMver_ACZfreecamGameplay[2] + 0x38DCF0
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(EERAMver_ACZfreecamGameplay[2] + 0x38DCF0, 0x4, true) -- 14
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = EERAMver_ACZfreecamGameplay[2] + 0x3F80E8
		ACZfreecamGameplay_dataList[#ACZfreecamGameplay_dataList + 1] = readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3F80E8, 0x4, true) -- 16

		-- Create memory records for the light control parameters
		create_memory_record(EERAMver_ACZfreecamGameplay[2] + 0x38F740, {0x0}, {vtSingle}, {"Source light intensity (Player aircraft)"}, lighting_values_header)
		create_memory_record(EERAMver_ACZfreecamGameplay[2] + 0x38DCF0, {0x0}, {vtSingle}, {"Source light intensity (other)"}, lighting_values_header)
		create_memory_record(EERAMver_ACZfreecamGameplay[2] + 0x3F80E8, {0x0}, {vtSingle}, {"Ambient source light intensity"}, lighting_values_header)

		-- Remove dynamic shadow.
		writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3FC030, 0)

		-- //[INITIALIZE VARIABLES AND FUNCTIONS]//
		-- Read and store addresses and variables, initialize wrapper closure and freecam functions.
		local function ACZfreecamGameplay_init()

			-- Get current screen resolution.
			-- Foreground layer
			local screenWidthF = ACZfreecamGameplay_dataList[3]
			local screenWidthF_old = ACZfreecamGameplay_dataList[4]
			local screenHeightF = ACZfreecamGameplay_dataList[5]
			local screenHeightF_old = ACZfreecamGameplay_dataList[6]
			-- Background layer
			local screenWidthB =  ACZfreecamGameplay_dataList[7]
			local screenWidthB_old =  ACZfreecamGameplay_dataList[8]
			local screenHeightB =  ACZfreecamGameplay_dataList[9]
			local screenHeightB_old =  ACZfreecamGameplay_dataList[10]

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

			-- Camera XYZ coordinates.
			-- Adjust addresses and default values depending on current camera view.
			local xPosS1
			local xPosS1_old
			local zPosS1
			local zPosS1_old
			local yPosS1
			local yPosS1_old
			local xPosS2
			local xPosS2_old
			local zPosS2
			local zPosS2_old
			local yPosS2
			local yPosS2_old

			if currentCamView == 1 then
				xPosS1 = ACZfreecamGameplay_dataList[1][1]
				xPosS1_old = ACZfreecamGameplay_dataList[2][1]
				zPosS1 = ACZfreecamGameplay_dataList[1][2]
				zPosS1_old = ACZfreecamGameplay_dataList[2][2]
				yPosS1 = ACZfreecamGameplay_dataList[1][3]
				yPosS1_old = ACZfreecamGameplay_dataList[2][3]

				xPosS2 = ACZfreecamGameplay_dataList[1][4]
				xPosS2_old = ACZfreecamGameplay_dataList[2][4]
				zPosS2 = ACZfreecamGameplay_dataList[1][5]
				zPosS2_old = ACZfreecamGameplay_dataList[2][5]
				yPosS2 = ACZfreecamGameplay_dataList[1][6]
				yPosS2_old = ACZfreecamGameplay_dataList[2][6]
			else
				xPosS1 = ACZfreecamGameplay_dataList[1][7]
				xPosS1_old = ACZfreecamGameplay_dataList[2][7]
				zPosS1 = ACZfreecamGameplay_dataList[1][8]
				zPosS1_old = ACZfreecamGameplay_dataList[2][8]
				yPosS1 = ACZfreecamGameplay_dataList[1][9]
				yPosS1_old = ACZfreecamGameplay_dataList[2][9]
			end

			-- Pitch, yaw, roll.
			local pRot = ACZfreecamGameplay_dataList[1][10]
			local pRot_old = ACZfreecamGameplay_dataList[2][10]
			local yRot = ACZfreecamGameplay_dataList[1][11]
			local yRot_old = ACZfreecamGameplay_dataList[2][11]
			local rRot = ACZfreecamGameplay_dataList[1][12]
			local rRot_old = ACZfreecamGameplay_dataList[2][12]

			-- Lighting values.
			local lightVal1 = ACZfreecamGameplay_dataList[11]
			local lightVal1_old = ACZfreecamGameplay_dataList[12]
			local lightVal2 = ACZfreecamGameplay_dataList[13]
			local lightVal2_old = ACZfreecamGameplay_dataList[14]
			local lightVal3 = ACZfreecamGameplay_dataList[15]
			local lightVal3_old = ACZfreecamGameplay_dataList[16]

			-- Set default entity ID which the camera will focus on.
			local currentEntityID = 2

			-- Custom XYZ/PYR coordinates that will used in the entity focus mode.
			local customCoordSet1 = {0x5D, 0xE6, 0xDA, 0xC2, 0x62, 0xA6, 0x8B, 0x42, 0x97, 0xD9, 0xA4, 0xC2}
			local customCoordSet2 = {0x00, 0x00, 0x00, 0xBF, 0x01, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00}

			-- Set camera movement rates depending on the camera views (HUD or COCKPIT)
			if currentCamView == 0 then

				local tempScan = memscan_func(soExactValue, vtByteArray, nil, "CC CC 4C 42", nil, EERAMver_ACZfreecamGameplay[2] + 0x800000, EERAMver_ACZfreecamGameplay[2] + 0x1F00000, "", 1, "4", true, nil, nil, nil)

				for i = 1, #tempScan do

					-- Filter and remove entities that are not yet active or garbage data.
					if readInteger(tempScan[i] - 0x114) == 1065353216 then

						ACZfreecamGameplay_entityCoordList[#ACZfreecamGameplay_entityCoordList + 1] = tempScan[i] - 0x120
						ACZfreecamGameplay_entityCoordList[#ACZfreecamGameplay_entityCoordList + 1] = readBytes(tempScan[i] - 0x120, 0x1C, true)

					end

				end

				-- Write custom camera position for the HUD view mode.
				writeBytes(xPosS1, customCoordSet1)
				writeBytes(pRot, customCoordSet2)

			end

			-- Camera movement speed.
			local camera_base_speed = 0.1

			-- Create timer object and wrapper closure function.
			ACZfreecamGameplay_timer = createTimer()
			ACZfreecamGameplay_timer.Interval = 50

			ACZfreecamGameplay_timer.OnTimer = function(ACZfreecamGameplay_timerObj)

				-- If the emulator has exited abruptly, disable script.
				if readInteger(EERAMver_ACZfreecamGameplay[2]) == nil then

					ACZfreecamGameplay_timerObj.destroy()
					ACZfreecamGameplay_timer = nil

					getAddressList().getMemoryRecordByDescription("Gameplay").Active = false

					return

				end

				-- Ignore key input if PCSX2 is not on focus.
				if getForegroundProcess() ~= getOpenedProcessID() then

					return

				end

				-- Send arguments and/or update dynamic variables.
				distortionFactorW, distortionFactorH, camera_base_speed, currentEntityID = ACZfreecamGameplay_mainFunc(screenWidthF, screenWidthF_old, screenHeightF, screenHeightF_old, screenWidthB, screenWidthB_old, screenHeightB, screenHeightB_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPosS1, xPosS1_old, zPosS1, zPosS1_old, yPosS1, yPosS1_old, xPosS2, xPosS2_old, zPosS2, zPosS2_old, yPosS2, yPosS2_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, currentEntityID, currentCamView, customCoordSet1, customCoordSet2, lightVal1, lightVal1_old, lightVal2, lightVal2_old, lightVal3, lightVal3_old)

			end

		end

		-- Call function above.
		ACZfreecamGameplay_init()

		-- Disable controls, camera opcodes and pause game.
		switch(true)

		-- Clear this variable.
		ACZcoord_temp = nil

	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and tables on script deactivation.
if IsACZfreecamGameplayEnabled then

	if ACZfreecamGameplay_timer then

		ACZfreecamGameplay_timer.destroy()
		ACZfreecamGameplay_timer = nil

	end

	if readInteger(EERAMver_ACZfreecamGameplay[2]) ~= nil then

		-- // Debugger cleanup
		-- Process exists: Clean cleanup
		local bplist = debug_getBreakpointList()

		if bplist then

			for i=1, #bplist do debug_removeBreakpoint(bplist[i]) end

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

	-- Also disable any scripts that requires this one to be active to work.
	getAddressList().getMemoryRecordByDescription("Isolate 3D objects").Active = false
	getAddressList().getMemoryRecordByDescription("Generate alpha mask").Active = false
	getAddressList().getMemoryRecordByDescription("Isolate VFX").Active = false

	ACZfreecamGameplay_mainHeader.destroy()

	ACZfreecamGameplayAOB_dataList = nil
	ACZfreecamGameplay_dataList = nil
	ACZfreecamGameplay_entityCoordList = nil
	ACZfreecamGameplay_breakpointQueue = nil

	IsACZfreecamGameplayEnabled = nil

end

EERAMver_ACZfreecamGameplay = nil
