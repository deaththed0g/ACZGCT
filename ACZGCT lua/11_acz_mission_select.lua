{$lua}

--[[
=================================================================
==== ACE COMBAT ZERO: THE BELKAN WAR - MISSION SELECT SCRIPT ====
=================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v280226
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

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

-- Write value/check emulator status/create memory record function
function ACZmissionSelect_outSortieCheck(ACZmissionSelect_outSortieCheckTimer)

	-- Check if the emulator is up.
	if readInteger(EEMEMver_ACZmissionSelect[2]) ~= nil then

		-- Check if the memory record was not deleted. If true then create a new one.
		if getAddressList().getMemoryRecordByDescription("Type the mission's ID") then

			getAddressList().getMemoryRecordByDescription("Type the mission's ID").Active = true

			-- Write User's value then freeze record as long the script is enabled.
			ACZmissionSelect_ID = tonumber(getAddressList().getMemoryRecordByDescription("Type the mission's ID").getValue())

			-- Skip broken/unplayable stages.
			if not ((ACZmissionSelect_ID >= 0 and ACZmissionSelect_ID <= 30) or value_exists({46, 47, 48, 49, 50, 51, 53}, ACZmissionSelect_ID) or (ACZmissionSelect_ID >= 78 and ACZmissionSelect_ID <= 108)) then

				ACZmissionSelect_ID = 0

			end

			getAddressList().getMemoryRecordByDescription("Type the mission's ID").Value = ACZmissionSelect_ID

		else

			create_memory_record(EEMEMver_ACZmissionSelect[2] + 0x3BF740, {0x0}, {vtByte}, {"Type the mission's ID"}, getAddressList().getMemoryRecordByDescription("Select mission"))

		end

	else

		getAddressList().getMemoryRecordByDescription("Select mission").Active = false

	end

end

[ENABLE]

if syntaxcheck then return end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EEMEMver_ACZmissionSelect = pcsx2_version_check()

if (EEMEMver_ACZmissionSelect[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "18 B7 3D 00 88 44 3F 00 18 B7 3D 00 68 45 3F 00", nil, EEMEMver_ACZmissionSelect[2] + 0x300000, EEMEMver_ACZmissionSelect[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_21346_check ~= 0 then

		-- Process with the script activation if all checks were passed.
		IsACZmissionSelectEnabled = true

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EEMEMver_ACZmissionSelect[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EEMEMver_ACZmissionSelect[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EEMEMver_ACZmissionSelect[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsACZmissionSelectEnabled then

	-- Create a memory record so the User can input their desire value.
	create_memory_record(EEMEMver_ACZmissionSelect[2] + 0x3BF740, {0x0}, {vtByte}, {"Type the mission's ID"}, getAddressList().getMemoryRecordByDescription("Select mission"))

	-- Create a timer object that will execute the function that checks the emulator status
	-- and handle memory record creation and value input.
	ACZmissionSelect_outSortieCheck_Timer = createTimer()
	ACZmissionSelect_outSortieCheck_Timer.Interval = 300
	ACZmissionSelect_outSortieCheck_Timer.onTimer = ACZmissionSelect_outSortieCheck
	ACZmissionSelect_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsACZmissionSelectEnabled then

	if ACZmissionSelect_outSortieCheck_Timer ~= nil then

		ACZmissionSelect_outSortieCheck_Timer.destroy()
		ACZmissionSelect_outSortieCheck_Timer = nil

	end

	writeBytes(EEMEMver_ACZmissionSelect[2] + 0x698390, {0x00, 0xC0, 0xF1, 0x11, 0x00, 0xE8, 0x91, 0x00})

	getAddressList().getMemoryRecordByDescription("Type the mission's ID").destroy()

	IsACZmissionSelectEnabled = nil

end

EEMEMver_ACZmissionSelect = nil