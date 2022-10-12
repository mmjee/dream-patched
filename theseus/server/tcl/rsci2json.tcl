#package provide rsci2json 1.0

package require json::write
package require rsci

if ![info exists SE127_PROTOCOL] {
    #puts "SE127_PROTOCOL undefined, defaulting to DCP!\n\r"
	set SE127_PROTOCOL DCP
}

if {$SE127_PROTOCOL == "DCP"} {
	package require dcp
	namespace import dcp::*
}

if {$SE127_PROTOCOL == "IPIO"} {
	package require ipio
	namespace import ipio::*
}

proc TagItem2JSON {tagName byteLength data} {
      global SE127_VERSION 

	if {[string range $tagName 0 0] == "x"} {
		# Process statistics tag - output is list of alternating statistic and value (e.g. 0 19.8 50 20.3 100 21.9)
		set baseTagName "r[string range $tagName 1 3]"
		binary scan $data "Sc" nFrames nStats
		set decodedTag [list $nFrames]
		set byteLenPerStat [expr ($byteLength - 3) / $nStats]
		set tag [list]
            for {set i 3} {$i<$byteLength} {incr i $byteLenPerStat} {
			binary scan [string range $data $i $i] "c" statistic
			lappend decodedTag $statistic
			set subTag [ProcessTagItem $baseTagName [expr $byteLenPerStat - 1] [string range $data [expr $i + 1] [expr $i + $byteLenPerStat - 1]]]
			lappend decodedTag $subTag
		}
		return $decodedTag 
	}
	if {$tagName == "rast"} {
	    binary scan $data "SS" totalFrames correctFrames
            return [json::write object "total_frames" $totalFrames "correct_frames" $correctFrames]
	}

	if {$tagName == "dlfc"} {
	    binary scan $data "I"  decodedTag
	    return $decodedTag
	}
	
	if {$tagName == "robm"} {
	    binary scan $data "c" decodedTag 
	    set decodedTag [expr ($decodedTag + 0x100)%0x100]
	    return $decodedTag
	}

	if {$tagName == "rdmo"} {
	    binary scan $data "a4" decodedTag
          return $decodedTag
      }

	if {$tagName == "fmjd"} {
	    binary scan $data "II" mjd tms 
	    set decodedTag [json::write object "mjd" $mjd "tms" $tms]
	    return $decodedTag
	}

	# andrewm - 20070228 - GPS TAG decode
	if {$tagName == "rgps"} {
		set decodedTag [list]
	    set count [binary scan $data "ccScSScSSccccSccSS" source satellites latDD latM \
			latmm longDD longM longmm altAA alta timeH timeM timeS dateYY dateM dateD speed heading]
        if {$count == 18} {
		
	      set latM [expr { $latM & 0xff }]
	      set latmm [expr { $latmm & 0xffff }]

	      set latDeg [expr { ( $latDD + ( $latM + $latmm/65536.0) / 60.0 ) }]

	      set longM [expr { $longM & 0xff }]
	      set longmm [expr { $longmm & 0xffff }]
	      set longDeg [expr { ( $longDD + ( $longM + $longmm/65536.0) / 60.0 ) }]

          set alta [expr { $alta & 0xff }]
          set altMetres [expr { $altAA + ( $alta / 60.0 ) }]

	      set speed [expr { $speed & 0xffff }]
	      set heading [expr { $heading & 0xffff }]

	      set decodedTag [json::write object "lat_deg" $latDeg "long_deg" $longDeg "alt_metres" $altMetres "year" $dateYY "month" $dateM "day" $dateD "hour" $timeH "minute" $timeM "second" $timeS "speed" $speed "heading" $heading]
        } 

	    return $decodedTag
	}

	if {$tagName == "rfre"} {
	    binary scan $data "I" decodedTag
	    return $decodedTag
	}		

	if {$tagName == "rmer"} {

	    # Init list
	    set decodedTag [list]

	    # Go though every value and store
	    for {set i 0} {$i<$byteLength} {incr i 2} {
		set subData [string range $data $i [expr $i+1]]
		binary scan $subData "cc" byte1 byte2
		set byte2 [expr ($byte2 + 0x100)%0x100]
		lappend decodedTag [format "%.0f" [expr $byte1+$byte2/256.0]]
	    }
	    

	    # In case that we are using se127 v2 or lower, copy rmer value to rwmf
	    if {$SE127_VERSION <3} {
		set tags(rwmf) $tags(rmer)
	    }

	    return [json::write array {*}$decodedTag]
	}	

	if {$tagName == "rwmf"} {

	    # Init list
	    set decodedTag [list]

	    # Go though every value and store
	    for {set i 0} {$i<$byteLength} {incr i 2} {
		set subData [string range $data $i [expr $i+1]]
		binary scan $subData "cc" byte1 byte2
		set byte2 [expr ($byte2 + 0x100)%0x100]
		lappend decodedTag [format "%.0f" [expr $byte1+$byte2/256.0]]
	    }
	    return [json::write array {*}$decodedTag]
	}	

	if {$tagName == "rwmm"} {

	    # Init list
	    set decodedTag [list]

	    # Go though every value and store
	    for {set i 0} {$i<$byteLength} {incr i 2} {
		set subData [string range $data $i [expr $i+1]]
		binary scan $subData "cc" byte1 byte2
		set byte2 [expr ($byte2 + 0x100)%0x100]
		lappend decodedTag [format "%.0f" [expr $byte1+$byte2/256.0]]
	    }
	    return [json::write array {*}$decodedTag]
	}	

	if {$tagName == "rser"} {
	    binary scan $data "c" decodedTag 
	    return $decodedTag
	}

	if {$tagName == "rdel"} {
	    # Init list
	    set decodedTag [list]

	    # Go though every value and store
	    for {set i 0} {$i<$byteLength} {incr i 3} {
		set subData [string range $data $i [expr $i+2]]
		binary scan $subData "ccc" percentage byte1 byte2
		set byte2 [expr ($byte2 + 0x100)%0x100]
		lappend decodedTag [json::write object "percentage" $percentage "delay" [format "%.1f" [expr $byte1+$byte2/256.0]]]
	    }
	    return [json::write array {*}$decodedTag]
	}

	if {$tagName == "Bdia"} {
		binary scan $data "cB8SScccB8a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4Sca4" \
	       dummy rxStat dspStat mlcStat audioStat cpuLoad drmMode stickyFlags \
	       minFP maxFP minTCS maxTCS minSe maxSe \
	       csiMean csiPeak csiPos csiPk2Mn \
	       cirPeak cirPos \
	       mass1 mass1Pos mass2 doppler \
	       cwPos attenuation bufferFP

		# Use Bdiag doppler if we are in version 2 or lower of the se127 protocol
		if {$SE127_VERSION < 3} {
			set tags(rdop) [format "%.1f" [IEEE2float $doppler 0]]
		}
	}

	if {$tagName == "rdbv"} {

	    # Init list
	    set decodedTag [list]

	    # Go though every value and store
	    for {set i 0} {$i<$byteLength} {incr i 2} {
		set subData [string range $data $i [expr $i+1]]
		binary scan $subData "cc" byte1 byte2
		set byte2 [expr ($byte2 + 0x100)%0x100]
		lappend decodedTag [format "%.0f" [expr $byte1+$byte2/256.0]]
	    }
	    return [json::write array {*}$decodedTag]
	}	

	if {$tagName == "rsta"} {
	    binary scan $data "cccc" byte0 byte1 byte2 byte3
	    set byte0 [expr ($byte0 + 0x100)%0x100]
	    set byte1 [expr ($byte1 + 0x100)%0x100]
	    set byte2 [expr ($byte2 + 0x100)%0x100]
	    set byte3 [expr ($byte3 + 0x100)%0x100]
	    set decodedTag [json::write object "sync" $byte0 "fac" $byte1 "sdc" $byte2 "audio" $byte3]
	    return $decodedTag
	}

	if {$tagName == "rbp0" || $tagName == "rbp1" || $tagName == "rbp2" || $tagName == "rbp3"} {
	    binary scan $data "SS" byte0 byte1
	    set byte0 [expr ($byte0 + 0x10000)%0x10000]
	    set byte1 [expr ($byte1 + 0x10000)%0x10000]
	    set decodedTag [json::write object "errors" $byte0 "bits" $byte1]
	    return $decodedTag
	}

	if {$tagName == "rbw_"} {
	    binary scan $data "cc" byte1 byte2
	    set byte2 [expr ($byte2 + 0x100)%0x100]
	    set decodedTag [format "%.2f" [expr $byte1+$byte2/256.0]]
	    return $decodedTag
	}	


	if {$tagName == "rafs"} {
	    binary scan $data "cB8B8B8B8B8" noOfFrames b1 b2 b3 b4 b5
	    set bitString [string range $b1$b2$b3$b4$b5 0 [expr $noOfFrames-1]]
	    set decodedTag [json::write string $bitString]
	    return $decodedTag
	}	


	if {$tagName == "rdop"} {
	    binary scan $data "cc" byte1 byte2
	    set byte2 [expr ($byte2 + 0x100)%0x100]
	    set decodedTag [format "%.2f" [expr $byte1+$byte2/256.0]]
	    return $decodedTag
	}	

	if {$tagName == "rinf"} {
	   binary scan $data "a4a2a2a2a6" company implementation major minor serial
	   set decodedTag [json::write object "company" $company "implementation" $implementation "major" $major "minor" $minor "serial" $serial]
	   return $decodedTag 
	}

#	if {$tagName == "str0"} {
#	    set decodedTag ""
#	    return $decodedTag
#	}

	# All other tags: Use data as it is
	set decodedTag [json::write string [binary encode base64 $data]]

	return $decodedTag
}

proc TagContent2JSON {tagContent tagsVar} {

    # Expects binary string with tag content and returns array <tags>
    # which contains alls TAGS reference in the string

    upvar $tagsVar tags
    global SE127_VERSION 

    set pointer 0;
    set contentLength [string length $tagContent]
    set tagsJSONList [list]

#    set outString ""
#    for {set i 0} {$i<=[string length $tagContent]} {incr i} {
#	binary scan [string range $tagContent $i $i] "c" byte
#	set byte [expr ($byte+0x100)%0x100]
#	append outString [format "%02x " $byte]#
#	if {[expr $i%16] == 15} {
#	    append outString "\n"
#	}
#    }
#    DisplayData $outString

    # Go through individual tags
    while {$pointer != $contentLength} {

	# Tag name
	set tagName [string range $tagContent $pointer [expr $pointer+3]]

	# If the tag name has illegal characters, return with -1 error
	if ![regexp {[a-zA-Z0-9_]} $tagName] {
		puts "Tag name $tagName is illegal. Skipping packet"
		return -1
	}

	# Data length in bytes
	binary scan [string range $tagContent [expr $pointer+4] [expr $pointer+7]] "I" dataBitSize
	set byteLength [expr $dataBitSize/8]

	# Output length
	DisplayData "      $tagName\t$byteLength"

	# Treat empty tags
	if {$byteLength == 0} {
		#TODO!
	    #set tags($tagName) ""

	    # Advance pointer
	    set pointer [expr $pointer+8+$byteLength]

	    continue
	}

	# Treat tags with data
	set data [string range $tagContent [expr $pointer+8] [expr $pointer+7+$byteLength]]

	# Advance pointer
	set pointer [expr $pointer+8+$byteLength]

	# Process the tag item body according to the tag name
	lappend tagsJSONList $tagName [TagItem2JSON $tagName $byteLength $data]
    }

    set tags [json::write object {*}$tagsJSONList]

    ########### Put this in since the receiver occasionally seems to forget to send AFS 
    # Look into this in the new year
    # Boy: I guess this is because occasionaly some UDP-packets get messed up and
    #      not all the tags are correctly received, there was an error
    #      calling this function from recordall.tcl, it was fixed.
    #
    #if ![info exists tags(rafs)] {
   # 	return -1
   # }
}


proc GetTagJSON {tty tagsVar binaryFrameVar} {
    global SE127_PROTOCOL

    # Reads next SUDP packet from serial port and extracts tag content into tags.
    # The whole packet including header is returned in binaryFrameVar

    upvar $tagsVar tags
    upvar $binaryFrameVar binaryFrame

    # Data is returned in 3 binary segments: (IO)id, (IO)header and IO(payload)

	set binarySegments [ReadPacket $tty]

    set id [lindex $binarySegments 0]
    set header [lindex $binarySegments 1]
    set tagContent [lindex $binarySegments 2]

    # Compose binary frame
    set binaryFrame $id$header$tagContent

    # Return -1 if error occurred
    if {$tagContent == -1 || $binarySegments == -1} {
	puts "Error in packet!"
	return -1
    }

    # Process the TAG content
    if {[TagContent2JSON $tagContent tags] == -1} {
    	puts "Error with tags!"
	return -1
    }

    puts $tags

   return 0
}

