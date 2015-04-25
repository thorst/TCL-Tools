if 0 {
	About
		Pretty print a tcl script. Recommended mass comment as if 0 {}.
	
	Dependencies
	_stringPad
	_stringCount
	
	History
		I wrote this initially in c#, and would ftp the file to a webserver,
		format it, and then ftp it back. With our new server we have web
		services on the box directly so I expose a web service that calls
		this.
	
	Example
		Format the script. Quotes would be needed if there was a space in the path
		
		_scriptFormat "/path/to/file.tcl"
		
		Over write the mass comments, You will need to send in all that you support, so it may
		be a good idea to include the default ones
		
		_scriptFormat "/path/to/file.tcl" [dict create comments [list "if \{1==3\} \{"]]
	
	Change Log:
		2015-04-01 Todd Horst
			-Initial version, port of c# code
		2015-04-24 Todd Horst
			-Ignore \{ and \}, people may have it in a string
			-Added [] everywhere there is a {}, as they also dictate indentation
			-Replace all tabs with "    ", the ide and my websites prefer spaces
			-Ignore formatting if its between an if 0 {}, trust the user
			-Ignore {}[] if after # later in a line
	
	TODO:
		-Do we need to handle line continuation specially? \
			I dont have a use case here
		-Do we need to immediatly handle \] like we do \}
}
#

if 0 {
	Here is the c# version
	As you can see the tcl version is much more robust.
	
	#string readText = "";
	#int depth = 0;
	#int newdepth = 0;
	#int tab = 4;
	#string line;
	#while (reader2.Peek() >= 0)
	#\{
	#	line = reader2.ReadLine().Trim();                       //Get the line of text
	#	newdepth += line.Count(f => f == '\{') * tab;            //For each opening bracket we indent another tab
	#	newdepth -= line.Count(f => f == '\}') * tab;            //For each closing bracket we outdent another tab
	#
	#	if (line == "\}") { depth = newdepth; }
	#	else if (line.StartsWith("\}")) { depth = newdepth - tab; }         //If this starts with close bracket we apply the newdepth immediately
	#
	#
	#	readText += new String(' ', depth) + line + "\r\n";
	#	depth = newdepth;
	#\}
}
#


proc _scriptFormat {script {options ""}} {
	
	set options [dict merge [dict create \
			comments [list \
				"if 0 \{" \
				"if \{0\} \{" \
				"if false \{" \
				"if \{false\} \{" \
				"if 1==2 \{" \
				"if \{1==2\} \{" \
			] \
	] $options]
	
	# Before we touch it back it up, just incase I mess it up
	file copy $script $script.FORMATTED.[clock format [clock seconds] -format %Y-%m-%d_%H.%M.%S]
	
	# Read file in
	set fl [open $script]
	set data [read $fl]
	close $fl
	
	# Init vars
	set depth 0
	set newdepth 0
	set olddepth 0
	set tab 4
	set tabStr [string repeat " " $tab]
	set commentDepth 0
	

	set newData ""
	foreach line [split $data \n] {
		# Create backups
		set olddepth $depth
		set lineBackup $line
		
		# We are in a mass comment, so we are gonna ignore
		# everything until its over, You format it the way you like
		if {[lsearch [dict get $options comments] $line] >=0 || $commentDepth>0} {
			
			# Add and subtract each {}
			incr commentDepth [_stringCount $line \{]
			incr commentDepth [expr [_stringCount $line \}] * -1]
			
			# Add the line as you wrote it
			lappend newData $line
			continue		
		}
		
		# Trim new lines
		set line [string trim $line]
		
		# Replace tabs with spaces, useful for comments with lots of tabs
		set line [string map {\t $tabStr} $line]
		
		# If this line starts with a comment, ignore any depth change.
		if {[string range $line 0 0]=="\#"} {
			
			# Append this line
			lappend newData [_stringPad $line $depth]
		}
		
		# Remove escaped {} [] #
		set lineTemp $line
		set lineTemp [string map {\\\{ "" \\\} ""} $lineTemp]
		set lineTemp [string map {\\\[ "" \\\] ""} $lineTemp]
		set lineTemp [string map {\\\# ""} $lineTemp]
		
		# Only care about everything before the first comment
		set lineTemp [lindex [split $lineTemp "\#"] 0]
		
		# Determine what the next line should be indented as, based on the occurence of curlies
		incr newdepth [expr [_stringCount $lineTemp \{] * $tab]
		incr newdepth [expr [_stringCount $lineTemp \}] * $tab * -1]
		
		# Square brackets also affect the indentation
		incr newdepth [expr [_stringCount $lineTemp \[] * $tab]
		incr newdepth [expr [_stringCount $lineTemp \]] * $tab * -1]		
		
		# If the line is just a closing make new depth immediate
		if {$line=="\}" || $line=="\]"} {
			set depth $newdepth
			
		# If the line starts with end curly make temporarily less indented, its an elseif 
		} elseif {[string range $line 0 0]=="\}"} {
			set depth [expr $newdepth-$tab]
		}
		
		# Append this line
		lappend newData [_stringPad $line $depth]
		
		# Commit new depth
		set depth $newdepth
	}

	# Write	out the formated file
	set fl [open $script w]
	puts -nonewline $fl [join $newData "\n"]
	close $fl
}
