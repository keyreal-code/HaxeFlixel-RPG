package ;
import flixel.FlxSprite;

class Potion extends FlxSprite
{

	public function new() 
	{
		super();
		loadGraphic("assets/images/potion.png", false, 16, 16);
	}
	
}