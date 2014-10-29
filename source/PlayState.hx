package ;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxTypedGroup;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;
import flixel.util.FlxSave;
import openfl.Assets;

enum PlayerAction {
	Walking;
	Combat;
}

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var camera:FlxCamera;
	private var cameraFocus:FlxSprite;
	private var combatHide:FlxTween;
	private var combatWindow:CombatWindow;
	private var currentAction:PlayerAction;
	private var enemies:Array<Enemy>;
	private var movementMarker:FlxSprite;
	private var path:FlxPath;
	private var potions:FlxTypedGroup<Potion>;
	private var saveButton:FlxButton;
	private var tileMap:FlxTilemap;
	private var particleEmitter:FlxEmitter;
	public static var CAMERA_SPEED:Int = 8;
	public static var LEVEL_HEIGHT:Int = 50;
	public static var LEVEL_WIDTH:Int = 50;
	public static var SAVE_NAME:String = "RPG_Save";
	public static var TILE_HEIGHT:Int = 16;
	public static var TILE_WIDTH:Int = 16;
	public var hero:FlxSprite;
	public var hud:HUD;
	public var loadedGame:Bool;
	
	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
		super.create();
		
		FlxG.worldBounds.width = TILE_WIDTH * LEVEL_WIDTH;
		FlxG.worldBounds.height = TILE_HEIGHT * LEVEL_HEIGHT;
		
		tileMap = new FlxTilemap();
		tileMap.loadMap(Assets.getText("assets/data/map.csv"), "assets/images/tileset.png", TILE_WIDTH, TILE_HEIGHT, 0, 1);
		tileMap.setTileProperties(0, FlxObject.ANY);
		tileMap.setTileProperties(1, FlxObject.ANY);
		tileMap.setTileProperties(2, FlxObject.NONE);
		add(tileMap);
		
		cameraFocus = new FlxSprite();
		cameraFocus.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		add(cameraFocus);
		
		camera = FlxG.camera;
		camera.follow(cameraFocus, FlxCamera.STYLE_LOCKON);
		
		movementMarker = new FlxSprite();
		movementMarker.visible = false;
		add(movementMarker);
		
		hero = new FlxSprite(TILE_WIDTH * 7, TILE_HEIGHT * 3);
		hero.loadGraphic("assets/images/hero.png", true, TILE_WIDTH, TILE_HEIGHT);
		hero.animation.add("down", [0, 1, 0, 2]);
		hero.animation.add("up", [3, 4, 3, 5]);
		hero.animation.add("right", [6, 7, 6, 8]);
		hero.animation.add("left", [9, 10, 9, 11]);
		add(hero);
		
		potions = new FlxTypedGroup<Potion>();
		add(potions);
		
		hero.animation.play("down");
		path = new FlxPath();
		
		enemies = new Array<Enemy>();
		
		hud = new HUD();
		
		if (loadedGame) {
			loadGame();
		}else {
			newGame();
		}
		
		particleEmitter = new FlxEmitter(0, 0);
		particleEmitter.setXSpeed( -8, 8);
		particleEmitter.setYSpeed( -8, 8);
		add(particleEmitter);
		
		add(hud);
		
		currentAction = Walking;
		hero.active = true;
		
		combatWindow = new CombatWindow(this);
		combatWindow.active = false;
		combatWindow.visible = false;
		add(combatWindow);
		
		saveButton = new FlxButton(FlxG.width - 80, 0, "Save", doSave);
		add(saveButton);
	}
	
	public function newGame():Void {
		spawnPotion(5, 5);
		spawnPotion(6, 5);
		spawnPotion(3, 10);
		spawnPotion(4, 10);
		spawnPotion(1, 10);
		addEnemy(10, 15);
		addEnemy(12, 10);
		addEnemy(15, 6);
		addEnemy(20, 6);
		addEnemy(12, 20);	
	}
	
	public function loadGame():Void {
		var save:FlxSave = new FlxSave();
		save.bind(SAVE_NAME);
		hud.hp = save.data.hp;
		hud.maxHp = save.data.maxHp;
		hud.exp = save.data.exp;
		hud.maxExp = save.data.maxExp;
		hud.level = save.data.level;
		var i:Int;
		if(save.data.enemies != null){
			for (i in 0...save.data.enemies.length) {
				addEnemy(Math.floor(save.data.enemies[i].x / TILE_WIDTH), Math.floor(save.data.enemies[i].y / TILE_HEIGHT));
			}
		}
		if(save.data.potions != null){
			for (i in 0...save.data.potions.length) {
				spawnPotion(Math.floor(save.data.potions[i].x / TILE_WIDTH), Math.floor(save.data.potions[i].y / TILE_HEIGHT));
			}
		}
		hero.x = save.data.heroX;
		hero.y = save.data.heroY;
		cameraFocus.x = save.data.cameraX;
		cameraFocus.y = save.data.cameraY;
	}
	
	private function doSave():Void {
		var save:FlxSave = new FlxSave();
		
		// Delete all existing data
		save.bind(SAVE_NAME);
		save.erase();
		
		// Write new data
		save.bind(SAVE_NAME);
		save.data.hp = hud.hp;
		save.data.maxHp = hud.maxHp;
		save.data.exp = hud.exp;
		save.data.maxExp = hud.maxExp;
		save.data.level = hud.level;
		var i:Int;
		save.data.enemies = new Array<Dynamic>();
		for (i in 0...enemies.length) {
			if(enemies[i].exists && enemies[i].active){
				save.data.enemies.push({ x: enemies[i].x, y: enemies[i].y });
			}
		}
		save.data.potions = new Array<Dynamic>();
		for (i in 0...potions.members.length) {
			if(potions.members[i].exists && potions.members[i].active){
				save.data.potions.push({ x: potions.members[i].x, y: potions.members[i].y });
			}
		}
		save.data.heroX = hero.x;
		save.data.heroY = hero.y;
		save.data.cameraX = cameraFocus.x;
		save.data.cameraY = cameraFocus.y;
		
		save.flush();
		FlxG.switchState(new MenuState());
	}
	
	private function spawnPotion(x:Int, y:Int):Void{
		var potion:Potion = new Potion();
		potion.x = x * TILE_WIDTH;
		potion.y = y * TILE_HEIGHT;
		potions.add(potion);
	}
	
	private function addEnemy(x:Int, y:Int):Void {
		var enemy:Enemy = new Enemy(tileMap, hero);
		enemy.x = x * TILE_WIDTH;
		enemy.y = y * TILE_HEIGHT;
		enemy.health = 5;
		enemies.push(enemy);
		add(enemy);
	}
	
	private function onPotionCollision(hero:FlxSprite, potion:Potion):Void {
		if (potion.exists && hero.exists) {
			potion.kill();
			hud.addHealth(1);
			
			particleEmitter.x = potion.x + TILE_WIDTH / 2;
			particleEmitter.y = potion.y + TILE_HEIGHT / 2;
			var i:Int;
			for (i in 0...10) {
				var particle:FlxParticle = new FlxParticle();
				particle.makeGraphic(2, 2, FlxColor.CYAN);
				particle.visible = false;
				particleEmitter.add(particle);
			}
			particleEmitter.start(true, 2, 0, 10, 1);
		}
	}
	
	private function onEnemyCollision(hero:FlxSprite, enemy:Enemy):Void {
		if (enemy.exists && hero.exists && hero.active && enemy.active) {
			hero.active = false;
			enemy.active = false;
			currentAction = Combat;
			startCombat(enemy);
		}
	}
	
	private function startCombat(enemy:Enemy):Void {
		combatWindow.active = true;
		combatWindow.visible = true;
		if (combatHide!=null && combatHide.active) {
			combatHide.cancel();
		}
		FlxTween.tween(combatWindow, { y: FlxG.height / 2 - 40 }, 1, { type: FlxTween.ONESHOT, ease: FlxEase.quadOut } );
		combatWindow.y = -200;
		combatWindow.fight(enemy);
	}
	
	public function winCombat(enemy:Enemy):Void {
		endCombat(enemy);
	}
	
	public function endCombat(enemy:Enemy):Void {
		enemy.kill();
		combatHide = FlxTween.tween(combatWindow, {y: -200 }, 1, { type: FlxTween.ONESHOT, ease: FlxEase.quadIn, complete: hideCombat} );
		hero.active = true;
		currentAction = Walking;
	}
	
	private function hideCombat(tween:FlxTween):Void {
		combatWindow.active = false;
		combatWindow.visible = false;	
	}

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		super.update();
		
		// Save visibility
		saveButton.visible = currentAction == Walking;
		
		// Collisions
		FlxG.overlap(hero, potions, onPotionCollision);
		var i:Int;
		for (i in 0...enemies.length) {
			FlxG.overlap(hero, enemies[i], onEnemyCollision);
		}
		
		// Animation
		if (!path.finished && path.nodes!=null) {
			if (path.angle == 0 || path.angle == 45 || path.angle == -45) {
				hero.animation.play("up");
			}
			if (path.angle == 180 || path.angle == -135 || path.angle == 135) {
				hero.animation.play("down");
			}
			if (path.angle == 90) {
				hero.animation.play("right");
			}
			if (path.angle == -90) {
				hero.animation.play("left");
			}
		} else {
			hero.animation.curAnim.curFrame = 0;
			hero.animation.curAnim.stop();
		}
		
		// Camera movement
		if (FlxG.keys.anyPressed(["DOWN", "S"])) {
			cameraFocus.y += CAMERA_SPEED;
		}
		if (FlxG.keys.anyPressed(["UP", "W"])) {
			cameraFocus.y -= CAMERA_SPEED;
		}
		if (FlxG.keys.anyPressed(["RIGHT", "D"])) {
			cameraFocus.x += CAMERA_SPEED;
		}
		if (FlxG.keys.anyPressed(["LEFT", "A"])) {
			cameraFocus.x -= CAMERA_SPEED;
		}
		
		// Camera bounds
		if (cameraFocus.x < FlxG.width / 2) {
			cameraFocus.x = FlxG.width / 2;
		}
		if (cameraFocus.x > LEVEL_WIDTH * TILE_WIDTH - FlxG.width / 2) {
			cameraFocus.x = LEVEL_WIDTH * TILE_WIDTH - FlxG.width / 2;
		}
		if (cameraFocus.y < FlxG.height / 2) {
			cameraFocus.y = FlxG.height / 2;
		}
		if (cameraFocus.y > LEVEL_HEIGHT * TILE_HEIGHT - FlxG.height / 2) {
			cameraFocus.y = LEVEL_HEIGHT * TILE_HEIGHT - FlxG.height / 2;
		}
		
		// Mouse clicks
		if (currentAction == Walking && FlxG.mouse.justReleased){
			var tileCoordX:Int = Math.floor(FlxG.mouse.x / TILE_WIDTH);
			var tileCoordY:Int = Math.floor(FlxG.mouse.y / TILE_HEIGHT);
			
			movementMarker.visible = true;
			if (tileMap.getTile(tileCoordX, tileCoordY) == 2) {
				var nodes:Array<FlxPoint> = tileMap.findPath(FlxPoint.get(hero.x + TILE_WIDTH/2, hero.y + TILE_HEIGHT/2), FlxPoint.get(tileCoordX * TILE_WIDTH + TILE_WIDTH/2, tileCoordY * TILE_HEIGHT + TILE_HEIGHT/2));
				if (nodes != null) {
					path.start(hero, nodes);
					movementMarker.loadGraphic(AssetPaths.marker_move__png, false, TILE_WIDTH, TILE_HEIGHT);
				}else {
					movementMarker.loadGraphic(AssetPaths.marker_stop__png, false, TILE_WIDTH, TILE_HEIGHT);
				}
			}else {
				movementMarker.loadGraphic(AssetPaths.marker_stop__png, false, TILE_WIDTH, TILE_HEIGHT);
			}
			movementMarker.setPosition(tileCoordX * TILE_WIDTH, tileCoordY * TILE_HEIGHT);
		}
	}
}