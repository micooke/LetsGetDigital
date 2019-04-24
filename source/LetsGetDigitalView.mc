using Toybox.Time as Time;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.ActivityMonitor as ActMon;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;
using Toybox.Math as Math;
/*
char id=35 x=180    y=15     width=14    height=14    xoffset=0     yoffset=4     xadvance=14    page=0  chnl=15
char id=36 x=165     y=15     width=15    height=14    xoffset=0     yoffset=4     xadvance=15    page=0  chnl=15
*/
class LetsGetDigitalView extends Ui.WatchFace {

	hidden var smallDateFont, dateFont, timeFont, timeCheckerFont;
	
	hidden const ordinalIndicator = ["TH","ST","ND","RD","TH","TH","TH","TH","TH","TH"];
	hidden const engDay = ["","sun","mon","tue","wed","thu","fri","sat"];
	hidden const engMonth = ["","jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"];
	hidden const overstepGap = 2, overstepWidth = 3, mediumDateOffset = 5, halfMediumDateOffset = 3, stepArcWidth = 4;

	hidden const _DEBUG = false;

	hidden const dateFontHeight = 33*1.25;
	hidden const timeFontHeight = 59*1.05;
	//                           [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	hidden const timeFontWidth = [51,28,45,42,47,44,48,43,50,48]; // get this from the relevant fnt file (column width)
	hidden const smallDateFontHeight = 16;//3;
	// get this from the relevant fnt file (column xadvance)
	hidden const smallDateWidth = {" "=>6,"%"=>16,"0"=>11,"1"=>6,"2"=>10,"3"=>9,"4"=>10,"5"=>10,"6"=>10,"7"=>9,"8"=>11,"9"=>10,
					"A"=>11,"B"=>11,"C"=>9,"D"=>11,"E"=>10,"F"=>9,"G"=>11,"H"=>11,"I"=>6,"J"=>9,"K"=>11,"L"=>9,"M"=>14,
					"N"=>11,"O"=>11,"P"=>11,"Q"=>11,"R"=>11,"S"=>10,"T"=>10,"U"=>11,"V"=>11,"W"=>14,"X"=>11,"Y"=>11,"Z"=>9,
					"#"=>15,"$"=>16};
	
	// settings
	hidden var is24Hour, fourtwenty = false;
	hidden var isRoundface = 0;
	hidden var showSteps;
	hidden var backgroundColour, HourColour, MinuteColour, DateColour, InactiveColour;
	hidden var ActiveColour, OverActiveColour, WatchStyle;
	hidden var TimeCheckerplateStyle = -1, DateCheckerplateStyle = -1;
	
	// screen and font dimensions
	hidden var timeVerticalCentre, dateVerticalCentre, smallDateVerticalCentre;
  	hidden var screenWidth, halfScreenWidth, screenHeight, halfScreenHeight;

	function initialize()
	{
		WatchFace.initialize();
		updateSettings();
		
		loadCheckerplateFonts();
		
		timeFont = Ui.loadResource(Rez.Fonts.Digitalt);
		
		smallDateFont = Ui.loadResource(Rez.Fonts.DigitaltSmall);
	}
	
	function loadCheckerplateFonts()
	{
		var _TimeCheckerplateStyle = Application.getApp().getProperty("TimeCheckerplateStyle");
		var _DateCheckerplateStyle = Application.getApp().getProperty("DateCheckerplateStyle");
		
		if (TimeCheckerplateStyle != _TimeCheckerplateStyle)
		{
			TimeCheckerplateStyle = _TimeCheckerplateStyle;
			switch(TimeCheckerplateStyle) {
				case 1:
					timeCheckerFont = Ui.loadResource(Rez.Fonts.DigitaltChecker0);
					break;
				case 2:
					timeCheckerFont = Ui.loadResource(Rez.Fonts.DigitaltChecker1);
					break;
				case 3:
					timeCheckerFont = Ui.loadResource(Rez.Fonts.DigitaltChecker2);
					break;
				case 4:
					timeCheckerFont = Ui.loadResource(Rez.Fonts.DigitaltChecker3);
					break;
				case 5:
					timeCheckerFont = Ui.loadResource(Rez.Fonts.DigitaltChecker4);
					break;
				default:
					timeCheckerFont = Ui.loadResource(Rez.Fonts.Digitalt);
					break;
			}
		}
		if (DateCheckerplateStyle != _DateCheckerplateStyle)
		{
			DateCheckerplateStyle = _DateCheckerplateStyle;
			switch(DateCheckerplateStyle) {
				case 1:
					dateFont = Ui.loadResource(Rez.Fonts.DigitaltMediumChecker0);
					break;
				case 2:
					dateFont = Ui.loadResource(Rez.Fonts.DigitaltMediumChecker1);
					break;
				case 3:
					dateFont = Ui.loadResource(Rez.Fonts.DigitaltMediumChecker2);
					break;
				case 4:
					dateFont = Ui.loadResource(Rez.Fonts.DigitaltMediumChecker3);
					break;
				case 5:
					dateFont = Ui.loadResource(Rez.Fonts.DigitaltMediumChecker4);
					break;
				default:
					dateFont = Ui.loadResource(Rez.Fonts.DigitaltMedium);
					break;
			}
		}
	}

	function onLayout(dc) {
		getScreenDimensions(dc);
		updateSettings();
	}
	
	function getScreenDimensions(dc)
	{
		screenWidth = dc.getWidth();
   		halfScreenWidth = screenWidth/2;
   		screenHeight = dc.getHeight();
   		halfScreenHeight = screenHeight/2;
   		
   		timeVerticalCentre = halfScreenHeight - 0.5*timeFontHeight;
		dateVerticalCentre = halfScreenHeight - 0.4*dateFontHeight;
  		smallDateVerticalCentre = halfScreenHeight - 0.5*smallDateFontHeight;
  		
  		isRoundface = (screenWidth == screenHeight);
  		
  		if (_DEBUG) { System.print("H x W = "); System.print(screenWidth); System.print(" x "); System.println(screenHeight); }
	}
	
	function updateSettings() {
		// settings menu
		showSteps = Application.getApp().getProperty("ShowSteps");
    	backgroundColour = Application.getApp().getProperty("BackgroundColour");
		HourColour = Application.getApp().getProperty("HourColour");
		MinuteColour = Application.getApp().getProperty("MinuteColour");
		DateColour = Application.getApp().getProperty("DateColour");
		InactiveColour = Application.getApp().getProperty("InactiveColour");
		ActiveColour = Application.getApp().getProperty("ActiveColour");
		OverActiveColour = Application.getApp().getProperty("OverActiveColour");
		WatchStyle = Application.getApp().getProperty("WatchStyle");
		
		// watch settings
		var deviceSettings = System.getDeviceSettings();
		is24Hour = deviceSettings.is24Hour;
	}
	
	function onSettingsChanged() { // triggered by settings change in GCM
		updateSettings();        
    	WatchUi.requestUpdate();   // update the view to reflect changes
	}

	function onUpdate(dc) {
		//var t0 = Sys.getTimer();
		//updateSettings();
		loadCheckerplateFonts();
		
		// watch settings
		var deviceSettings = System.getDeviceSettings();
		var notificationCount = deviceSettings.notificationCount;
		if (_DEBUG)
		{
			notificationCount = 10;
			is24Hour = true;
		}
		
		// watch statistics
    	var batteryLevel = Sys.getSystemStats().battery;
		
		// get local time
		var clockTime = Sys.getClockTime();

		// Four Twenty ...
        if ( (clockTime.hour == 16) && (clockTime.min == 20) )
        {
        	backgroundColour = Gfx.COLOR_DK_GREEN;
        	HourColour = Gfx.COLOR_GREEN;
        	MinuteColour = Gfx.COLOR_WHITE;
        	InactiveColour = Gfx.COLOR_WHITE;
        	ActiveColour = Gfx.COLOR_GREEN;
        	OverActiveColour = Gfx.COLOR_WHITE;
        	fourtwenty = true;
        }

		if (clockTime.hour == 24) // Not sure if this is needed?
        {
            clockTime.hour = 0;
        }
        
		if ((!is24Hour) && (clockTime.hour > 12))
        {
            clockTime.hour -= 12;
        }
        
        if (_DEBUG)
		{
			clockTime.hour = 6;
		}
		
		// Call the parent onUpdate function to redraw the layout
		//View.onUpdate(dc);

		// setup the watch face
	    // draw the background
		dc.setColor(backgroundColour, backgroundColour);
		dc.clear();
        
		// get the date
		var clockDate = Calendar.info(Time.now(), Time.FORMAT_SHORT); // FORMAT_SHORT returns digits
		// get english only month and day
		var day_of_week = engDay[clockDate.day_of_week];
		var day = clockDate.day;
		var month = engMonth[clockDate.month];
		
		if (_DEBUG)
		{
			clockDate.day_of_week = "Sun"; clockDate.day = 2; clockDate.month = "Sep";
		}
		
		var dateString = toDateString(day_of_week, day, month, true);
		
		if (_DEBUG)
		{
			dateString = toDateString("Sun", 2, clockDate.month, true);
		}

		var dateStringSplit = [ day_of_week.toUpper(),
								day.toString() + ordinalIndicator[day % 10],
								month.toUpper()];
								
		if ((day > 10) && (day < 14))
        {
        	dateStringSplit[1] = day.toString() + "TH";
        } 

		// get the current step count
      	var ActInfo = ActMon.getInfo();
		var stepCount = ActInfo.steps;
		var stepGoal = ActInfo.stepGoal;
		var stepPercent = (stepCount == 0.0)?0.0:(stepCount.toFloat() / stepGoal);
		if (_DEBUG)
		{
			stepPercent = 2.65;
		}
        		
                
        // setup the time
		var hourLabel = clockTime.hour.format("%02d");
		var minuteLabel = clockTime.min.format("%02d");
		
		// meta parameters
		var overStepCount = stepPercent.toNumber();
	   	var fillPercent = stepPercent - overStepCount.toFloat();
		
		if (WatchStyle < 3)
		{
			// screen and font dimensions
	    	var hourWidth = timeFontWidth[clockTime.hour / 10] + timeFontWidth[clockTime.hour % 10];
	      	var minuteWidth = timeFontWidth[clockTime.min / 10] + timeFontWidth[clockTime.min % 10];

			var fontTopLR = [timeVerticalCentre - 0.5*timeFontHeight + 1, 
							dateVerticalCentre - dateFontHeight + 1];
			var fontHeightLR = [2*timeFontHeight, 
								3*dateFontHeight];
			var fontBottomLR = [fontTopLR[0] + fontHeightLR[0], 
							fontTopLR[1] + fontHeightLR[1]];
			var fillTopLR = [((1-fillPercent)*fontHeightLR[0] + fontTopLR[0]).toNumber(), 
							((1-fillPercent)*fontHeightLR[1] + fontTopLR[1]).toNumber()];
			var fillHeightLR = [(fillPercent*fontHeightLR[0]).toNumber(), 
								(fillPercent*fontHeightLR[1]).toNumber()];

			if (WatchStyle == 0)
			{
				/// draw the step count
				// draw the empty portion
				dc.setColor(InactiveColour, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(halfScreenWidth + mediumDateOffset, fontTopLR[1], halfScreenWidth - mediumDateOffset, fillTopLR[1] - fontTopLR[1]);
				
				// draw the full portion
				dc.setColor(ActiveColour, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(halfScreenWidth + mediumDateOffset, fillTopLR[1], halfScreenWidth - mediumDateOffset, fillHeightLR[1]);

				// draw the over-full indicators
				dc.setColor(OverActiveColour, Gfx.COLOR_TRANSPARENT);
				for (var index = 0; index < overStepCount; index++)
		     	{
		     		var vStart = fillTopLR[1] + (overstepGap + overstepWidth)*index;
		     		dc.fillRectangle(halfScreenWidth + mediumDateOffset, vStart, halfScreenWidth - mediumDateOffset, overstepWidth); 
		      	}
		        
				// draw the date
				dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColour);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre - dateFontHeight, dateFont, endPad(dateStringSplit[0],8," "), Gfx.TEXT_JUSTIFY_LEFT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre                 , dateFont, endPad(dateStringSplit[1],8," "), Gfx.TEXT_JUSTIFY_LEFT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre + dateFontHeight, dateFont, endPad(dateStringSplit[2],8," "), Gfx.TEXT_JUSTIFY_LEFT);
							
				// draw the battery percent
				drawBatteryLevel(dc, batteryLevel);

			    // draw the notification count
    			drawNotificationCount(dc, notificationCount);

			
				// draw the time
				dc.setColor(HourColour, Gfx.COLOR_TRANSPARENT);
				if (clockTime.hour < 10)
				{
					dc.drawText(halfScreenWidth - timeFontWidth[clockTime.hour], timeVerticalCentre - 0.5*timeFontHeight, timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
					dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				}
				else
				{
					dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, hourLabel, Gfx.TEXT_JUSTIFY_RIGHT);	
				}
				dc.setColor(MinuteColour, Gfx.COLOR_TRANSPARENT);
				dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_RIGHT);
			}
			else if (WatchStyle == 1)
			{
				// draw the step count
				// draw the empty portion
				dc.setColor(InactiveColour, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(0, fontTopLR[0], halfScreenWidth, fillTopLR[0] - fontTopLR[0]);
				// draw the full portion
				dc.setColor(ActiveColour, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(0, fillTopLR[0], halfScreenWidth, fillHeightLR[0]);
				// draw the over-full indicators
				dc.setColor(OverActiveColour, Gfx.COLOR_TRANSPARENT);
				for (var index = 0; index < overStepCount; index++)
				{
					var vStart = fillTopLR[1] + (overstepGap + overstepWidth)*index;
					dc.fillRectangle(0, vStart, halfScreenWidth, overstepWidth); 
				}

				// black out the LHS of the time
				dc.setColor(backgroundColour, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(0, timeVerticalCentre - 0.5*timeFontHeight, halfScreenWidth - hourWidth + 1, timeFontHeight+1);
  				dc.fillRectangle(0, timeVerticalCentre + 0.5*timeFontHeight, halfScreenWidth - minuteWidth + 1, timeFontHeight+1);
		        
				// draw the date
				dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre - dateFontHeight, dateFont, dateStringSplit[0], Gfx.TEXT_JUSTIFY_LEFT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre                 , dateFont, dateStringSplit[1], Gfx.TEXT_JUSTIFY_LEFT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre + dateFontHeight, dateFont, dateStringSplit[2], Gfx.TEXT_JUSTIFY_LEFT);
							
				// draw the battery percent
				drawBatteryLevel(dc, batteryLevel);

			    // draw the notification count
    			drawNotificationCount(dc, notificationCount);
			
				// draw the time
				dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColour);
				if (clockTime.hour < 10)
				{
					dc.drawText(halfScreenWidth - timeFontWidth[clockTime.hour], timeVerticalCentre - 0.5*timeFontHeight, timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
					dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				}
				else
				{
					dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, hourLabel, Gfx.TEXT_JUSTIFY_RIGHT);	
				}
				dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColour);
				dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_RIGHT);
			}
			else if (WatchStyle == 2)
			{
				// draw the step count
		        var fontTop = min(fontTopLR);
		        var fontBottom = max(fontBottomLR);
		        var fontHeight = fontBottom - fontTop; 
		        var fillTop = ((1-fillPercent)*fontHeight + fontTop).toNumber();
		        var fillHeight = (fillPercent*fontHeight).toNumber();	        
		        
		        // draw the empty portion
		        dc.setColor(InactiveColour, Gfx.COLOR_TRANSPARENT);
		        dc.fillRectangle(0, fontTop, halfScreenWidth, fillTop - fontTop); // LHS - time side
		        dc.fillRectangle(halfScreenWidth + mediumDateOffset, fontTopLR[1], halfScreenWidth - mediumDateOffset, fillTop - fontTopLR[1]); // RHS - date side
		        // draw the full portion
		        dc.setColor(ActiveColour, Gfx.COLOR_TRANSPARENT);
		        dc.fillRectangle(0, fillTop, halfScreenWidth, fillHeight); // LHS - time side
		        dc.fillRectangle(halfScreenWidth + mediumDateOffset, fillTop, halfScreenWidth - mediumDateOffset, fillHeightLR[1]); // RHS - date side
		        // draw the over-full indicators
		        dc.setColor(OverActiveColour, Gfx.COLOR_TRANSPARENT);
		        for (var index = 0; index < overStepCount; index++)
		     	{
		     		var vStart = fillTop + (overstepGap + overstepWidth)*index;
		     		dc.fillRectangle(0, vStart, halfScreenWidth, overstepWidth); // LHS - time side
		     		if (((vStart + overstepWidth) > fontTopLR[1]) && ((vStart + overstepWidth) <= fontBottomLR[1])) 
		     		{
		     			vStart = max([vStart, fontTopLR[1]]);
		     			var osWidth = min([fontBottomLR[1] - vStart, overstepWidth]); 
		     			dc.fillRectangle(halfScreenWidth + mediumDateOffset, vStart, halfScreenWidth - mediumDateOffset, osWidth); // RHS - date side
	     			}
		        }
		        
		        // black out the LHS of the time
		        dc.setColor(backgroundColour, Gfx.COLOR_TRANSPARENT);
		        dc.fillRectangle(0, timeVerticalCentre - 0.5*timeFontHeight, halfScreenWidth - hourWidth + 1, timeFontHeight+1);
		        dc.fillRectangle(0, timeVerticalCentre + 0.5*timeFontHeight, halfScreenWidth - minuteWidth + 1, timeFontHeight+1);
		        // black out the RHS under the date
		        dc.fillRectangle(halfScreenWidth + mediumDateOffset, fontBottomLR[1], halfScreenWidth - mediumDateOffset, fontBottomLR[0] - fontBottomLR[1]);
		        
				// draw the date
				dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColour);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre - dateFontHeight, dateFont, endPad(dateStringSplit[0],8," "), Gfx.TEXT_JUSTIFY_LEFT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre                 , dateFont, endPad(dateStringSplit[1],8," "), Gfx.TEXT_JUSTIFY_LEFT);
	        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre + dateFontHeight, dateFont, endPad(dateStringSplit[2],8," "), Gfx.TEXT_JUSTIFY_LEFT);
										
				// draw the battery percent
				drawBatteryLevel(dc, batteryLevel);

				// draw the notification count
    			drawNotificationCount(dc, notificationCount);
			
				// draw the time
				dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColour);
				if (clockTime.hour < 10)
				{
					dc.drawText(halfScreenWidth - timeFontWidth[clockTime.hour], timeVerticalCentre - 0.5*timeFontHeight, timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
					dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_RIGHT);
				}
				else
				{
					dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, hourLabel, Gfx.TEXT_JUSTIFY_RIGHT);	
				}
				dc.setColor(Gfx.COLOR_TRANSPARENT, backgroundColour);
				dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_RIGHT);
			}
		}
		else if (WatchStyle == 3)
		{
			// draw the step count
	        var fillHeight = ((1-fillPercent) * screenHeight).toNumber();
	        // draw the empty portion
	        dc.setColor(backgroundColour, Gfx.COLOR_TRANSPARENT);
	        dc.fillRectangle(0, 0, screenWidth, fillHeight);
	        // draw the full portion
	        dc.setColor(ActiveColour, Gfx.COLOR_TRANSPARENT);
	        dc.fillRectangle(0, fillHeight, screenWidth, screenHeight - fillHeight);
	        // draw the over-full indicators
	        dc.setColor(OverActiveColour, Gfx.COLOR_TRANSPARENT);
	        for (var index = 0; index < overStepCount; index++)
	     	{
	     		var vStart = fillHeight + (overstepGap + overstepWidth)*index;
	     		dc.fillRectangle(0, vStart, screenWidth, overstepWidth); 
	        }
	        
	        // draw the date
			dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);
        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre - dateFontHeight, dateFont, dateStringSplit[0], Gfx.TEXT_JUSTIFY_LEFT);
        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre                 , dateFont, dateStringSplit[1], Gfx.TEXT_JUSTIFY_LEFT);
        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre + dateFontHeight, dateFont, dateStringSplit[2], Gfx.TEXT_JUSTIFY_LEFT);
			
			// draw the battery percent
        	drawBatteryLevel(dc, batteryLevel);

		    // draw the notification count
			drawNotificationCount(dc, notificationCount);
		
			// draw the time
			dc.setColor(HourColour, Gfx.COLOR_TRANSPARENT);
			if (clockTime.hour < 10)
			{
				dc.drawText(halfScreenWidth - timeFontWidth[clockTime.hour], timeVerticalCentre - 0.5*timeFontHeight, timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_RIGHT);
			}
			else
			{
				dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, hourLabel, Gfx.TEXT_JUSTIFY_RIGHT);	
			}
			dc.setColor(MinuteColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_RIGHT);
		}
		else if (WatchStyle == 4)
		{
			// draw the step count
			drawStepCount(dc, stepPercent, stepArcWidth, HourColour, MinuteColour);
			
			// draw the date
			dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);
        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre - dateFontHeight, dateFont, dateStringSplit[0], Gfx.TEXT_JUSTIFY_LEFT);
        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre                 , dateFont, dateStringSplit[1], Gfx.TEXT_JUSTIFY_LEFT);
        	dc.drawText(halfScreenWidth + mediumDateOffset, dateVerticalCentre + dateFontHeight, dateFont, dateStringSplit[2], Gfx.TEXT_JUSTIFY_LEFT);
			
			// draw the battery percent
        	drawBatteryLevel(dc, batteryLevel);

		    // draw the notification count
			drawNotificationCount(dc, notificationCount);
			
			// draw the time
			dc.setColor(HourColour, Gfx.COLOR_TRANSPARENT);
			if (clockTime.hour < 10)
			{
				dc.drawText(halfScreenWidth - timeFontWidth[clockTime.hour], timeVerticalCentre - 0.5*timeFontHeight, timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_RIGHT);
			}
			else
			{
				dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, hourLabel, Gfx.TEXT_JUSTIFY_RIGHT);	
			}
			dc.setColor(MinuteColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_RIGHT);
		}
		else if (WatchStyle == 5)
		{
			// draw the step count
			drawStepCount(dc, stepPercent, stepArcWidth, HourColour, MinuteColour);

			// draw the date
			dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);
        	var dateXOffsets = getSmallDateOffsets(dateString);
			var dateYOffsets = getY_onArc(dateXOffsets, halfScreenHeight - (stepArcWidth + 1));
			drawTextArray(dc, dateString, halfScreenWidth, stepArcWidth + 1, dateXOffsets, dateYOffsets);

			// draw the battery percent and notification count in line
			var batteryLevelString = batteryLevel.format("%d") + "%";
			if (notificationCount > 0)
			{
				batteryLevelString = notificationCount.format("%d") + "#  " + batteryLevelString; 
			}
        	var batteryXOffsets = getSmallDateOffsets(batteryLevelString);
			var batteryYOffsets = getY_onArc(batteryXOffsets, halfScreenHeight - stepArcWidth);
			batteryYOffsets = multiplyByScalar(batteryYOffsets,-1);
			drawTextArray(dc, batteryLevelString, halfScreenWidth, screenHeight - (stepArcWidth + 1 + 1.2*smallDateFontHeight), batteryXOffsets, batteryYOffsets);

			// draw the time
			var hourTens = clockTime.hour / 10;
			var hourUnits = clockTime.hour % 10;
			
			var hourXOffset = (timeFontWidth[hourTens] - timeFontWidth[hourUnits])/2;
			
			dc.setColor(HourColour, Gfx.COLOR_TRANSPARENT);
			if (clockTime.hour < 10)
			{
				dc.drawText(halfScreenWidth - hourXOffset, timeVerticalCentre - 0.5*timeFontHeight, timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText(halfScreenWidth + hourXOffset, timeVerticalCentre - 0.5*timeFontHeight, timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_LEFT);
			}
			else
			{
				dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*timeFontHeight, timeFont, hourLabel, Gfx.TEXT_JUSTIFY_CENTER);	
			}

			dc.setColor(MinuteColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*timeFontHeight, timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_CENTER);
		}
		else
		{
			// draw the step count
			drawStepCount(dc, stepPercent, stepArcWidth, HourColour, MinuteColour);
			
			// draw the date
			dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);
        	dc.drawText(halfScreenWidth, smallDateVerticalCentre, smallDateFont, dateString, Gfx.TEXT_JUSTIFY_CENTER);
			
			// draw the battery percent
        	drawBatteryLevel(dc, batteryLevel);

		    // draw the notification count
			drawNotificationCount(dc, notificationCount);
			
			// draw the time
			var hourTens = clockTime.hour / 10;
			var hourUnits = clockTime.hour % 10;
			
			var hourXOffset = (timeFontWidth[hourTens] - timeFontWidth[hourUnits])/2;
			
			dc.setColor(HourColour, Gfx.COLOR_TRANSPARENT);
			if (clockTime.hour < 10)
			{
				dc.drawText(halfScreenWidth - hourXOffset, timeVerticalCentre  - 0.5*(smallDateFontHeight + timeFontHeight), timeCheckerFont, "0", Gfx.TEXT_JUSTIFY_RIGHT);
				dc.drawText(halfScreenWidth + hourXOffset, timeVerticalCentre  - 0.5*(smallDateFontHeight + timeFontHeight), timeFont, (clockTime.hour).toString(), Gfx.TEXT_JUSTIFY_LEFT);
			}
			else
			{
				dc.drawText(halfScreenWidth, timeVerticalCentre - 0.5*(smallDateFontHeight + timeFontHeight), timeFont, hourLabel, Gfx.TEXT_JUSTIFY_CENTER);	
			}

			dc.setColor(MinuteColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText(halfScreenWidth, timeVerticalCentre + 0.5*(smallDateFontHeight + timeFontHeight), timeFont, minuteLabel, Gfx.TEXT_JUSTIFY_CENTER);
		}
		
		if (fourtwenty)
		{
			fourtwenty = false;
		   updateSettings();
		}
		/*
		var t1 = Sys.getTimer();
		System.print("exe time = ");
		System.print(t1 - t0);
		System.println(" ms");
		*/
	}
			
	function toDateString(dotw, day, month, UseUpperCase)
	{
		var dateString = Lang.format("$1$ $2$ $3$", [dotw, day, month]);

		return (UseUpperCase)?dateString.toUpper():dateString;
	}
	
	function drawArc(dc, degreeStart, degreeEnd, stepArcWidth, arcColour)
	{
		dc.setColor(arcColour, Gfx.COLOR_TRANSPARENT);
		if (degreeEnd > 90)
        {
        	if ((degreeStart > 90) == false)
        	{
         		dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth, Gfx.ARC_CLOCKWISE, 90 - degreeStart, 0);
         		dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth, Gfx.ARC_CLOCKWISE, 0, 360 - (degreeEnd - 90));
         	}
         	else
         	{
         		dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth, Gfx.ARC_CLOCKWISE, 360 - (degreeStart - 90), 360 - (degreeEnd - 90));
         	}
		}
        else
        {
        	dc.drawArc(halfScreenWidth, halfScreenHeight, halfScreenWidth - stepArcWidth, Gfx.ARC_CLOCKWISE, 90 - degreeStart, 90 - degreeEnd);         	
        }
	}
	
	function drawOverStepPos(dc, stepPercent, arcWidth, MinuteColour)
    {
	     dc.setColor(MinuteColour, Gfx.COLOR_TRANSPARENT);
         dc.setPenWidth(arcWidth);
         
         var overStepCount = stepPercent.toNumber();
         var arcPercent = stepPercent - overStepCount.toFloat();
         
         var arcSwathDeg = overstepWidth;
         var arcGapDeg = overstepGap;
     	 
     	 for (var index = 0; index < overStepCount; index++)
     	 {
     	 	var degreeEnd = 360 * arcPercent - (arcGapDeg + arcSwathDeg)*index;
     	 	var degreeStart = degreeEnd - arcSwathDeg;
     	 
     	 	drawArc(dc, degreeStart, degreeEnd, arcWidth, MinuteColour);	
     	 }
     	 
    }
    
    function drawStepCount(dc, stepPercent, arcWidth, HourColour, MinuteColour)
    {
    	if ((stepPercent > 0.0) and (showSteps))
		 {
	         dc.setColor(HourColour, Gfx.COLOR_TRANSPARENT);
	         dc.setPenWidth(arcWidth);
	         var degreeStart = 0;
	         
	         var degreeEnd = degreeStart;
	         if (stepPercent > 1.0)
	         {
	         	degreeEnd += (360 - degreeStart);
	         }
	         else
	         {
	         	degreeEnd += (360 - degreeStart)*stepPercent;
	         }
         	
         	 drawArc(dc, degreeStart, degreeEnd, arcWidth, HourColour);
         	 	         
	         if (stepPercent > 1.0)
	         {
	         	drawOverStepPos(dc, stepPercent, arcWidth, MinuteColour);
	         }
        }
    }
    
    // draw the notification count
    function drawNotificationCount(dc, notificationCount)
    {
	    if (isRoundface)
        {
			drawNotificationCountAtHeight(dc, notificationCount, 6);
        }
        else
        {
			drawNotificationCountAtHeight(dc, notificationCount, -2);
		}
    }
    
    function drawNotificationCountAtHeight(dc, notificationCount, height)
    {
		if (notificationCount > 0)
		{
			dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText(halfScreenWidth - 1, height, smallDateFont, notificationCount.format("%d")+"#", Gfx.TEXT_JUSTIFY_CENTER);
		}
    }
    
    function drawBatteryLevel(dc, batteryLevel)
    {
    	var batteryLevelString = batteryLevel.format("%d") + "%";
		dc.setColor(DateColour, Gfx.COLOR_TRANSPARENT);

    	if (isRoundface)
        {
			dc.drawText(halfScreenWidth, screenHeight - 1.6*smallDateFontHeight, smallDateFont, batteryLevelString, Gfx.TEXT_JUSTIFY_CENTER);
		}
		else
		{
			dc.drawText(halfScreenWidth, screenHeight - 1.1*smallDateFontHeight, smallDateFont, batteryLevelString, Gfx.TEXT_JUSTIFY_CENTER);
		}
	}
    
    function drawTextArray(dc, in_string, x_0, y_0, x_offsets, y_offsets)
    {
    	for (var c=0; c < x_offsets.size(); ++c)
    	{
    		dc.drawText(x_0 + x_offsets[c], y_0 + y_offsets[c], smallDateFont, in_string.substring(c,c+1), Gfx.TEXT_JUSTIFY_CENTER);
		}
    }
    
    function getY_onArc(x_offsets, radius)
    {
    	var y_offsets = new[x_offsets.size()];
    	var radius_squared = Math.pow(radius,2);
    	for (var c=0; c < x_offsets.size(); ++c)
    	{
    		y_offsets[c] = radius - Math.sqrt(radius_squared - Math.pow(x_offsets[c],2));
    	}
    	return y_offsets;
    }

	function getSmallDateOffsets(in_string)
	{
		var in_length = in_string.length();
		var out_lengths = new[in_length];
		
		// determine cumulative length
		out_lengths[0] = smallDateWidth.get(in_string.substring(0,1));
		for (var c=1; c < in_length; ++c)
		{
			out_lengths[c] = out_lengths[c-1] + smallDateWidth.get(in_string.substring(c,c+1));
		}
		
		// re-centre the lengths
		var halfActualLength = Math.round(out_lengths[in_length - 1]/2);
		if ((in_length % 2) == 1) // odd length
		{
			// it looks more natural to put the middle char in the middle
			halfActualLength = out_lengths[(in_length/2).toNumber()];
		}
		
		out_lengths = addScalar(out_lengths, -halfActualLength);
		
		return out_lengths;
	}

    function endPad(in_string, out_length, pad_value)
    {
    	var out_string = in_string;
    	for (var p=in_string.length(); p < out_length; ++p)
    	{
    		out_string += pad_value;
    	}
    	
    	return out_string;
    }
    
    function max(in_array)
    {
    	var maximum = in_array[0]; 
    	for (var i=0; i < in_array.size(); ++i)
    	{
    		if (maximum < in_array[i])
    		{
    			maximum = in_array[i];
    		}
    	}
    	return maximum;
    }

    function min(in_array)
    {
    	var minimum = in_array[0]; 
    	for (var i=0; i < in_array.size(); ++i)
    	{
    		if (minimum > in_array[i])
    		{
    			minimum = in_array[i];
    		}
    	}
    	return minimum;
    }

    function addScalar(in_array, in_scalar)
    {
    	var out_array = in_array;
    	for (var i=0; i < in_array.size(); ++i)
    	{
    		out_array[i] += in_scalar;
    	}
    	return out_array; 
    }
    
    function multiplyByScalar(in_array, in_scalar)
    {
    	var out_array = in_array;
    	for (var i=0; i < in_array.size(); ++i)
    	{
    		out_array[i] *= in_scalar;
    	}
    	return out_array; 
    }
    
    /*
    function split(s, sep) {
	    var tokens = [];
	
	    var found = s.find(sep);
	    while (found != null) {
	        var token = s.substring(0, found);
	        tokens.add(token);
	
	        s = s.substring(found + sep.length(), s.length());
	
	        found = s.find(sep);
	    }
	
	    tokens.add(s);
	
	    return tokens;
	}
	*/
}
