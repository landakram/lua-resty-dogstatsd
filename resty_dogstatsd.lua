local resty_statsd = require('resty_statsd')

local dogstatsd = {
   metadata = {
      -- general
      tags = '#',

      -- event
      date_happened    = 'd:',
      hostname         = 'h:',
      aggregation_key  = 'k:',
      priority         = 'p:',
      source_type_name = 's:',
      alert_type       = 't:',

      -- service_check
      timestamp = 'd:',
      hostname  = 'h:',
      message   = 'm:',
   }
}

local function is_array(x)
  return type(x) == "table" and x[1] ~= nil
end

local function serialize_tags(tags)
   if is_array(tags) then
      return tags
   end

   local serialized_tags = {}
   for key, value in pairs(tags) do
      table.insert(serialized_tags, key .. ':' .. value)
   end
   return serialized_tags
end

function dogstatsd.new(config)
   local statsd = resty_statsd(config.statsd)

   statsd.send_to_socket = function(self, string)
      local payload = self.parent:serialize_payload(string)
      return self.udp:send(payload)
   end

   local obj = {
      statsd = statsd,
      config = config,
      meta = {},
   }
   statsd.parent = setmetatable(obj, {__index = dogstatsd})
   return statsd.parent
end

local function merge_tags(lhs, rhs)
   local tag_set = {}

   for _, tag in pairs(serialize_tags(lhs)) do
      tag_set[tag] = true
   end

   for _, tag in pairs(serialize_tags(rhs)) do
      tag_set[tag] = true
   end

   local tags = {}

   for key, _ in pairs(tag_set) do
      table.insert(tags, key)
   end

   return tags
end

function dogstatsd:serialize_payload(string)
   for key, value in pairs(self.meta) do
      if key == 'tags' then
         local tags = merge_tags(self.config.tags or {}, value)
         value = table.concat(tags, ',')
      end
      string = string .. '|' .. self.metadata[key] .. value
   end

   return string
end

-- ----- ----- ----- ----- -----
-- DogStatsd Original Function
-- ----- ----- ----- ----- -----

function dogstatsd:event(title, text, meta)
   self.meta = meta or {}
   return self.statsd:send_to_socket('_e{'..string.len(title)..','..string.len(text)..'}:'..title..'|'..text)
end

function dogstatsd:service_check(name, status, meta)
   self.meta = meta or {}
   return self.statsd:send_to_socket('_sc|'..name..'|'..status)
end

-- ----- ----- ----- ----- -----
-- Statsd Function With Tags
-- ----- ----- ----- ----- -----

function dogstatsd:gauge(stat, value, sample_rate, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:gauge(stat, value, sample_rate)
end

function dogstatsd:counter(stat, value, sample_rate, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:counter(stat, value, sample_rate)
end

function dogstatsd:increment(stat, value, sample_rate, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:increment(stat, value, sample_rate)
end

function dogstatsd:decrement(stat, value, sample_rate, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:decrement(stat, value, sample_rate)
end

function dogstatsd:timer(stat, ms, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:timer(stat, ms)
end

function dogstatsd:histogram(stat, value, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:histogram(stat, value)
end

function dogstatsd:meter(stat, value, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:meter(stat, value)
end

function dogstatsd:set(stat, value, tags)
   self.meta = {tags = tags or {}}
   return self.statsd:set(stat, value)
end

return dogstatsd
