{$lua}

--[[
=======================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - ISOLATE VFX ====
=======================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v010726
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

local ACZisolateVFX_temp = {}
ACZisolateVFX_dataList = {}

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

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if the [GAMEPLAY] camera script is enabled.
if IsACZfreecamGameplayEnabled then

	-- Check if the [ISOLATE 3D OBJECTS] and [CONVERT SCENE TO ALPHA MASK] scripts are NOT active.
	if not IsACZgenerateAlphaMaskEnabled and not IsACZisolate3DobjectsEnabled then

		-- Scan for the address where the current stage's environment assets is located.
		ACZisolateVFX_temp = memscan_func(soExactValue, vtByteArray, nil, "27 00 00 00 A0 00 00 00 A0 01 00 00", nil, EERAMver_ACZfreecamGameplay[2] + 0x700000, EERAMver_ACZfreecamGameplay[2] + 0x1f00000, "", 2, "0", true, nil, nil, nil)

		-- Proceed with the rest of the script.
		IsACZisolateVFXEnabled = true

	else

		showMessage("<< The [ISOLATE 3D OBJECTS]/[GENERATE ALPHA MASK] script is still active. Deactivate it before activating this one first. >>")

	end

else

	showMessage("<< Activate the [GAMEPLAY] camera script before this one first. >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZisolateVFXEnabled then

	-- Get stage's environment assets environment parameter list.
	local ACZisolateVFX_envTemp = retrieve_toc(ACZisolateVFX_temp[1])

	-- Read and store address and bytearray data of the skybox parameter set.
	ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = ACZisolateVFX_envTemp[12] -- Skybox configuration file address
	ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = readBytes(ACZisolateVFX_envTemp[12], 352, true) -- Skybox configuration file as bytearray data

	-- Read and store the address and bytearray data of the first stage environment set.
	ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = ACZisolateVFX_envTemp[19] -- address
	ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = readBytes(ACZisolateVFX_envTemp[19], 864, true) -- bytearray data

	-- Read and store the address and bytearray data of the second stage environment set.
	ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = ACZisolateVFX_envTemp[38]
	ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = readBytes(ACZisolateVFX_envTemp[38], 864, true)

	-- If the main stage file has a take-off/landing/refueling stage in it then also append its start offsets and environment data.
	if readBytes(ACZisolateVFX_envTemp[39], 1) == 38 then

		local ACZisolateVFX_envTempSub = retrieve_toc(ACZisolateVFX_envTemp[39])

		ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = ACZisolateVFX_envTempSub[12]
		ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = readBytes(ACZisolateVFX_envTempSub[12], 352, true)

		ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = ACZisolateVFX_envTempSub[19]
		ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = readBytes(ACZisolateVFX_envTempSub[19], 864, true)

		ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = ACZisolateVFX_envTempSub[38]
		ACZisolateVFX_dataList[#ACZisolateVFX_dataList + 1] = readBytes(ACZisolateVFX_envTempSub[38], 864, true)

	end

	-- Apply changes.
	for i = 1, #ACZisolateVFX_dataList do

		-- Change skybox's colors to pure black.
		if value_exists({1, 7}, i) then

			writeBytes((ACZisolateVFX_dataList[i] + 0x10), {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			writeBytes((ACZisolateVFX_dataList[i] + 0x38), {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
			writeBytes((ACZisolateVFX_dataList[i] + 0x68), {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

		end

		-- Edit environment parameters.
		if value_exists({3, 5, 9, 11}, i) then

			-- Moon sprite transparency (set 1)
			writeFloat(ACZisolateVFX_dataList[i] + 0xC8, 0)

			-- Star sprite transparency (set 1)
			writeFloat(ACZisolateVFX_dataList[i] + 0xCC, 0)

			-- Moon sprite transparency (set 2)
			writeFloat(ACZisolateVFX_dataList[i] + 0x168, 0)

			-- Star sprite transparency (set 2)
			writeFloat(ACZisolateVFX_dataList[i] + 0x16C, 0)

			-- Cloud type flag
			writeByte(ACZisolateVFX_dataList[i] + 0x190, 0)

			-- Foliage visibility range
			writeBytes(ACZisolateVFX_dataList[i] + 0x310, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Screen blur
			writeBytes(ACZisolateVFX_dataList[i] + 0x44, 0x0)

		end

	end

	-- Rendering parameter.
	writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F80F0, -255)

	-- Remove reflection/highlights from aircraft's surface
	writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x38F7B0, 0)
	writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x38FAC0, 0)

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZisolateVFXEnabled then

	if readInteger(EERAMver_ACZfreecamGameplay[2]) ~= nil then

		if (readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FFD1C, 1) ~= 255) then

			for i = 1, #ACZisolateVFX_dataList, 2 do

				writeBytes(ACZisolateVFX_dataList[i], ACZisolateVFX_dataList[i + 1])

			end

		end

		writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F80F0, 255)
		writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x38F7B0, 0.5)
		writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x38FAC0, 0.5)

	end

	ACZisolateVFX_dataList = nil
	IsACZisolateVFXEnabled = nil

end