package ;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxBar;

/**
 * RPG HUD.
 * @author Kirill Poletaev
 */
class HUD extends FlxSpriteGroup
{
	private var healthDisplay:FlxText;
	private var levelDisplay:FlxText;
	private var expBar:FlxBar;
	
	public var hp:Int;
	public var maxHp:Int;
	public var exp:Int;
	public var maxExp:Int;
	public var level:Int;
	
	private var sfx_levelup:FlxSound;
	
	public function new() 
	{
		super();
		scrollFactor.x = 0;
		scrollFactor.y = 0;
		
		healthDisplay = new FlxText(2, 2);
		hp = 5;
		maxHp = 10;
		add(healthDisplay);
		
		levelDisplay = new FlxText(2, 12);
		level = 1;
		add(levelDisplay);
		
		maxExp = 10;
		exp = 0;
		expBar = new FlxBar(4, 25, FlxBar.FILL_LEFT_TO_RIGHT, 100, 4);
		expBar.createFilledBar(0xFF63460C, 0xFFE6AA2F);
		add(expBar);
		
		sfx_levelup = FlxG.sound.load("assets/sounds/levelup.wav");
	}
	
	override public function update() {
		healthDisplay.text = "Health: " + hp + "/" + maxHp;
		levelDisplay.text = "Level: " + level;
		expBar.currentValue = exp;
		expBar.setRange(0, maxExp);
	}
	
	public function addHealth(num:Int):Void {
		hp += num;
		if (hp > maxHp) {
			hp = maxHp;
		}
		if (hp <= 0) {
			FlxG.switchState(new MenuState());
		}
	}
	
	public function addExp(num:Int):Void {
		exp += num;
		while (exp > maxExp) {
			level++;
			exp -= maxExp;
			maxExp = Math.ceil(maxExp * 1.3);
			hp++;
			maxHp++;
			sfx_levelup.play();
		}
	}
	
	public function getLevel():Int {
		return level;
	}
	
}