# Read common code and global variables
source SettingsRemoteMonitoring.tcl

package require http ;
# Include support for UDP
package require udp

set HTTP_TIMEOUT 10000
set ROOT_DIR2 "/tmp"

proc SendRxCommand {commandXML} {

	global CONTROL_PORT
	# connect to mediator
	set ttyRxCommand [udp_open]
	fconfigure $ttyRxCommand -remote [list localhost $CONTROL_PORT]
	fconfigure $ttyRxCommand -buffering none -translation binary

	# send the command
	puts $ttyRxCommand "$commandXML"
	flush $ttyRxCommand

	close $ttyRxCommand
}

proc SetFrequency {rxID freq mode} {

	set command "<cfre rxID=\"$rxID\" mode=\"$mode\"> $freq</cfre>"
	SendRxCommand $command
}

proc ProcessStatusData {ttyMediator rxID} {

	

	global socketBuffer
	global endTimeSeconds
	global waitVar

	# This function is called when data is sent on TCP socket 

	#puts "Received stuff on socket $socket $addr:$port"
	#
	


	if [eof $ttyMediator] {
		puts "EOF"
		catch {close $ttyMediator}
		return
	}

	set inData [read $ttyMediator]

	# Check whether end time has passed
	#if {[clock seconds] > $endTimeSeconds} {
#		return
#	}


	# prepend anything we have received already
	if {$socketBuffer != ""} {
		set inData "$socketBuffer$inData"
	}

	set id "AF"

	while {[string length $inData] != 0} {
		# find the AF (TODO add PF)

		set startPos [string first $id $inData] 
		if {$startPos == -1} {
			# AF was not found, so store the story so far in the buffer and wait for more data
			set socketBuffer $inData
			return
		}

		# We have found an AF somewhere

		# trim off everything before the AF
		set inData [string range $inData $startPos end]

		set headerLen 10
		if {[string length $inData] < $headerLen} {
			# not enough data for header
			set siteSocketBuffers($socket) $inData
			return
		}

		set len_field [string range $inData 2 6]

		# Decode header
		binary scan $len_field "I" len 

		# Convert to unsigned numbers
		set len [expr ($len + 0x1000000)%0x1000000]

		# puts [format "DCP: len: %4x\t seq: %4x\tcrc: %1x\tversion: %x.%x %s" $len $seq $crc $maj $min $pt]

		# If the length is greater than 10000 bytes, there is an error
		if {$len > 10000} {
			# packet length too long - AF string might be data mimicing header. Throw away input
			puts "Error! Packet size is long: $len bytes. Ignoring."
			set socketBuffer ""
			return
		}

		if {[string length $inData] < [expr $len + $headerLen]} {
			# not enough data for the payload left, so store and wait for more data
			set socketBuffer $inData
			return
		}

			
		# Read <len> payload bytes
		set packet [string range $inData 0 [expr $len + $headerLen + 1] ]

		set inData [string range $inData [expr $len + $headerLen + 2] end]

		set fmjd_pos [string first "fmjd" $packet]
		if {$fmjd_pos >= 0} {
			set fmjd_payload [string range $packet [expr $fmjd_pos + 8] [expr $fmjd_pos + 15] ]
			binary scan $fmjd_payload "II" mjd tms
			puts "Found fmjd: $mjd , $tms"
			set frame_datetime [clock scan [string cat "1970-01-01 00:00:00 GMT + " [expr $mjd - 40587] " days + " [expr $tms / 10000] " seconds"]]
			set frame_milliseconds [expr ( $tms / 10 ) % 1000]

		
			set frame_seconds [clock format $frame_datetime -format "%s" ]
			set seconds_remaining [expr $endTimeSeconds - $frame_seconds]
			puts "Frame seconds: $frame_seconds End seconds: $endTimeSeconds time remaining: $seconds_remaining"
			if {$seconds_remaining <=0} {
				set waitVar 1
				return
			}
			WriteRSCIFile $rxID $frame_datetime $frame_milliseconds $packet
		}

	}

	set socketBuffer $inData

}
	


proc WriteRSCIFile {rxID frame_datetime frame_milliseconds packet} {
	set filename [MakeSinglePacketFileName $rxID $frame_datetime $frame_milliseconds]
	puts "writing $filename"
	set ttyFile [OpenRSCIFile $filename]
	puts -nonewline $ttyFile $packet
	close $ttyFile
}

proc MakeSinglePacketFileName {rxID frame_datetime frame_milliseconds} {
  global RSI_FILES_ROOT
  #set currentMilliseconds [clock milliseconds]
  #set currentTime [expr $currentMilliseconds / 1000]
  #set currentMilliseconds [expr $currentMilliseconds % 1000]
  set strMilliseconds [format "%03d" $frame_milliseconds]

  set strDate [clock format $frame_datetime -format "%Y-%m-%d" -gmt 1]
  set strHHMMSS [clock format $frame_datetime -format "%H-%M-%S" -gmt 1]
  set dir [file join $RSI_FILES_ROOT "$rxID" "${strDate}"]
  file mkdir $dir
  return [file join "$dir" "${rxID}_${strDate}_${strHHMMSS}_${strMilliseconds}.rsA"]
}

proc OpenRSCIFile {fileName} {
  puts "Opening file: $fileName"
  set ttyFile [open $fileName w]
  fconfigure $ttyFile -translation binary
  return $ttyFile
}
##### Main #####

# cmd line args
set rxID [lindex $argv 0]
set recordTime [lindex $argv 1]
set freq [lindex $argv 2]

# Set rx frequency
SetFrequency $rxID $freq "drm_"

# Calculate end time to prevent recording running on if event pump is busy. Add on some margin to give time for all the relevant frames to be processed.
set endTimeSeconds [expr [clock seconds] + $recordTime + 5]


# connect to mediator
set socketBuffer ""
set ttyMediator [socket localhost $SUBSCRIBERS_SERVER_PORT]
fconfigure $ttyMediator -translation binary -blocking 0
fileevent $ttyMediator readable [list ProcessStatusData $ttyMediator $rxID]

# request the required ID
puts $ttyMediator "$rxID"
flush $ttyMediator

set waitVar 0
puts "Record time = $recordTime"
set recordTimeMilliseconds [expr $recordTime * 1000]
puts "RecordTimeMilliseconds=${recordTimeMilliseconds}"
#after [expr $recordTime * 1000] {set waitVar 1}
vwait waitVar

close $ttyMediator
if [info exists ttyFile] {
  close $ttyFile
}


puts "exiting"


