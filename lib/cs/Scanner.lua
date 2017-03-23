-- @param: region, channel begin/end
-- cache current region, channel, rxagc, rxgain
-- set scscan trigger, set region, channel, set rxagc=0, rxgain=0
-- > scan each channel
-- > print format: <rgn>,<ch>,<freq>,<noise>,<ts>
-- clean chscan trigger
-- set region, channel, rxagc, rxgain

local fmt = require 'six.fmt'
local cmd = require 'six.cmd'

local cs = {}

function cs.Run()
end

return cs
