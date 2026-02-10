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

local function close_book_before_suspend(inhibit)
    -- Closes Book and goes to Home
    if ReaderUI.instance then
        ReaderUI.instance:onHome()
    end
    -- Do normal Before Suspend actions
    beforeSuspend_original(inhibit)
end

function CloseBookOnSuspend:onDispatcherRegisterActions()
    Dispatcher:registerAction("close_book_on_suspend_toggle", {
        category = "none",
        event = "CloseBookToggle",
        title = _("Toggle CloseBookOnSuspend"),
        filemanager = true,
    })
    Dispatcher:registerAction("close_book_on_suspend_enable", {
        category = "none",
        event = "CloseBookEnable",
        title = _("Enable CloseBookOnSuspend"),
        filemanager = true,
    })
    Dispatcher:registerAction("close_book_on_suspend_disable", {
        category = "none",
        event = "CloseBookDisable",
        title = _("Disable CloseBookOnSuspend"),
        filemanager = true,
    })
end

function CloseBookOnSuspend:init()
    self.ui.menu:registerToMainMenu(self)
    self:onDispatcherRegisterActions()
    
    local is_enabled = getSettingOrDefault("is_enabled", false)
    if is_enabled then
        self:onCloseBookEnable()
    else
        self:onCloseBookDisable()
    end
end

function CloseBookOnSuspend:onCloseBookEnable()
    if self.is_enabled then
        return
    end
    -- add close book function
    Device._beforeSuspend = close_book_before_suspend 
    self.is_enabled = true
    -- save state on device memory
    setSetting("is_enabled", true)
end

function CloseBookOnSuspend:onCloseBookDisable()
    if not self.is_enabled then
        return
    end
    -- Go back to default behavior
    Device._beforeSuspend = beforeSuspend_original 
    self.is_enabled = false
    -- save state on device memory
    setSetting("is_enabled", false)
end

function CloseBookOnSuspend:onCloseBookToggle()
    if self.is_enabled then
        self:onCloseBookDisable()
    else
        self:onCloseBookEnable()
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
            self:onCloseBookToggle()
        end,
    }
end

return CloseBookOnSuspend
