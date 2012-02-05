//
//  AIDirector.m
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-10-01.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIDirector.h"

@implementation AIDirector

@synthesize elapsedTime, timeUntilSpawn, gameplayLayerDelegate;

- (id)init
{
    self = [super init];
    if (self) {
        elapsedTime = 0.0;
        timeUntilSpawn = arc4random() % 15;
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
    gameplayLayerDelegate = nil;
}

-(void)updateWithDeltaTime:(ccTime)deltaTime andArrayOfGameObjects:(CCArray*)arrayOfGameObjects 
{
    elapsedTime += deltaTime;
    timeUntilSpawn -= deltaTime;
    
    if (timeUntilSpawn <= 0) {
#if GRID_CHASER_DEBUG_MODE
        CCLOG(@"Spawn a new car at: %f",elapsedTime);
#endif
        [gameplayLayerDelegate addGameObjectWithType:kGameObjectEnemyCar withTileCoord:ccp(-1, -1)];
        timeUntilSpawn = arc4random() % 15;
    }
}

@end
