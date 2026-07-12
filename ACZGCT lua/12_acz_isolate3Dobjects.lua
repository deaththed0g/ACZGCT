{$lua}

--[[
==============================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - ISOLATE 3D OBJECTS ====
==============================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v110726
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+
local ACZisolate3Dobjects_temp = {}
ACZisolate3Dobjects_dataList = {}
ACZisolate3Dobjects_EFDBsize = {}
ACZisolate3Dobjects_EFDBsize_sub = {}

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

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if the [GAMEPLAY] camera script is enabled.
if IsACZfreecamGameplayEnabled then

	-- Check if the [ISOLATE VFX] and [CONVERT SCENE TO ALPHA MASK] scripts are NOT active.
	if not IsACZgenerateAlphaMask and not IsACZisolateVFXEnabled then

		-- Proceed with the rest of the script.
		IsACZisolate3DobjectsEnabled = true

	else

		showMessage("<< The [ISOLATE VFX]/[GENERATE ALPHA MASK] script is still active. Deactivate it before activating this one first. >>")

	end

else

	showMessage("<< Activate the [GAMEPLAY] camera script before this one first. >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZisolate3DobjectsEnabled then

	-- Get stage's environment assets environment parameter list.
	-- Scan for the address where the current stage's environment assets is located.
	local ACZisolate3Dobjects_temp = memscan_func(soExactValue, vtByteArray, nil, "27 00 00 00 A0 00 00 00 A0 01 00 00", nil, EERAMver_ACZfreecamGameplay[2] + 0x700000, EERAMver_ACZfreecamGameplay[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
	local ACZisolate3Dobjects_tempEnv = retrieve_toc(ACZisolate3Dobjects_temp[1])

	-- Read and store address and bytearray data of the skybox parameter set.
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnv[12] -- Skybox configuration file address
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnv[12], 352, true) -- Skybox configuration file as bytearray data

	-- Read and store the address and bytearray data of the first stage environment set.
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnv[19] -- address
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnv[19], 864, true) -- bytearray data

	-- Read and store the address and bytearray data of the second stage environment set.
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnv[38]
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnv[38], 864, true)

	-- Read and store the address and bytearray data of the first EFDB file.
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnv[21] + 0x10
	ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnv[21] + 0x10, (ACZisolate3Dobjects_tempEnv[22] - ACZisolate3Dobjects_tempEnv[21]) - 0x10, true)

	-- Because writing individual bytes is slow, fill a table with zeros to speed up the editing of the particle effects.
	for i = 1, (ACZisolate3Dobjects_tempEnv[22] - ACZisolate3Dobjects_tempEnv[21]) - 0x10 do

		ACZisolate3Dobjects_EFDBsize[#ACZisolate3Dobjects_EFDBsize + 1] = 0

	end

	-- If the main stage file has a take-off/landing/refueling stage in it then also append its start offsets and environment data.
	if readBytes(ACZisolate3Dobjects_tempEnv[39], 1) == 38 then

		local ACZisolate3Dobjects_tempEnvSub = retrieve_toc(ACZisolate3Dobjects_tempEnv[39])

		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnvSub[12]
		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnv[12], 352, true)

		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnvSub[19]
		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnvSub[19], 864, true)

		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnvSub[38]
		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnvSub[38], 864, true)

		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = ACZisolate3Dobjects_tempEnvSub[21] + 0x10 --15
		ACZisolate3Dobjects_dataList[#ACZisolate3Dobjects_dataList + 1] = readBytes(ACZisolate3Dobjects_tempEnvSub[21] + 0x10, (ACZisolate3Dobjects_tempEnvSub[22] - ACZisolate3Dobjects_tempEnvSub[21]) - 0x10, true)

		for i = 1, (ACZisolate3Dobjects_tempEnvSub[22] - ACZisolate3Dobjects_tempEnvSub[21]) - 0x10 do

			ACZisolate3Dobjects_EFDBsize[#ACZisolate3Dobjects_EFDBsize_sub + 1] = 0

		end

	end

	-- Apply changes.
	local offsets = {0x60, 0x90, 0x100, 0x130}

	for i = 1, #ACZisolate3Dobjects_dataList do

		-- Change skybox's colors to pure black.
		if value_exists({1, 7}, i) then

			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x10, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x38, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x68, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

		end

		-- Edit environment parameters.
		if value_exists({3, 5, 11, 13}, i) then

			-- Moon sprite transparency (set 1)
			writeFloat(ACZisolate3Dobjects_dataList[i] + 0xC8, 0)

			-- Star sprite transparency (set 1)
			writeFloat(ACZisolate3Dobjects_dataList[i] + 0xCC, 0)

			-- Moon sprite transparency (set 2)
			writeFloat(ACZisolate3Dobjects_dataList[i] + 0x168, 0)

			-- Star sprite transparency (set 2)
			writeFloat(ACZisolate3Dobjects_dataList[i] + 0x16C, 0)

			-- Sun sprite transparency (both sets)
			for p = 1, #offsets do

				for t = 1, 6 do

					if t ~= 3 then

						writeBytes(ACZisolate3Dobjects_dataList[i] + offsets[p] + (t * (4 - 4)), {0x00, 0x00, 0x00, 0x00})

					end

				end

			end

			-- Cloud type flag
			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x190, 0)

			-- Foliage visibility range
			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x310, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Rain/snow/fog particles (set 1)
			writeBytes(ACZisolate3Dobjects_dataList[i] + 0xD4, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Rain/snow/fog particles (set 2)
			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x174, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			-- Screen blur
			writeBytes(ACZisolate3Dobjects_dataList[i] + 0x44, 0x0)

		end

		-- Remove particle effects.
		if i == 7 then

			writeBytes(ACZisolate3Dobjects_dataList[i], ACZisolate3Dobjects_EFDBsize)

		elseif i == 15 then

			writeBytes(ACZisolate3Dobjects_dataList[i], ACZisolate3Dobjects_EFDBsize_sub)

		end

	end

	-- Apply rendering parameter changes.
	writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F8264, 0)
	writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F8050, 0)
	writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F90EC, 0)

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and stray debug breakpoints on script deactivation.
if IsACZisolate3DobjectsEnabled then

	if readInteger(EERAMver_ACZfreecamGameplay[2]) ~= nil then

		if (readBytes(EERAMver_ACZfreecamGameplay[2] + 0x3FFD1C, 1) ~= 255) then

			for i = 1, #ACZisolate3Dobjects_dataList, 2 do

				writeBytes(ACZisolate3Dobjects_dataList[i], ACZisolate3Dobjects_dataList[i + 1])

			end

			writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F8264, 65536)
			writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F8050, 16384)
			writeFloat(EERAMver_ACZfreecamGameplay[2] + 0x3F90EC, 4)

		end

	end

	ACZisolate3Dobjects_EFDBsize = nil
	ACZisolate3Dobjects_EFDBsize_sub = nil
	ACZisolate3Dobjects_dataList = nil

	IsACZisolate3DobjectsEnabled = nil

end