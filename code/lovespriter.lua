--[[
	@brief Parses (a subset of) XML
	
	Might only support ASCII characters.
	
	Elements (such as the rootNode returned) look like this:
	@code
	{
		name = "name",
		attributes =
		{
			keyN = "valueN"
		},
		content = -- may be missing for <emptyElements/>
		{
			elements = { childElements },
			charData = "character data"
		}
	}
	@endcode
	
	@param xmlData string containing the XML data
	
	@return On success: rootNode
	        On failure: nil, errorMessage
--]]
local function ParseSimpleXML( xmlData )
	local namePattern = "[%a_:][%a%d%.%-_:]*";
	
	-- skip <?xml ... ?> header - caution: it is optional!
	if xmlData:sub( 0, 5 ) == "<?xml" then
		local xmlDeclEnd = xmlData:find( ">" ) -- first character has index 1
		if not xmlDeclEnd then
			return nil, "Unclosed <?xml tag!" 
		end
		xmlData = xmlData:sub( xmlDeclEnd + 1 )
	end
	
	local ParseElement --forward declaration
	
	local function ParseElementContent()
		local elements = {}
		local charData = {}

		local elementOver = false
		while not elementOver do
			-- find the next child element / this element's end
			local ltPos = xmlData:find("<") -- first character has index 1
			if ltPos then
				-- there might not be any < if this is the toplevel call
				
				-- charData must not contain ]]>
				if xmlData:sub( 1, ltPos - 1 ):find( "%]%]>" ) then
					return nil, "Stray ]]> found!"
				end
				
				-- save charData (might be empty, we don't care)
				charData[ #charData + 1 ] = xmlData:sub( 1, ltPos - 1 )
				
				-- remove charData
				xmlData = xmlData:sub( ltPos )
			else
				-- charData must not contain ]]>
				if xmlData:find( "%]%]>" ) then
					return nil, "Stray ]]> found!"
				end
				
				-- save charData (might be empty, we don't care)
				charData[ #charData + 1 ] = xmlData
				
				xmlData = ""
			end
			
			-- end of this element?
			if xmlData:sub( 1, 2 ) == "</" or not ltPos then
				-- end loop, we're done with the content
				elementOver = true
			
			-- or a comment?
			elseif xmlData:sub( 1, 4 ) == "<!--" then
				-- skip comments.
				local _, commentEnd = xmlData:find( "%-%->" )
				if not commentEnd then
					return nil, "Unexpected EOF! (Unterminated comment)"
				end
				xmlData = xmlData:sub( commentEnd + 1 )
			
			-- or a processing instruction?
			elseif xmlData:sub( 1, 2 ) == "<?" then
				-- we ignore those.
				local _, PIEnd = xmlData:find( "%?>" )
				if not PIEnd then
					return nil, "Unexpected EOF! (Unterminated Processing Instruction)"
				end
				xmlData = xmlData:sub( PIEnd + 1 )
			
			-- or a CDATA section?
			elseif xmlData:sub( 1, 9) == "<![CDATA[" then
				-- we ignore those.
				local _, CDATAEnd = xmlData:find( "%]%]>" )
				if not CDATAEnd then
					return nil, "Unexpected EOF! (Unterminated CDATA Section)"
				end
				xmlData = xmlData:sub( CDATAEnd + 1 )
			
			-- otherwise there should be a child element here.
			else
				local element, errorMessage = ParseElement()
				
				if not element then
					return nil, errorMessage
				end
				elements[ #elements + 1 ] = element
			end
		end
		return {
			childElements = elements,
			charData = table.concat( charData )
		}
	end
	
	function ParseElement()
		-- find out name
		local all, name = xmlData:match( "^(<(" .. namePattern .. ")%s*)" )
		if not name then
			return nil, "Invalid element/-name"
		end
		xmlData = xmlData:sub( all:len() + 1 )
		
		-- find out attributes
		local attributes = {}
		local attributePattern = "^((" .. namePattern .. ")%s*=%s*\"([^\"&<]*)\"%s*)"
		local all, key, value = xmlData:match( attributePattern )
		while all and key and value do
			attributes[ key ] = value
			xmlData = xmlData:sub( all:len() + 1 )
			all, key, value = xmlData:match( attributePattern )
		end
		
		-- nothing else ought to be there
		if xmlData:sub( 1, 2 ) == "/>" then
			xmlData = xmlData:sub( 3 )
			return {
				name = name,
				attributes = attributes,
				content = nil
			}
		end
		if xmlData:sub( 1, 1 ) ~= ">" then
			return nil, "Invalid element tag!"
		end
		
		xmlData = xmlData:sub( 2 )
		
		-- parse content
		local content, errorMessage = ParseElementContent()
		if not content then
			return nil, errorMessage
		end
		
		-- look for end tag
		
		-- create search-safe version of the name (i.e. escape pattern-specific stuff )
		local nameSafe = name:gsub( "[%^%$%(%)%%%.%[%]%*%+%-%?]", function( specialChar ) return "%" .. specialChar end )
		
		local all = xmlData:match( "</" .. nameSafe .. "%s*>" )
		
		if not all then
			return nil, "Element not properly closed!"
		end
		
		xmlData = xmlData:sub( all:len() + 1 )
		
		return {
			name = name,
			attributes = attributes,
			content = content
		}
	end
	
	local rootContent, errorMessage = ParseElementContent()
	
	if not rootContent then
		return nil, errorMessage
	end
	
	if #rootContent.childElements ~= 1 then
		return nil, "Not exactly one root element!"
	end
	
	if rootContent.charData:find( "[^%s]" ) then
		return nil, "Loose charData!: " .. rootContent.charData
	end
	
	return rootContent.childElements[1]
end

_G.ParseSimpleXML = ParseSimpleXML