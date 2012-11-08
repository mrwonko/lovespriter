local lovespriter = require("code/lovespriter")

local spriterCharacter, errorMessage = lovespriter.loadFile( "tests/testchar/testchar.scml" )
if not spriterCharacter then
	error( errorMessage, 0 )
end