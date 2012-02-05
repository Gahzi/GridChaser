//
//  EnemyCar.m
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-08-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EnemyCar.h"

@implementation EnemyCar

@synthesize lastPlayerCoord,lastPlayerDirection,vision,state,turnSuccessRate;

#define kBaseVelocity 40

-(id)init
{
    if(self = [super init]) {
        velocity = kBaseVelocity;
        acceleration = 10;
        topSpeed = 50;
        vision = 10;
        lastPlayerCoord = ccp(-1, -1);
        lastPlayerDirection = -1;
        state = kStatePatrolling;
        turnSuccessRate = kSuccessRatePerfect;
    }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

-(void) setState:(EnemyState)newState
{
    [targetPath removeAllObjects];
    
    switch (newState) {
        case kStatePatrolling: {
            acceleration = 10;
            topSpeed = 50;
            turnSuccessRate = kSuccessRatePerfect;
            break;
        }
        case kStateCautiousPatrolling: {
            turnSuccessRate = 100.0;
            break;
        }
        case kStateCreeping: {
            turnSuccessRate = 100.0;
            break;
        }
        case kStateChasing: {
            acceleration = 40;
            topSpeed = 100;
        }
        case kStateAlarmed: {
            break;
        }
        default:
            break;
    }
    state = newState;
}

-(CharacterTurnAttempt) attemptTurnWithDeltaTime:(ccTime)deltaTime
{
    int minValue = MIN(kSuccessRatePerfect,turnSuccessRate);
    int maxValue = MAX(kSuccessRatePerfect,turnSuccessRate);
    
    int x = (arc4random() % (maxValue - minValue+1));
    x = x + minValue;
    
    if( x > (kSuccessRatePerfect - kTurnAttemptPerfect)) {
        velocity = velocity + 100 * deltaTime;
        return kTurnAttemptPerfect;
    }
    else if(x > (kSuccessRatePerfect - kTurnAttemptGood)) {
        velocity = velocity + 50 * deltaTime;
        return kTurnAttemptGood;
    }
    else if(x > (kSuccessRatePerfect - kTurnAttemptOkay)) {
        velocity = velocity + 0 * deltaTime;
        return kTurnAttemptOkay;
    }
    else if(x > (kSuccessRatePerfect - kTurnAttemptPoor)) {
        velocity = velocity - 50 * deltaTime;
        return kTurnAttemptPoor;
    }
    else if(x > (kSuccessRatePerfect - kTurnAttemptTerrible)) {
        velocity = velocity - 75 * deltaTime;
        return kTurnAttemptTerrible;
    }
    else {
        velocity = velocity - 100 * deltaTime;
        return kTurnAttemptFailed;
    }
}

-(BOOL) isGameObjectVisible:(GameObject *) gameObject 
{
    CGPoint adjacentTile = self.tileCoordinate;
    for (int i = 0; i < vision; i++) {

        if ([self.mapDelegate isCollidableWithTileCoord:adjacentTile]) {
            break;
        }
        else if (CGPointEqualToPoint(gameObject.tileCoordinate, adjacentTile)) {
            return YES;
        }
        
        adjacentTile = [self getAdjacentTileCoordFromTileCoord:adjacentTile WithDirection:direction];
    }
    return NO;
}

-(void)updateWithDeltaTime:(ccTime)deltaTime andArrayOfGameObjects:(CCArray *)arrayOfGameObjects
{
    float newVelocity = velocity + acceleration * deltaTime;
    
    if (newVelocity > topSpeed) {
        velocity = topSpeed;
    }
    else {
        velocity = newVelocity;
    }
    
    
    PlayerCar *player = nil;
    CharacterDirection nextDirection = kDirectionNull;
    CGPoint nextTileCoord = ccp(-1, -1);
    
    GameCharacter *tempChar;
    
    CCARRAY_FOREACH(arrayOfGameObjects, tempChar) {
        if(tempChar.tag == kPlayerCarTag) {
            player = (PlayerCar*)tempChar;
            break;
        }
    }
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGFloat distanceFromPlayer = ccpDistance(self.tileCoordinate, player.tileCoordinate);
    CGFloat characterLimit = (winSize.width / [mapDelegate getTileSize].width);
    
    if (distanceFromPlayer > characterLimit) {
        [self removeFromParentAndCleanup:YES];
        return;
    }
    
    /*
     *If we have a success rate that isn't 100% then we must be 
     *in a chasing the player and we should increment the successRate.
     */
    
    
    switch (state) {
        //if noteriety is above a certain level, then chase
        //otherwise we might follow/creep toward the player
        //or do nothing
        case kStatePatrolling:
        {
            if ([self isGameObjectVisible:player]) {
                self.state = kStateCreeping;
                targetTile = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:self.direction];
                break;
            }
            else {            
                if(targetPath.count == 0) {
                    //set a new position
                    CGPoint nextTargetTile = ccp(-1, -1);
                    CGSize mapSize = [mapDelegate getMapSize];
                    
                    while ([mapDelegate isCollidableWithTileCoord:nextTargetTile]) {
                        int x = arc4random() % (int)mapSize.width;
                        int y = arc4random() % (int)mapSize.height;
                        nextTargetTile = ccp(x, y);
                    }
                    
                    self.targetPath = [mapDelegate getPathPointsFrom:self.tileCoordinate to:nextTargetTile withDirection:direction];
                    targetTile = [self getNextTileCoordWithPath:targetPath];
                }
                else if(targetPath.count > 0) {
                    targetTile = [self getNextTileCoordWithPath:targetPath];
                }
            }
            break;
        }
            
        case kStateCreeping:
        {
            self.state = kStateChasing;
            targetTile = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:self.direction];
            break;
        }
            
        case kStateCautiousPatrolling:
        {
            break;
        }
            
        case kStateChasing:
        {
            if (turnSuccessRate != kSuccessRatePerfect) {
                if(turnSuccessRate + 2.0 > 100) {
                    turnSuccessRate = 100;
                }
                turnSuccessRate += 2.0;
            }
            
            if(player) {
                CGRect playerBoundingBox = [player boundingBox];
                CGRect boundingBox = [self boundingBox];
                
                if(CGRectIntersectsRect(boundingBox, playerBoundingBox)) {
                    velocity = kBaseVelocity;
                    //Player shall die.
                    //[player removeFromParentAndCleanup:YES];
                }
                
                //if we see the player, then continue chasing
                //if the player is no longer visible, then we should guess where they are.
                //potential reasons for loss of visibility, turning, getting out of vision range.
                
                if ([self isGameObjectVisible:player]) {
                    
                    lastPlayerCoord = player.tileCoordinate;
                    
                    
                    if (lastPlayerDirection != player.direction) {
                        lastPlayerDirection = player.direction;
                        turnSuccessRate = 0.0;
                    }
                    targetTile = player.tileCoordinate;
                    //If we were on an existing path, we shouldn't be going back to it anymore.
                    [targetPath removeAllObjects];
                    break;
                }
                else {
                    if(targetPath.count == 0) {
                        nextTileCoord = [self getNextTileCoordWithTileCoord:lastPlayerCoord andDirection:lastPlayerDirection];

                        if(CGPointEqualToPoint(self.tileCoordinate, nextTileCoord)) {
                            self.state = kStateAlarmed;
                            break;
                        }
                        
                        self.targetPath = [mapDelegate getPathPointsFrom:self.tileCoordinate to:nextTileCoord withDirection:direction];
                        targetTile = [self getNextTileCoordWithPath:targetPath];
                    }
                    else if(targetPath.count > 0) {
                        targetTile = [self getNextTileCoordWithPath:targetPath];
                    }
                }
                
                nextDirection = [self getDirectionWithTileCoord:targetTile];
                
                if (nextDirection != self.direction && nextDirection != kDirectionNull) {
                    CharacterTurnAttempt turnAttempt = [self attemptTurnWithDeltaTime:deltaTime];
                    
                    if (turnAttempt != kTurnAttemptFailed) {
                        self.direction = nextDirection;
                    }
                    else {
                        //We have failed our turn.
                        //If possible, move forward and do not turn. Rebuild a new targetPath after we have passed the turn.
                        //If we can't move forward anymore, then turn.
                        nextTileCoord = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:self.direction];
                        CGPoint nextPlayerCoord = [self getNextTileCoordWithTileCoord:lastPlayerCoord andDirection:lastPlayerDirection];
                        
                        if (![mapDelegate isCollidableWithTileCoord:nextTileCoord]) {
                            self.targetPath = [mapDelegate getPathPointsFrom:nextTileCoord to:nextPlayerCoord withDirection:direction];
                            targetTile = [self getNextTileCoordWithPath:targetPath];
                        }
                    }
                }
                break;
            }
        }
            
        case kStateAlarmed:
        {
            self.state = kStatePatrolling;
            //search for player in an alarmed state;
        }
    }

    if(!CGPointEqualToPoint(targetTile, ccp(-1, -1))) {
        nextDirection = [self getDirectionWithTileCoord:targetTile];
        if(nextDirection != kDirectionNull) {
            self.direction = nextDirection;
        }
        [self updateSprite];
        [self moveToTileCoord:targetTile withDeltaTime:deltaTime];
    }
}

-(void) updateSprite
{
    if (direction == kDirectionUp) {
        [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kEnemyCarVerticalImage]];
        self.flipY = NO;
    }
    else if(direction == kDirectionRight) {
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kEnemyCarImage];
        [self setDisplayFrame:frame];
        self.flipX = YES;
    }
    else if(direction == kDirectionDown) {
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kEnemyCarVerticalImage];
        [self setDisplayFrame:frame];
        self.flipY = YES;
    }
    else if(direction == kDirectionLeft) {
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kEnemyCarImage];
        [self setDisplayFrame:frame];
        self.flipX = NO;
    }
}
@end

