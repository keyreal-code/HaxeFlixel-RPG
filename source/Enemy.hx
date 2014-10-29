package ;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;

/**
 * Enemy
 * @author Kirill Poletaev
 */
class Enemy extends FlxSprite
{
	public var path:FlxPath;
	private var wandering:Bool;
	private var wanderTicks:Int;
	private var nodes:Array<FlxPoint>;
	private var tilemap:FlxTilemap;
	private var hero:FlxSprite;

	public function new(tilemap:FlxTilemap, hero:FlxSprite) 
	{
		super();
		this.tilemap = tilemap;
		this.hero = hero;
		
		loadGraphic("assets/images/enemy.png", true, PlayState.TILE_WIDTH, PlayState.TILE_HEIGHT);
		animation.add("down", [0, 1, 0, 2]);
		animation.add("up", [3, 4, 3, 5]);
		animation.add("right", [6, 7, 6, 8]);
		animation.add("left", [9, 10, 9, 11]);
		
		path = new FlxPath();
		
		animation.play("down");
		
		wandering = true;
		wanderTicks = Std.int(Math.random() * 300);
	}
	
	override public function update() {
		super.update();
		
		if (wandering) {
			var startPoint:FlxPoint = FlxPoint.get(x + PlayState.TILE_WIDTH / 2, y + PlayState.TILE_HEIGHT / 2);
			var heroPoint:FlxPoint = FlxPoint.get(hero.x + PlayState.TILE_WIDTH / 2, hero.y + PlayState.TILE_HEIGHT / 2);
			
			if (hero.active && tilemap.ray(startPoint, heroPoint)) {
				var pathToHero:Array<FlxPoint> = tilemap.findPath(startPoint, heroPoint, false);
				if(pathToHero.length <= 5){
					wanderTicks = 300;
					path.start(this, pathToHero);
				}
			}
			
			if (wanderTicks > 0) {
				wanderTicks--;
			} else {
				wanderTicks = Std.int(Math.random() * 300);
				while (nodes == null || nodes.length == 0) {
					var tileCoordY:Int = Std.int(startPoint.y / PlayState.TILE_WIDTH + Math.ceil(Math.random()*6) - 3);
					var tileCoordX:Int = Std.int(startPoint.x / PlayState.TILE_HEIGHT + Math.ceil(Math.random()*6) - 3);
					var endPoint = FlxPoint.get(tileCoordX * PlayState.TILE_WIDTH + PlayState.TILE_WIDTH / 2, tileCoordY * PlayState.TILE_HEIGHT + PlayState.TILE_HEIGHT / 2);
					nodes = tilemap.findPath(startPoint, endPoint);
				}
				path.start(this, nodes);
			}
		}
		
		if (!path.finished && path.nodes != null) {
			if (path.angle == 0 || path.angle == 45 || path.angle == -45) {
				animation.play("up");
			}
			if (path.angle == 180 || path.angle == -135 || path.angle == 135) {
				animation.play("down");
			}
			if (path.angle == 90) {
				animation.play("right");
			}
			if (path.angle == -90) {
				animation.play("left");
			}
		} else {
			animation.curAnim.curFrame = 0;
			animation.curAnim.stop();
			nodes = null;
		}	
	}
	
}