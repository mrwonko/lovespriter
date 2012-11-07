require("code/lovespriter")

-- local xmlData = love.filesystem.read( "tests/test.xml" )
local xmlData = love.filesystem.read( "tests/testchar/testchar.scml" )

assert( type( xmlData ) == "string" )

local rootNode, errorMessage = ParseSimpleXML( xmlData )


if not rootNode then
	error( errorMessage )
end

local fileInfo = { "\n" }
local function addInfo( str )
	fileInfo[ #fileInfo + 1 ] = str
end

local function nodeToString( node )
	addInfo( "<" )
	addInfo( node.name )
	for key, val in pairs( node.attributes ) do
		addInfo( " " )
		addInfo( key )
		addInfo( " = \"" )
		addInfo( val )
		addInfo( "\"" )
	end
	if node.content then
		addInfo( ">" )
		for _, child in ipairs( node.content.childElements ) do
			nodeToString( child )
		end
		addInfo( node.content.charData )
		addInfo( "</" )
		addInfo( node.name )
		addInfo( ">" )
	else
		addInfo( "/>" )
	end
end

local function nodeToStringNoCharData( node )
	addInfo( "<" )
	addInfo( node.name )
	for key, val in pairs( node.attributes ) do
		addInfo( " " )
		addInfo( key )
		addInfo( " = \"" )
		addInfo( val )
		addInfo( "\"" )
	end
	if node.content then
		addInfo( ">\n" )
		for _, child in ipairs( node.content.childElements ) do
			nodeToStringNoCharData( child )
		end
		addInfo( "</" )
		addInfo( node.name )
		addInfo( ">" )
	else
		addInfo( "/>\n" )
	end
end

nodeToStringNoCharData( rootNode )

error( table.concat( fileInfo ) )