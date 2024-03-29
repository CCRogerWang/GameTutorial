//
//  MyScene.m
//  GameTutorial
//
//  Created by Roger on 2013/12/15.
//  Copyright (c) 2013年 Roger. All rights reserved.
//

#import "MyScene.h"
#import "GameOverLayer.h"
static const uint32_t shipCategory = 0x1 << 0;
static const uint32_t obstacleCategory = 0x1 << 1;

static const float BG_VELOCITY = 100.0;
static const float OBJECT_VELOCITY = 160.0;
static inline CGPoint CGPointAdd(const CGPoint a,const CGPoint b){
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat b){
    return  CGPointMake(a.x * b, a.y *b);
}



@implementation MyScene{
    SKSpriteNode *ship;
    SKAction *actionMoveUp;
    SKAction *actionMoveDown;
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    NSTimeInterval _lastMissileAdded;
}

- (id)initWithSize:(CGSize)size{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor whiteColor];
        [self initalizingScrollingBackground];
        [self addShip];
        //Making self delegate of physics Wold
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
    }
    return self;
}

-(void) initalizingScrollingBackground{
    for (int i = 0; i < 3; i++) {
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
        bg.position = CGPointMake(i * bg.size.width, 0);
        bg.anchorPoint = CGPointZero;
        bg.name = @"bg";
        [self addChild:bg];
    }
}

-(void)addShip{
    //initalizing spaceship node
//    SKSpriteNode *ship = [SKSpriteNode new];
    ship = [SKSpriteNode new];
    ship = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship.png"];
    [ship setScale:0.5];
    ship.zRotation = - M_PI/2;
    
    //Adding spritekit physicsBody for collision detection
    ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ship.size];
    ship.physicsBody.categoryBitMask = shipCategory;
    ship.physicsBody.dynamic = YES;
    ship.physicsBody.contactTestBitMask = obstacleCategory;
    ship.physicsBody.collisionBitMask = 0;// set ship not bounce off
    ship.name = @"ship";
    ship.position = CGPointMake(120, 160);
    
    [self addChild:ship];
    
    actionMoveUp = [SKAction moveByX:0 y:30 duration:.2];
    actionMoveDown = [SKAction moveByX:0 y:-30 duration:.2];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    if (touchLocation.y > ship.position.y) {
        if (ship.position.y < 270) {
            [ship runAction:actionMoveUp];
        }
    }
    else{
        if (ship.position.y > 50) {
            [ship runAction:actionMoveDown];
        }
    }
}

- (void)moveBg{
    [self enumerateChildNodesWithName:@"bg" usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *bg = (SKSpriteNode*)node;
        CGPoint bgVelocity = CGPointMake(-BG_VELOCITY, 0);
        CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity, _dt);
        bg.position = CGPointAdd(bg.position, amtToMove);
        
        //checks if bg node is completely scrolled of the screen, if yes then put it at the end of the other node
        if (bg.position.x <= -bg.size.width) {
            bg.position = CGPointMake(bg.position.x + bg.size.width * 3, bg.position.y);
        }
    }];
}

-(void) addMissile{
    //initalizing  missile node
    SKSpriteNode *missile;
    missile = [SKSpriteNode spriteNodeWithImageNamed:@"red-missile.png"];
    [missile setScale:0.15];
    
    //Adding SpriteKit physicsBody for collision dectection
    missile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:missile.size];
    missile.physicsBody.categoryBitMask = obstacleCategory;
    missile.physicsBody.dynamic = YES;
    missile.physicsBody.contactTestBitMask = shipCategory;
    missile.physicsBody.collisionBitMask = 0;
    missile.physicsBody.usesPreciseCollisionDetection = YES;
    missile.name = @"missile";
    //selecting random y posistion for missile
    int r = arc4random() %300;
    missile.position = CGPointMake(self.frame.size.width + 20, r );
    [self addChild:missile];
}

- (void)moveObstacle{
    NSArray *nodes = self.children;
    for (SKNode *node in nodes) {
        if (![node.name isEqual:@"bg"] && ![node.name isEqualToString:@"ship"]) {
            SKSpriteNode *ob = (SKSpriteNode*)node;
            CGPoint obVelocity = CGPointMake(-OBJECT_VELOCITY, 0);
            CGPoint amtToMove = CGPointMultiplyScalar(obVelocity, _dt);
            
            ob.position = CGPointAdd(ob.position, amtToMove);
            if (ob.position.x < -100) {
                [ob removeFromParent];
            }
        }
    }
}

- (void)update:(NSTimeInterval)currentTime{
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    }
    else{
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    
    if (currentTime - _lastMissileAdded > 1) {
        _lastMissileAdded = currentTime + 1;
        [self addMissile];
    }
    
    [self moveBg];
    [self moveObstacle];
}

- (void) didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody, *secondBody;
    if (contact.bodyA.categoryBitMask <contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    if ((firstBody.categoryBitMask & shipCategory) != 0 && (secondBody.categoryBitMask & obstacleCategory) != 0) {
        [ship removeFromParent];
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gamOverScene = [[GameOverLayer alloc]initWithSize:self.size];
        [self.view presentScene:gamOverScene transition:reveal];
    }
}
@end
