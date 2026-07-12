{$lua}

--[[
======================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - GENERATE ALPHA MASK SCRIPT ====
======================================================================
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

local ACZgenerateAlphaMask_temp = {}
ACZgenerateAlphaMask_dataList = {}
ACZgenerateAlphaMask_addressListStatic = {0x3F80F0, 0x38F7B0, 0x38FAC0, 0x38E6F8, 0x38FD34, 0x3F80F4, 0x3F9F6C, 0x3F8B1C, 0x3F8BF8, 0x3FC030}
ACZgenerateAlphaMask_addressListStatic_newVal = {61440, 0, 0, 0, 0, 255, 0, 0, 0, 0}
ACZgenerateAlphaMask_addressListStatic_defVal = {255, 0.5, 0.5, 0.5, 127, -255, 6, 1, 1, 0.5}
ACZgenerateAlphaMask_EFDBsize = {}
ACZgenerateAlphaMask_EFDBsize_sub = {}

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

	-- Check if the [ISOLATE VFX] and [ISOLATE 3D OBJECTS] scripts are NOT active.
	if not IsACZisolate3DobjectsEnabled and not IsACZisolateVFXEnabled then

		-- Scan for the address where the current stage's environment assets is located.
		ACZgenerateAlphaMask_temp = memscan_func(soExactValue, vtByteArray, nil, "27 00 00 00 A0 00 00 00 A0 01 00 00", nil, EERAMver_ACZfreecamGameplay[2] + 0x700000, EERAMver_ACZfreecamGameplay[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

		-- Proceed with the rest of the script.
		IsACZgenerateAlphaMaskEnabled = true

	else

		showMessage("<< The [ISOLATE VFX]/[ISOLATE 3D OBJECTS] script is still active. Deactivate it before activating this one first. >>")

	end

else

	showMessage("<< Activate the [GAMEPLAY] camera script before this one first. >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZgenerateAlphaMaskEnabled then

	-- Get stage's environment assets environment parameter list.
	local ACZgenerateAlphaMask_envTemp = retrieve_toc(ACZgenerateAlphaMask_temp[1])

	-- Read and store address and bytearray data of the skybox parameter set.
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTemp[12] -- Skybox configuration file address -1
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTemp[12], 352, true) -- Skybox configuration file as bytearray data

	-- Read and store the address and bytearray data of the first stage environment set.
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTemp[19] -- address -3
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTemp[19], 864, true) -- bytearray data

	-- Read and store the address and bytearray data of the second stage environment set.-5
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTemp[38]
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTemp[38], 864, true)

	-- Read and store the address and bytearray data of the first EFDB file.
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTemp[21] + 0x10 --7
	ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTemp[21] + 0x10, (ACZgenerateAlphaMask_envTemp[22] - ACZgenerateAlphaMask_envTemp[21]) - 0x10, true)

	-- Because writing individual bytes is slow, fill a table with zeros to speed up the editing of the particle effects.
	for i = 1, (ACZgenerateAlphaMask_envTemp[22] - ACZgenerateAlphaMask_envTemp[21]) - 0x10 do

		ACZgenerateAlphaMask_EFDBsize[#ACZgenerateAlphaMask_EFDBsize + 1] = 0

	end

	-- If the main stage file has a take-off/landing/refueling stage in it then also append its start offsets and environment data.
	if readBytes(ACZgenerateAlphaMask_envTemp[39], 1) == 38 then

		local ACZgenerateAlphaMask_envTempSub = retrieve_toc(ACZgenerateAlphaMask_envTemp[39])

		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTempSub[12] --9
		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTemp[12], 352, true)

		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTempSub[19] --11
		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTempSub[19], 864, true)

		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTempSub[38] --13
		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTempSub[38], 864, true)

		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = ACZgenerateAlphaMask_envTempSub[21] + 0x10 --15
		ACZgenerateAlphaMask_dataList[#ACZgenerateAlphaMask_dataList + 1] = readBytes(ACZgenerateAlphaMask_envTempSub[21] + 0x10, (ACZgenerateAlphaMask_envTempSub[22] - ACZgenerateAlphaMask_envTempSub[21]) - 0x10, true)

		for i = 1, (ACZgenerateAlphaMask_envTempSub[22] - ACZgenerateAlphaMask_envTempSub[21]) - 0x10 do

			ACZgenerateAlphaMask_EFDBsize[#ACZgenerateAlphaMask_EFDBsize_sub + 1] = 0

		end

	end

	-- Apply changes.
	for i = 1, #ACZgenerateAlphaMask_dataList do

		-- Change skybox's colors to pure black.
		if value_exists({1, 9}, i) then

			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x10, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x38, {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF})
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x68, {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF})

		end

		-- Edit environment parameters.
		if value_exists({3, 5, 11, 13}, i) then

			-- Draw distance (set 1)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0x50, 1)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0x54, 0)

			-- Draw distance (set 2)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0xF0, 1)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0xF4, 0)

			-- Moon sprite transparency (set 1)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0xC8, 0)

			-- Star sprite transparency (set 1)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0xCC, 0)

			-- Moon sprite transparency (set 2)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0x168, 0)

			-- Star sprite transparency (set 2)
			writeFloat(ACZgenerateAlphaMask_dataList[i] + 0x16C, 0)

			-- Light source/Sun sprite (set 1, low)
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x60, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Light source/Sun sprite (set 1, high)
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x90, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Light source/Sun sprite (set 2, low)
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x100, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Light source/Sun sprite (set 2, high)
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x130, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Cloud type flag
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x190, 0)

			-- Foliage visibility range
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x310, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Rain/snow/fog particles (set 1)
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0xD4, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Rain/snow/fog particles (set 2)
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x174, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Screen blur
			writeBytes(ACZgenerateAlphaMask_dataList[i] + 0x44, 0x0)

		end

		-- Remove particle effects.
		if i == 7 then

			writeBytes(ACZgenerateAlphaMask_dataList[i], ACZgenerateAlphaMask_EFDBsize)

		elseif i == 15 then

			writeBytes(ACZgenerateAlphaMask_dataList[i], ACZgenerateAlphaMask_EFDBsize_sub)

		end

	end

	-- Apply rendering parameter changes.
	for i = 1, #ACZgenerateAlphaMask_addressListStatic do

		writeFloat(EERAMver_ACZfreecamGameplay[2] + ACZgenerateAlphaMask_addressListStatic[i], ACZgenerateAlphaMask_addressListStatic_newVal[i])

	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZgenerateAlphaMaskEnabled then

	if readInteger(EERAMver_ACZfreecamGameplay[2]) ~= nil then

		if (readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FFD1C, 1) ~= 255) then

			for i = 1, #ACZgenerateAlphaMask_dataList, 2 do

				writeBytes(ACZgenerateAlphaMask_dataList[i], ACZgenerateAlphaMask_dataList[i + 1])

			end

			for i = 1, #ACZgenerateAlphaMask_addressListStatic do

				writeFloat(EERAMver_ACZfreecamGameplay[2] + ACZgenerateAlphaMask_addressListStatic[i], ACZgenerateAlphaMask_addressListStatic_defVal[i])

			end

		end

	end

	ACZgenerateAlphaMask_dataList = nil
	ACZgenerateAlphaMask_EFDBsize = nil
	ACZgenerateAlphaMask_EFDBsize_sub = nil
	ACZgenerateAlphaMask_addressListStatic = nil
	ACZgenerateAlphaMask_addressListStatic_newVal = nil
	ACZgenerateAlphaMask_addressListStatic_defVal = nil

	IsACZgenerateAlphaMaskEnabled = nil

end