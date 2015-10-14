-- USBDeviceReference.lua
--[[
	The USBDeviceReference represents a reference to a USB device...
	That is, the device was attached to the system at some point, but 
	whether or not is accessible at the moment is not assured.

	From the reference you can get some basic information, such as a 
	description of the device.

	Most importantly, you can get a handle on something you can actually
	use to read and write from using: getActiveDevice()
--]]
local usb = require("libusb")
local ffi = require("ffi")


local USBDeviceReference = {}
setmetatable(USBDeviceReference, {
	__call = function (self, ...)
		return self:new(...);
	end
})

local USBDeviceReference_mt = {
	__index = USBDeviceReference;
}

function USBDeviceReference.init(self, devHandle)
	local obj = {
		Handle = devHandle;
	}
	setmetatable(obj, USBDeviceReference_mt)

	-- get the device descriptor
	local desc = ffi.new("struct libusb_device_descriptor");
	local res = usb.libusb_get_device_descriptor(devHandle, desc);
	obj.Description = desc;

	return obj;
end

function USBDeviceReference.new(self, devHandle)
	usb.libusb_ref_device(devHandle);
	ffi.gc(devHandle, usb.libusb_unref_device);

	return self:init(devHandle);
end

function USBDeviceReference.getActive(self)
	-- get handle
	local handle = ffi.new("libusb_device_handle*[1]")
	local res = usb.libusb_open(self.Handle, handle);
	if res ~= 0 then
		return nil, string.format("failed to open device: [%d]", res);
	end

	-- construct a USBDevice from the handle
	-- return that
	handle = handle[0];
	ffi.gc(handle, usb.libusb_close)

	return USBDevice(handle)
end

return USBDeviceReference;
