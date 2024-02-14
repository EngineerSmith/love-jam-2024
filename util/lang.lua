local logger = require("util.logger")
local utf8 = require("util.utf8")
local insert, sort = table.insert, table.sort

local defaultLocale = "en"
local lang = {
  localeKey = defaultLocale,
  defaultLocale = defaultLocale,
  locales = { ["none"] = { } },
  pseudonym = { },
}

lang.importLocale = function(localeKey, locale)
  localeKey = localeKey:lower()
  if lang.locales[localeKey] then
    local locale, n, o = lang.locales[localeKey], 0, 0
    for k, v in pairs(locale) do
      if type(k) == "string" and type(v) == "string" then
        if locale[k] then o = o + 1 end
        locale[k] = v
        n = n + 1
      elseif k == "locale.pseudonym" and type(v) == "table" then
        for _, pseudonym in ipairs(v) do
          lang.pseudonym[pseudonym] = localeKey
        end
      else
        logger.warn("LocaleKey", localeKey, "tried to add non-string value:", k, "=", v, ", refused to add")
      end
    end
    if n > 0 then
      logger.info("Added", n, "entries to language", localeKey, "and overrode", o, "entries")
    else
      logger.warn("Did not add any entries for locale", localeKey)
    end
  else
    local n = 0
    for k, v in pairs(locale) do
      if type(k) ~= "string" and type(v) ~= "string" then
        logger.warn("LocaleKey", localeKey, "tried to add non-string value:", k, "=", v, ", refused to add")
        locale[k] = nil
      elseif k == "locale.pseudonym" and type(v) == "table" then
        for _, pseudonym in ipairs(v) do
          lang.pseudonym[pseudonym] = localeKey
        end
      else
        n = n + 1
      end
    end
    if n > 0 then
      lang.locales[localeKey] = locale
      logger.info("Added", n, "entries to language", localeKey)
    else
      logger.warn("Did not add any entries for locale", localeKey)
    end
    lang.dirty = true
  end
end

lang.setLocale = function(localeKey)
  localeKey = localeKey:lower()
  if not lang.locales[localeKey] then
    local oldKey = localeKey
    localeKey = lang.pseudonym[localeKey]
    if not localeKey or not lang.locales[localeKey] then
      logger.warn("Attempted to switch to", localeKey, "language, but no entries found for that language")
      return false
    else
      logger.info("Used pseudonym for", oldKey, "redirected to", localeKey)
    end
  end
  lang.localeKey = localeKey
  return true
end

local alphabeticalSort = function(a, b) return a.name < b.name end

lang.getLocales = function()
  if lang.dirty then
    local locales = {}
    for localeKey, locale in pairs(lang.locales) do
      insert(locales, {
        locale = localeKey,
        name = locale["locale"] or localeKey,
        active = localeKey == lang.localeKey,
      })
    end
    sort(locales, alphabeticalSort)
    lang._getLocales = locales
    lang.dirty = false
    return locales
  else
    return lang._getLocales
  end
end

lang.format = function(string, ...)
  for i = 1, select("#", ...), 1 do
    string = utf8.gsub(string, "$"..i, tostring(select(i, ...)))
  end
  return string
end

lang.getTextLocale = function(localeKey, stringKey, ...)
  if localeKey == "none" then return stringKey end
  local string
  if lang.locales[localeKey] then
    string = lang.locales[localeKey][stringKey]
  elseif lang.locales[lang.defaultLocale] then
    string = lang.locales[lang.defaultLocale][stringKey]
  else
    logger.warn("Default language has no entries. Requested key:", stringKey)
    return stringKey
  end
  return string and lang.format(string, ...) or stringKey
end

lang.getText = function(stringKey, ...)
  return lang.getTextLocale(lang.localeKey, stringKey, ...)
end

return lang