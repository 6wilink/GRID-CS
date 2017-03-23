-- @param: region, channel begin/end
-- cache current region, channel, rxagc, rxgain
-- set scscan trigger, set region, channel, set rxagc=0, rxgain=0
-- > scan each channel
-- > print format: <rgn>,<ch>,<freq>,<noise>,<ts>
-- clean chscan trigger
-- set region, channel, rxagc, rxgain

-- by Qige @ 2017.03.22

local fmt = require 'six.fmt'
local cmd = require 'six.cmd'
local abb = require 'kpi.ABB'
local gws = require 'kpi.GWS'


local SScan = {}

SScan.conf = {}
SScan.conf.r0ch_min = 14
SScan.conf.r0ch_max = 51
SScan.conf.r1ch_min = 21
SScan.conf.r1ch_max = 51

SScan.conf._trigger = '/sys/kernel/debug/ieee80211/phy0/ath9k/chanscan'
SScan.conf._start = 'echo "scan enable" > %s; gws5001app setrxagc 0; sleep 1; gws5001app setrxgain 0\n'
SScan.conf._stop = 'echo "scan disable" > %s; sleep 1; gws5001app setrxagc 1\n'

SScan.conf._result = '/tmp/.grid_lite_chscan'
SScan.conf._clean = 'echo -n "" > %s\n'
SScan.conf._scan = 'gws -C %d; sleep 2\n'
SScan.conf._scan_item = '%d,%d,%d,%d,%d'
SScan.conf._save = 'echo "%s" >> %s\n'

SScan.current = {}
SScan.current.rgn = -1
SScan.current.ch = -1
SScan.current.agc = -1

function SScan.load()
    local _abb = abb.RAW()
    local _gws = gws.RAW()
    if (_gws and _gws.rgn ~= nil) then
        SScan.current.rgn = _gws.rgn
        SScan.current.ch = _gws.ch
        SScan.current.agc = _gws.agc
    end
end

function SScan.restore()
    local current = SScan.current
    if (current.rgn > -1) then
        if (current.rgn > 0) then
            GWS.ops.Set('rgn', 1)
        else
            GWS.ops.Set('rgn', 0)
        end
    end
    if (current.agc > -1) then
        if (current.rgn > 0) then
            GWS.ops.Set('agc', 1)
        else
            GWS.ops.Set('agc', 0)
        end
    end
    if (current.ch >= SScan.conf.r0ch_min) then
        GWS.ops.Set('ch', current.ch)
    end
end


function SScan.init()
    local _fmt = SScan.conf._start
    local _f = SScan.conf._trigger
    local _cmd = string.format(_fmt, _f)
    cmd.exec(_cmd)

    -- clean result cache
    _f = SScan.conf._result
    _fmt = SScan.conf._clean
    _cmd = string.format(_fmt, _f)
    cmd.exec(_cmd)
end

function SScan.stop()
    local _fmt = SScan.conf._stop
    local _f = SScan.conf._trigger
    local _cmd = string.format(_fmt, _f)
    cmd.exec(_cmd)
end

function SScan.Run(rgn, b, e)
    local _f = SScan.conf._result

    SScan.load()
    SScan.init()

    -- read noise after 1 second
    -- set next channel
    local _rgn = rgn or 1
    local _ch = b or SScan.conf.r1ch_min
    local _ech = e or SScan.conf.r1ch_max
    local _freq
    local _noise = -111
    local _item, _cmd
    local _fmt_scan = SScan.conf._scan
    local _fmt_scan_item = SScan.conf._scan_item
    local _fmt_save = SScan.conf._save
    local _ts, i
    
    for i = _ch, _ech do
        if (_rgn > 0) then
            _freq = 474+8*(i-21)
        else
            _freq = 473+6*(i-14)
        end
        _noise = abb.raw.Noise()
        _ts = os.time()

        _cmd = string.format(_fmt_scan, i)
        cmd.exec(_cmd)
        
        _item = string.format(_fmt_scan_item, _rgn, i, _freq, _noise, _ts)
        io.write(_item .. '\n')
        _cmd = string.format(_fmt_save, _item, _f)
        cmd.exec(_cmd)
    end

    SScan.stop()
    --SScan.restore()
end

return SScan
