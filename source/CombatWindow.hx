package ;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/**
 * Turn based combat window.
 * @author Kirill Poletaev
 */
class CombatWindow extends FlxSpriteGroup
{
	private var btn_attack:FlxButton;
	private var btn_flee:FlxButton;
	private var bg:FlxSprite;
	private var txt:FlxText;
	
	private var playState:PlayState;
	private var enemy:Enemy;
	
	private var sfx_hit:FlxSound;

	public function new(playState:PlayState) 
	{
		super();
		this.playState = playState;
		this.scrollFactor.x = 0;
		this.scrollFactor.y = 0;
		
		x = FlxG.width / 2 - 100;
		y = FlxG.height / 2 - 40;
		
		bg = new FlxSprite();
		add(bg);
		bg.makeGraphic(200, 80, 0xff222222);
		
		btn_attack = new FlxButton(5, 55, "Attack", onAttack);
		btn_flee = new FlxButton(115, 55, "Flee", onFlee);
		add(btn_attack);
		add(btn_flee);
		
		txt = new FlxText(5, 5, 190);
		add(txt);
		sfx_hit = FlxG.sound.load("assets/sounds/hit.wav");
	}
	
	public function fight(enemy:Enemy) {
		this.enemy = enemy;
		txt.text = "A wild enemy appears!";
	}
	
	private function onAttack() {
		sfx_hit.play();
		var dmg:Int = playState.hud.getLevel();
		enemy.health -= dmg;
		txt.text = "You hit the enemy, dealing " + dmg + " damage.";
		if (enemy.health > 0) {
			var enemyDmg:Int = Math.floor(Math.random()*2);
			txt.text += "\nThe enemy strikes, dealing " + enemyDmg + " damage.";
			playState.hud.addHealth( -enemyDmg);
		} else {
			playState.winCombat(enemy);
			playState.hud.addExp(6);
		}
	}
	
	private function onFlee() {
		playState.endCombat(enemy);
	}
}