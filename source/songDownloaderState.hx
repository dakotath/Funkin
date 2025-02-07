package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import flixel.addons.ui.FlxUIDropDownMenu;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;

class SongDownloaderState extends FlxState
{
      public static inline var DEFAULT_BYTES_NAME = 'file.bin';
      public static inline var DEFAULT_BYTES_TYPE = 'application/octet-stream';
	static inline var NUM_BOXES:Int = 20;

	// We're just going to drop a bunch of boxes into a group
	var _boxGroup:FlxTypedGroup<FlxButton>;

	// We'll use these variables for the dragging
	var dragOffset:FlxPoint;
	var _dragging:Bool = false;
	var _dragTarget:FlxObject;

	// Buttons for the demo
	var _saveButton:FlxButton;
	var _loadButton:FlxButton;
	var _clearButton:FlxButton;
	var _file:FileReference;

	// The top text that yells at you
	var _topText:FlxText;
	var magenta:FlxSprite;

	override public function create():Void
	{
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('downloaderBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);
            FlxG.mouse.visible = true;
            var mods:Array<String> = [];
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			var http = new haxe.Http("https://raw.githubusercontent.com/dakotath/Funkin/master/modList.txt");
			var returnedData:Array<String> = [];
			http.onData = function(data:String)
			{
                        var modData:haxe.DynamicAccess<String> = haxe.Json.parse(data);
				returnedData[0] = data.substring(0, data.indexOf(';'));
				returnedData[1] = data.substring(data.indexOf('-'), data.length);
            		var mods:Array<String> = returnedData;
				_boxGroup = new FlxTypedGroup<FlxButton>();
				// And let's make some boxes!
                        var i = 0;
				for (key => value in modData)
				{
                              i++;
					var box:FlxButton;
					box = new FlxButton((i * 74) + 9, 50, key, function()
                              {
                                  downloadMod(value);
                              });
					if (i * 35 > 1080)
					{
						box.setPosition((i * 74 - 2) - 339, 85);
					}
					_boxGroup.add(box);
				}
				add(_boxGroup); // Add the group to the state

			}
			http.onError = function(error)
			{
				trace('error: $error');
				FlxG.switchState(new MainMenuState()); // fail but we go anyway
			}
		 	http.request();
		 });
            //_file = new FileReference();
            //_file.save("hello world.", "test.json");
		// Since we need the text before the usual end of the demo we'll initialize it up here.
		_topText = new FlxText(0, 2, FlxG.width, "Welcome!");
		_topText.alignment = 'center';

		// This just makes some dim text with instructions
		var dragText:FlxText = new FlxText(0, 0, "Mod downloader");
		dragText.color = FlxColor.WHITE;
		dragText.alpha = 1;
		dragText.size = 24;
		add(dragText);

		// Set out offset to non-null here
		dragOffset = FlxPoint.get(0, 0);

		// Get out buttons set up along the bottom of the screen
		var buttonY:Int = FlxG.height - 22;

		_saveButton = new FlxButton(2, buttonY, "Save Locations", onSave);
		add(_saveButton);
		_loadButton = new FlxButton(82, buttonY, "Load Locations", onLoad);
		add(_loadButton);
		_clearButton = new FlxButton(202, buttonY, "Clear Save", onClear);
		add(_clearButton);

		// Let's not forget about our old text, which needs to be above everything else
		add(_topText);
	}

	override public function update(elapsed:Float):Void
	{
		// This is just to make the text at the top fade out
		if (_topText.alpha > 0)
		{
			_topText.alpha -= .005;
		}

		super.update(elapsed);

		// If you've clicked, lets see if you clicked on a button
		// Note something like this needs to be after super.update() that way the button's state has updated to reflect the mouse event
		if (FlxG.mouse.justPressed)
		{
			for (box in _boxGroup)
			{
				if (box.pressed)
				{
					// The offset is used to make the box stick to the cursor and not snap to the corner
					dragOffset.set(box.x - FlxG.mouse.x, box.y - FlxG.mouse.y);
					_dragging = true;
					_dragTarget = box;
				}
			}
		}

		// If you let go, then release that box!
		if (FlxG.mouse.justReleased)
		{
			_dragTarget = null;
			_dragging = false;
		}

		// And lets move the box around
		if (_dragging)
		{
			_dragTarget.setPosition(FlxG.mouse.x + dragOffset.x, FlxG.mouse.y + dragOffset.y);
		}
	}

	/**
	 * Called when the user clicks the 'Save Locations' button
	 */
	function onSave():Void
	{
		// Do we already have a save? if not then we need to make one
		if (FlxG.save.data.boxPositions == null)
		{
			// Let's make a new array at the location data/
			// don't worry, if its not there - then flash will make a new variable there
			// You can also do something like gameSave.data.randomBool = true;
			// and if randomBool didn't exist before, then flash will create a boolean there.
			// though it's best to make a new type() before setting it, so you know the correct type is kept
			var boxPositions = new Array();

			for (box in _boxGroup)
			{
				boxPositions.push(FlxPoint.get(box.x, box.y));
			}

			FlxG.save.data.boxPositions = boxPositions;

			_topText.text = "Created a new save, and saved positions";
			_topText.alpha = 1;
		}
		else
		{
			// So we already have some save data? lets overwrite the data WITHOUT ASKING! oooh so bad :P
			// Now we're not doing a real for-loop here, because i REALLY like for each, so we'll need our own index count
			var tempCount:Int = 0;

			// For each button in the group boxGroup - I'm sure you see why I like this already
			for (box in _boxGroup)
			{
				FlxG.save.data.boxPositions[tempCount] = FlxPoint.get(box.x, box.y);
				tempCount++;
			}

			_topText.text = "Overwrote old positions";
			_topText.alpha = 1;
		}
		FlxG.save.flush();
	}

	/**
	 * Called when the user clicks the 'Load Locations' button
	 */
      function downloadMod(modUrl:String = "")
      {
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
                  _file = new FileReference();
			var http = new haxe.Http(modUrl);
			var returnedData:Array<String> = [];
			http.onData = function(data:String)
			{
                        var decoded = haxe.crypto.Base64.decode(data);
                        //var bytes = haxe.Resource.getBytes(decoded.toString());
                        //trace(bytes.getData());
                        _file.save(decoded.getData(), "mod.json");
			}
			http.onError = function(error)
			{
				trace('error: $error');
				FlxG.switchState(new MainMenuState()); // fail but we go anyway
			}
		 	http.request();
		 });
            //_file.save("hello world.", "test.json");
      }
	function onLoad():Void
	{
		// Loading what? Theres no save data!
		if (FlxG.save.data.boxPositions == null)
		{
			_topText.text = "Failed to load - There's no save";
			_topText.alpha = 1;
		}
		else
		{
			// Note that above I saved the positions as an array of FlxPoints, When the SWF is closed and re-opened the Types in the
			// array lose their type, and for some reason cannot be re-cast as a FlxPoint. They become regular Flash Objects with the correct
			// variables though, so you're safe to use them - just your IDE won't highlight recognize and highlight the variables
			var tempCount:Int = 0;

			for (box in _boxGroup)
			{
				box.x = FlxG.save.data.boxPositions[tempCount].x;
				box.y = FlxG.save.data.boxPositions[tempCount].y;
				tempCount++;
			}

			_topText.text = "Loaded positions";
			_topText.alpha = 1;
		}
	}

	/**
	 * Called when the user clicks the 'Clear Save' button
	 */
	function onClear():Void
	{
		FlxG.save.erase();
		_topText.text = "Save erased";
		_topText.alpha = 1;
	}
}
