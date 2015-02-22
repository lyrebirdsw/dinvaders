//###################################################
// File: dinvaders.d
// Created: 2015-02-23 07:55:59
// Modified: 2015-02-23 07:55:59
//
// See LICENSE file for license and copyright details
//###################################################

//############################################
// DInvaders. A short script to test Dgame
// author: Stewart Hore
// File: dinvaders.d
// Created: 2014-02-20 18:34:32
// Modified: 2014-02-20 21:45:23
//############################################

import std.stdio;

import Dgame.Window.all;
import Dgame.Graphics.all;
import Dgame.System.Clock;

// globals are cool!
immutable int windowWidth = 1024, windowHeight = 768;
immutable int FPS = 30;
bool gameOn = false;
// Manage the player
struct Player {
    static immutable int width = 77, height = 80;
    static immutable string image = "./player.png";
    static immutable int startX =windowWidth / 2-Player.width/2, startY = 650;
    Sprite player;
    int moveDir = 0;
    void create()
    {
        Image img = new Image(Player.image);
        player = new Sprite(img);
        player.setPosition(Player.startX, Player.startY);
    }
    // Called once per frame
    void update(Window wnd)
    {
        if(player.position.x < 5 && moveDir < 0) {
            moveDir = 0;
        } else if(player.position.x > windowWidth-Player.width-5 && moveDir > 0) {
            moveDir = 0;
        }
        player.move(moveDir, 0);
        wnd.draw(player);
    }
    void fireBullet(ref Bullet bullet)
    {
        bullet.sprite.position.x = player.position.x + Player.width / 2;
        bullet.sprite.position.y = player.position.y;

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
    bool alienOn[numRows*numCols];
    Clock timeout;
    int packX = 50, packY = 50; // The top-left of the alien pack
    int packDir = 1;
    // When frameCount reaches 0 we update. The update latch specified
    // the number of frames before an update and changes to increase
    // the speed.
    int updateLatch = 250;

    /// Create the aliens.
    void create()
    {
        timeout = Clock.init;
        Image img = new Image(Aliens.image);
        ulong idx = 0;
        foreach(ii; 0..numRows) {
            foreach(jj; 0..numCols) {
                aliens[idx]= new Spritesheet(img, ShortRect(0, 0, Aliens.width, Aliens.height));
                int x = jj * Aliens.offsetX + 50;
                int y = ii * Aliens.offsetY + 50;
                aliens[idx].setPosition(x, y);
                alienOn[idx] = true;
                ++idx;
            }
        }
    }
    // Called every frame
    void update(Window wnd)
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
        ulong idx = 0;
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
    void destroy(ulong idx)
    {
        alienOn[idx] = false;
    }
    // Check for collisions between aliens-player and aliens-bullet
    void checkCollisions(ref Bullet[2] bullets, ref Player player)
    {
        foreach(idx, alien; aliens) {
            if(bullets[0].active && alien.collideWith(bullets[0].sprite)) {
                destroy(idx);
                bullets[0].active = false;
                continue;
            }
            if(bullets[1].active && alien.collideWith(bullets[0].sprite)) { 
                destroy(idx);
                bullets[1].active = false;
                continue;
            }
            if(alien.collideWith(player.player)) {// Oops, game over!
                destroy(idx);
                gameOn = false;
            }
        }
    }

}
// Manage bullets 
struct Bullet {
    static immutable int width = 17, height = 40;
    static immutable string image = "./player_bullet.png";
    Sprite sprite;
    int moveDir = 0;
    bool active = false;
    void create()
    {
        Image img = new Image(Bullet.image);
        sprite = new Sprite(img);
    }
    void update(Window wnd)
    {
        if(active) {
            sprite.move(0, moveDir);
            wnd.draw(sprite);
            if(sprite.position.y < 5) {
                active = false;
            }
        }
    }
}
// Kickstart
void main()
{
    Window wnd = new Window(VideoMode(windowWidth, windowHeight), "D-Invaders");
    wnd.setVerticalSync(Window.Sync.Disable);
    wnd.setFramerateLimit(FPS);
    wnd.setClearColor(Color.Black); /// Default would be Color.White
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
    // Start the event loop
    Event event;
    while(wnd.isOpen()) {
        if(gameOn) {
            wnd.clear();
            while(EventHandler.poll(&event)) {
                switch(event.type) {
                    case Event.Type.Quit : {
                        wnd.close();
                        break;
                    }
                    case Event.Type.KeyDown : {
                        switch(event.keyboard.key) {
                            case Keyboard.Code.Esc: {
                                EventHandler.push(Event.Type.Quit);
                                break;
                            }
                            case Keyboard.Code.Left: {
                                player.moveDir = -5;
                                break;
                            }
                            case Keyboard.Code.Right: {
                                player.moveDir = 5;
                                break;
                            }
                            case Keyboard.Code.Space: {
                                // Do we have a bullet to fire?
                                if(!bullets[0].active) {
                                    player.fireBullet(bullets[0]);
                                } else if(!bullets[1].active) {
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
            // Update the aliens
            aliens.update(wnd);
            player.update(wnd);
            if(bullets[0].active) {
                bullets[0].update(wnd); // these only draw if active
            }
            if(bullets[1].active) {
                bullets[1].update(wnd);
            }
            aliens.checkCollisions(bullets, player);
            wnd.display();
        } else { // Too bad, game over
            wnd.setClearColor(Color.Red);
            wnd.clear();
            wnd.display();
            Clock.wait(1000);
            wnd.close();
        }
    }
}
