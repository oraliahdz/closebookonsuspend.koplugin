local WidgetContainer = require("ui/widget/container/widgetcontainer")
local G_reader_settings = require("luasettings"):open(require("datastorage"):getSettingsDir() .. "/settings.annotationsviewer.lua")
local _ = require("gettext")
local Device = require("device")
local Dispatcher = require("dispatcher")
local ReaderUI = require("apps/reader/readerui")

local CloseBookOnSuspend = WidgetContainer:extend{
    name = "closebookonsuspend",
    is_doc_only = false,
}

local function getSettingOrDefault(key, default)
    local val = G_reader_settings:readSetting("closebookonsuspend_" .. key)
    if val == nil then return default end
    if type(default) == "number" then
        local nval = tonumber(val)
        if nval == nil then return default end
        return nval
    end
    return val
end

local function setSetting(key, value)
    G_reader_settings:saveSetting("closebookonsuspend_" .. key, value)
    G_reader_settings:flush()
end

local beforeSuspend_original = Device._beforeSuspend

local function modify_before_suspend(inhibit)
    -- Cloase Book and go to Hone
    if ReaderUI.instance then
        ReaderUI.instance:onHome()
    end
    -- Do the normal Before Suspend Actions
    beforeSuspend_original(inhibit)
end

function CloseBookOnSuspend:init()
    self.ui.menu:registerToMainMenu(self)
    Dispatcher:registerAction("toggle_close_book", {
        category = "none",
        event = "ToggleCloseBook",
        title = _("ToggleCloseBook"),
        filemanager = true,
    })
    local is_enabled = getSettingOrDefault("is_enabled", false)
    if is_enabled then
        self:enable()
    else
        self:disable()
    end
end

function CloseBookOnSuspend:enable()
    if self.is_enabled then
        return
    end
    -- add close book function
    Device._beforeSuspend = modify_before_suspend 
    self.is_enabled = true
    -- save on local memory
    setSetting("is_enabled", true)
end

function CloseBookOnSuspend:disable()
    if not self.is_enabled then
        return
    end
    -- Go back to default behavior
    Device._beforeSuspend = beforeSuspend_original 
    self.is_enabled = false
    -- save on local memory
    setSetting("is_enabled", false)
end

function CloseBookOnSuspend:toggle()
    if self.is_enabled then
        self:disable()
    else
        self:enable()
    end
end

function CloseBookOnSuspend:isEnabled()
    return self.is_enabled
end

function CloseBookOnSuspend:addToMainMenu(menu_items)
    menu_items.close_book_on_suspend = {
        text = _("Close book on suspend"),
        checked_func = function() return self:isEnabled() end,
        callback = function()
            self:toggle()
        end,
    }
end

return CloseBookOnSuspend
