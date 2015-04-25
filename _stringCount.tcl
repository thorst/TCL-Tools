if 0 {
	Purpose:
		Count the occurences of char in str
	
	Playground:
		puts [_stringPad "Mississippi" i]
		>> 4
	
	Change Log:
	2015-04-01 Todd Horst
		Initial version
		
	TODO:
	-Specify case sensitive
}
#

proc _stringCount {str char} {
	return [llength [split $str $char]]
}
#
