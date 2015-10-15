//###################################################
// File: dinvaders.d
// Created: 2015-02-23 07:55:59
// Modified: 2015-02-27 08:50:16
//
// See LICENSE file for license and copyright details
//###################################################


import std.stdio;

//import Dgame.Window.all;
//import Dgame.Graphics.all;
//import Dgame.System.Clock;

import Dgame.Window;
import Dgame.Graphic;
import Dgame.System.StopWatch;
import Dgame.System.Keyboard;
//import Dgame.Math.Vector2;
import Dgame.Math.Rect;
import Dgame.Math;

// globals are cool!
immutable int windowWidth = 1024, windowHeight = 768;
immutable int FPS = 30;
immutable ubyte TICKS_PER_FRAME = 1000 / FPS; //test
immutable int testMode = 0;
StopWatch sw;//test

bool gameOn = false;
bool winOn = false;
// Manage the player
struct Player {
    static immutable int width = 77, height = 80;    
    static immutable string image = "./player.png";
    static immutable int startX =windowWidth / 2-Player.width/2, startY = 650;
    Texture img;//get it from local create context
    Sprite player;
    Shape circle;
    int moveDir = 0;
    void create()
    {
        //Image img = new Image(Player.image);//textura and surface
        
        img = Texture(Surface(Player.image));
        
        player = new Sprite(img);
        //player.setPosition(Player.startX, Player.startY); // Sprite.setPosition
        player.setPosition(Player.startX, Player.startY);

        circle = new Shape(25, Vector2f(180, 380));
        circle.setColor(Color4b.Green);    
        
    }
    // Called once per frame
    void update(ref Window wnd)
    {
        //if(player.position.x < 5 && moveDir < 0) {  //getPosition
        if(player.getPosition.x < 5 && moveDir < 0) {
            moveDir = 0;
        } else if(player.getPosition.x > windowWidth-Player.width-5 && moveDir > 0) {
            moveDir = 0;
        }
        
        //player.move(moveDir, 0);
        
        //some fansy movements, and seems it does not affect anything
        if (moveDir > 0) {
            player.move(1, 0);
            moveDir -= 1;
        } else if (moveDir < 0) {
            player.move(-1,0);
            moveDir += 1;
        }
        wnd.draw(player);    
        wnd.draw(circle);
    }
    void fireBullet(ref Bullet bullet)
    {
        //bullet.sprite.position.x = player.position.x + Player.width / 2;
        //bullet.sprite.position.y = player.position.y;

        bullet.sprite.setPosition(player.getPosition.x + Player.width / 2, player.getPosition.y);
        
        bullet.moveDir = -10;
        bullet.active = true;
    }
}
// Manage the state of the alien pack
// and shuffle on update.
struct Aliens {
    static immutable int width = 76, height = 80;
    static immutable string image = "./alien.png";
    static immutable int numRows = 4;
    static immutable int numCols = 7;
    static immutable int offsetX = Aliens.width + 5; // Some spacing for the pack
    static immutable int offsetY = Aliens.height + 5;
    static immutable int moveX = 10;


    Spritesheet[numRows*numCols] aliens;
    bool[numRows*numCols] alienOn;
    int alienCount = numRows*numCols;
    StopWatch timeout;
    int packX = 50, packY = 50; // The top-left of the alien pack
    int packDir = 1;
    // When frameCount reaches 0 we update. The update latch specified
    // the number of frames before an update and changes to increase
    // the speed.
    int updateLatch = 250;
    Texture img;//same
    /// Create the aliens.
    void create()
    {
        timeout = StopWatch.init;
        //Image img = new Image(Aliens.image);
        img =  Texture(Surface(Aliens.image));
        int idx = 0;
        foreach(ii; 0..numRows) {
            foreach(jj; 0..numCols) {
                //aliens[idx]= new Spritesheet(img, ShortRect(0, 0, Aliens.width, Aliens.height));  // Rect
                aliens[idx]= new Spritesheet(img, Rect(0, 0, Aliens.width, Aliens.height));
                int x = jj * Aliens.offsetX + 50;
                int y = ii * Aliens.offsetY + 50;
                aliens[idx].setPosition(x, y);
                alienOn[idx] = true;
                ++idx;
            }
        }
    }
    // Called every frame
    void update(ref Window wnd)
    {
        bool slide = false;
        if(gameOn && timeout.getElapsedTicks() > updateLatch) {
            // Shuffle along...
            packX += moveX*packDir;

            // Reached the end of the scan, start a new row and
            // increase the speed of these puppies.
            if(packX > 450 || packX < 50) {
                packDir *= -1;
                packY += (Aliens.height + 5);
                if(packY > 400) { // well, game over           
                }
                updateLatch /= 2;
            }
            slide =true;
            timeout.reset();
        }
        int idx = 0;
        foreach(y; 0..Aliens.numRows) {
            foreach(x; 0..Aliens.numCols) {
                if(alienOn[idx]) {
                    if(slide) {
                        aliens[idx].slideTextureRect();
                        aliens[idx].setPosition( x*Aliens.offsetX + packX, y*Aliens.offsetY + packY);
                    }
                    wnd.draw(aliens[idx]);
                }
                ++idx;
            }
        }
    }
    // Called when an alien is destroyed. Turns off the alien sprite and
    // turns on the corresponding explosion (have none).
    void destroy(int idx)
    {
        alienOn[idx] = false;
        writeln("Aliens left:", --alienCount);
    }
    // Check for collisions between aliens-player and aliens-bullet
    void checkCollisions(ref Bullet[2] bullets, ref Player player)
    {
        foreach(int idx, alien; aliens) {
            if(alienOn[idx]) {

                //if(bullets[0].active && alien.collideWith(bullets[0].sprite)) {
                if(bullets[0].active && alien.getClipRect.intersects(bullets[0].sprite.getClipRect, null)) {
                    destroy(idx);
                    bullets[0].active = false;
                    //writeln("hit 0 ", "alien ", idx);
                }
                //if(bullets[1].active && alien.collideWith(bullets[1].sprite)) {
                if(bullets[1].active && alien.getClipRect.intersects(bullets[1].sprite.getClipRect, null)) {
                    destroy(idx);
                    bullets[1].active = false;
                    //writeln("hit 0 ", "alien ", idx);
                }
                //if(alien.collideWith(player.player)) {// Oops, game over!
                if(alien.getClipRect.intersects(player.player.getClipRect, null)) {// Oops, game over!
                    gameOn = false;
                }
            }
        }
    }

}
// Manage bullets
struct Bullet {
    static immutable int width = 17, height = 40;
    static immutable string image = "./player_bullet.png";
    Texture img;//same
    Sprite sprite;
    int moveDir = 0;
    bool active = false;
    void create()
    {
        //Image img = new Image(Bullet.image);
        img =  Texture(Surface(Bullet.image));
        sprite = new Sprite(img);
        //writeln(sprite.getPosition());//marks
    }
    void update(ref Window wnd)
    {
        if(active) {
            sprite.move(0, moveDir);
            wnd.draw(sprite);
            //if(sprite.position.y < 5) {
            if(sprite.getPosition.y < 5) {
                active = false;
            }
        }
    }
}
// Kickstart
void main0()
{
    //Window wnd = new Window(VideoMode(windowWidth, windowHeight), "D-Invaders");
    Window wnd =  Window(windowWidth, windowHeight, "D-Invaders");
    //wnd.setVerticalSync(Window.Sync.Disable);
    wnd.setVerticalSync(Window.VerticalSync.Disable);
    //wnd.setFramerateLimit(FPS);
//    wnd.setClearColor(Color.Black); /// Default would be Color.White
    wnd.setClearColor(Color4b.Black); /// Default would be Color.White
    wnd.clear(); /// Clear the buffer and fill it with the clear Color
    wnd.display();

    auto aliens = Aliens();
    auto player = Player();
    // Setup our aliens.
    aliens.create();
    player.create();
    Bullet[2] bullets;
    bullets[0].create();
    bullets[1].create();

    gameOn = true;
    winOn = true;// test
    // Start the event loop
    Event event;
//    while(wnd.isOpen()) {
    while(winOn) { // test
        if(gameOn) {
            wnd.clear();
            //while(EventHandler.poll(&event)) {
            while(wnd.poll(&event)) {
                switch(event.type) {
                    case Event.Type.Quit : {
                        //wnd.close();
                        winOn = false;//test
                        break;
                    }
                    case Event.Type.KeyDown : {  
                        switch(event.keyboard.key) {
                            //case Keyboard.Code.Esc: {
                            case Keyboard.Key.Esc: {
                                //EventHandler.push(Event.Type.Quit);
                                wnd.push(Event.Type.Quit);
                                break;
                            }
                            //case Keyboard.Code.Left: {
                            case Keyboard.Key.Left: {
                                player.moveDir = -25;
                                break;
                            }
                            //case Keyboard.Code.Right: {
                            case Keyboard.Key.Right: {
                                player.moveDir = 25;
                                break;
                            }
                            //case Keyboard.Code.Space: {
                            case Keyboard.Key.Space: {
                                // Do we have a bullet to fire?
                                //writefln(" do we have a bullet to fire? bullet0:%s, bullet1:%s ",!bullets[0].active,!bullets[1].active);
                                if(!bullets[0].active) {
                                    //writeln("fire bullet 0");
                                    player.fireBullet(bullets[0]);                                    
                                } else if(!bullets[1].active) {
                                    //writeln("fire bullet 1");
                                    player.fireBullet(bullets[1]);                                    
                                }
                                break;
                            }
                            default :
                                break;
                        }
                        default :
                            break;
                    }
                }
            //sw.reset();
            }
        

            // Update the aliens
            aliens.update(wnd);
            player.update( wnd);
            if(bullets[0].active) {
                bullets[0].update(wnd); // these only draw if active
                //writeln("bullet0 position! ", bullets[0].sprite.getPosition());
            }
            if(bullets[1].active) {
                bullets[1].update(wnd);
                //writeln("bullet1 position! ", bullets[0].sprite.getPosition());
            }
            aliens.checkCollisions(bullets, player);

            wnd.display();
        } else { // Too bad, game over
            //wnd.setClearColor(Color.Red);
            wnd.setClearColor(Color4b.Red);
            wnd.clear();
            wnd.display();
            StopWatch.wait(1000);
            //wnd.close();
            winOn = false;//test
        }
        
        
    }
}




// Tests
void main1() {
    writeln("testing");
    
    
    //Window wnd = new Window(VideoMode(windowWidth, windowHeight), "D-Invaders");
    Window wnd =  Window(windowWidth, windowHeight, "D-Invaders");
    //wnd.setVerticalSync(Window.Sync.Disable);
    wnd.setVerticalSync(Window.VerticalSync.Disable);
    //wnd.setFramerateLimit(FPS);
//    wnd.setClearColor(Color.Black); /// Default would be Color.White
    wnd.setClearColor(Color4b.Black); /// Default would be Color.White
    wnd.clear(); /// Clear the buffer and fill it with the clear Color
    wnd.display();

    //auto aliens = Aliens();
    Player playerP;
    // Setup our aliens.
    //aliens.create();
    playerP.create();
    //Bullet[2] bullets;
    //bullets[0].create();
    //bullets[1].create();

    int width = 77, height = 80;
    string image = "./player.png";
    int startX =windowWidth / 2-Player.width/2, startY = 650;
    Sprite player;    
    Texture img =  Texture(Surface(image));        
    player = new Sprite(img);
    player.setPosition(Player.startX, Player.startY);    
    
   
    gameOn = false;
    winOn = false;// test
    // Start the event loop
    Event event;
//    while(wnd.isOpen()) {
    while(winOn) { // test
        if(gameOn) {
            wnd.clear();
            /*
            while(wnd.poll(&event)) {
                switch(event.type) {
                    case Event.Type.Quit : {
                        //wnd.close();
                        winOn = false;//test
                        break;
                    }
                    case Event.Type.KeyDown : {
                        
                        switch(event.keyboard.key) {
                            //case Keyboard.Code.Esc: {
                            case Keyboard.Key.Esc: {
                                //EventHandler.push(Event.Type.Quit);
                                wnd.push(Event.Type.Quit);
                                break;
                            }
                            //case Keyboard.Code.Left: {
                            case Keyboard.Key.Left: {
                                player.moveDir = -5;
                                break;
                            }
                            //case Keyboard.Code.Right: {
                            case Keyboard.Key.Right: {
                                player.moveDir = 5;
                                break;
                            }
                            //case Keyboard.Code.Space: {
                            case Keyboard.Key.Space: {
                                writeln("[0] ",bullets[0].active);
                                // Do we have a bullet to fire?
                                writefln(" do we have a bullet to fire? bullet0:%s, bullet1:%s ",
                                                    !bullets[0].active,!bullets[1].active);
                                if(!bullets[0].active) {
                                    writeln("fire bullet 0");
                                    player.fireBullet(bullets[0]);                                    
                                } else if(!bullets[1].active) {
                                    writeln("fire bullet 1");
                                    player.fireBullet(bullets[1]);                                    
                                }
                                break;
                            }
                            default :
                                break;
                        }
                        default :
                            break;
                    }
                }
            }
            
//            player.update( wnd);
            
            if(bullets[0].active) {
                bullets[0].update(wnd); // these only draw if active
                //writeln("bullet0 position! ", bullets[0].sprite.getPosition());
            }
            if(bullets[1].active) {
                bullets[1].update(wnd);
                //writeln("bullet1 position! ", bullets[0].sprite.getPosition());
            }
            aliens.checkCollisions(bullets, player);
            */    
            
            wnd.draw(player);
            wnd.display();
        } else { // Too bad, game over
            //wnd.setClearColor(Color.Red);
            wnd.setClearColor(Color4b.Red);
            wnd.clear();
            wnd.display();
            StopWatch.wait(1000);
            //wnd.close();
            winOn = false;//test
        }
        
        
    }
    

    

/*
    for(int i; i<30_000; ++i){
        wnd.clear();      
        if (i%10_000==0) {writeln(i);}
        player.move((i%41-20), 0);  
        wnd.draw(player);
        wnd.display();
    }
    
    for(int i; i<30_000; ++i){   
        wnd.clear();    
        if (i%10_000==0) {writeln(i);}
        player.move(0, 0);
        wnd.draw(player);
        wnd.display();
    }
*/   
      for(int i; i<30_001; ++i){   
        wnd.clear();    
        if (i%10_000==0) {writeln(i);}
        playerP.moveDir = i % 41 - 20;
        playerP.update( wnd);
        
        wnd.display();
    }
   
      
    
    wnd.display();
    
    StopWatch.wait(1000);
    
    }
    







void main()
{

    switch (testMode){
        case 0 : {    
            main0();
            break;
        }
        case 1 : {
            main1();
            break;
            }
        default : break;
    }

}