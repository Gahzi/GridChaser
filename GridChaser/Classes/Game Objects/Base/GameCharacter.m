//
//  GameCharacter.m
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-08-12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameCharacter.h"

@implementation GameCharacter

@synthesize characterHealth,targetTile,targetPath,direction,turnLimit,velocity,acceleration,topSpeed;

- (id)init
{
    self = [super init];
    if (self) {
        velocity = 40;
        targetTile = ccp(-1, -1);
        targetPath = [[NSMutableArray alloc] init];
        acceleration = 10;
        topSpeed = 125;
        characterHealth = 100;
        direction = kDirectionNull;
        turnLimit = 2;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
    [targetPath release];
}

-(void) updateWithDeltaTime:(ccTime)deltaTime andArrayOfGameObjects:(CCArray *)arrayOfGameObjects
{
    //OVERLOAD ME
}

-(void) updateSprite
{
    //This method should update the GameCharacter's sprite
    //based on the direction that the GameCharacter is facing
#if GRID_CHASER_DEBUG_MODE
    CCLOG(@"updateSprite should be overridden");
#endif
    
}

-(void) moveToTileCoord:(CGPoint)newTileCoord withDeltaTime:(ccTime)deltaTime
{
    CGPoint newPosition = [mapDelegate centerPositionFromTileCoord:newTileCoord];
    
    if (CGPointEqualToPoint(newTileCoord, ccp(-1, -1))) {
#if GRID_CHASER_DEBUG_MODE
        CCLOG(@"Attempting to move to -1,-1 with %@",NSStringFromClass([self class]));
#endif
    }
    
    if(![self.mapDelegate isCollidableWithTileCoord:newTileCoord]) {
        float deltaDistance = deltaTime * velocity;
        CGPoint moveDifference = ccpSub(newPosition, self.position);
        float distanceToMove = ccpLength(moveDifference);
        
        CGPoint newLocation;
        CGPoint deltaLocation = ccp(deltaDistance*moveDifference.x/distanceToMove,deltaDistance*moveDifference.y/distanceToMove);
        newLocation = ccpAdd(self.position, deltaLocation);
        self.position = newLocation;
    }
}

-(void) moveWithPath:(NSMutableArray *)path withDeltaTime:(ccTime)deltaTime
{
    //Check to see if path is valid
    //grab the next position from the path, get the center tile coordinate.
    CGPoint currentTileCoord = self.tileCoordinate;
    CGPoint nextTileCoord = CGPointFromString([path objectAtIndex:0]);
    CGPoint nextPosition = [mapDelegate centerPositionFromTileCoord :nextTileCoord];
    
    //check to see if we are not already at the first point
    if(CGPointEqualToPoint(currentTileCoord,nextTileCoord)) {
        [path removeObject:NSStringFromCGPoint(nextTileCoord)];
        
        if([path count] == 0) {
            //state = kStateIdle;
            return;
        }
        else {
            nextTileCoord = CGPointFromString([path objectAtIndex:0]);
            nextPosition = [mapDelegate centerPositionFromTileCoord:nextTileCoord];
        }
    }
    [self moveToTileCoord:nextTileCoord withDeltaTime:deltaTime];
}

-(void) moveWithDirection:(CharacterDirection)dir withDeltaTime:(ccTime)deltaTime 
{    
    if (dir == kDirectionNull) {
#if GRID_CHASER_DEBUG_MODE
        CCLOG(@"Attempting to move with null direction");
        return;
#endif
    }
    
    float deltaDistance = deltaTime * velocity;
    CGPoint newPosition;
    
    switch (dir) {
        case kDirectionDown:  {
            newPosition = ccp(0, deltaDistance); 
            break;
        }
        case kDirectionLeft:{
            newPosition = ccp(-deltaDistance, 0);
            break;
        }
        case kDirectionRight:  {
            newPosition = ccp(deltaDistance, 0);  
            break;
        }          
        case kDirectionUp:  {
            newPosition = ccp(0, -deltaDistance);  
            break;
        }          
        
        default:
            break;
    }
    
    newPosition = ccpAdd(self.position, newPosition);
    
    if(![self.mapDelegate isCollidableWithTileCoord:[mapDelegate tileCoordForPosition:newPosition]]) {
    self.position = newPosition;
    }
    else {
        CGPoint newTileCord = [mapDelegate tileCoordForPosition:newPosition];
        newTileCord = [self getAdjacentTileCoordFromTileCoord:newTileCord WithDirection:[self getOppositeDirectionFromDirection:dir]];
        [self moveToTileCoord:newTileCord withDeltaTime:deltaTime];
    }
}

-(BOOL) attemptLaneChangeWithDirection:(CharacterDirection)newDirection
{
    CGPoint adjacentSideTile;
    CGPoint adjacentForwardTile;
    CGPoint adjacentBackwardTile;
    BOOL isLaneChanging = NO;
    
    if (!(direction == newDirection || direction == [self getOppositeDirectionFromDirection:newDirection])) {
        adjacentSideTile = [self getAdjacentTileCoordFromTileCoord:self.tileCoordinate WithDirection:newDirection];
        adjacentForwardTile = [self getAdjacentTileCoordFromTileCoord:adjacentSideTile WithDirection:direction];
        adjacentBackwardTile = [self getAdjacentTileCoordFromTileCoord:adjacentSideTile WithDirection:[self getOppositeDirectionFromDirection:direction]];
        
        if (![mapDelegate isCollidableWithTileCoord:adjacentSideTile] && 
            ![mapDelegate isCollidableWithTileCoord:adjacentForwardTile] && 
            ![mapDelegate isCollidableWithTileCoord:adjacentBackwardTile]) {
            
            isLaneChanging = YES;
            targetTile = adjacentForwardTile;
        }
    }
    return isLaneChanging;
}
              
-(CharacterTurnAttempt) attemptTurnWithDirection:(CharacterDirection)newDirection andDeltaTime:(ccTime)deltaTime
{
    CGPoint nextTileCoord = self.tileCoordinate;
    BOOL isNextTileCollidable = YES;
    int i = 1;
    
    while (i <= turnLimit) {
        nextTileCoord = [self getNextTileCoordWithTileCoord:nextTileCoord andDirection:newDirection];
        isNextTileCollidable = [mapDelegate isCollidableWithTileCoord:nextTileCoord];
        
        if (!isNextTileCollidable) {
            break;
        }
        else {
            nextTileCoord = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:direction]; 
            i++;
        }
    }
    
    if (isNextTileCollidable) {
        return kTurnAttemptFailed;
    }
    else {
        CGPoint moveDifference = ccpSub(self.position, [mapDelegate centerPositionFromTileCoord:nextTileCoord]);
        float distanceToMove = ccpLength(moveDifference);
        
        CCLOG(@"distanceToMove: %f",distanceToMove);
        CharacterTurnAttempt turnAttempt;
        if (distanceToMove < kTurnAttemptPerfect ) {
            turnAttempt = kTurnAttemptPerfect;
            CCLOG(@"Perfect!");
        }
        else if(distanceToMove < kTurnAttemptGood) {
            turnAttempt = kTurnAttemptGood;
            CCLOG(@"Good!");
        }
        else if(distanceToMove < kTurnAttemptOkay) {
            turnAttempt = kTurnAttemptOkay;
            CCLOG(@"Okay!");
        }
        else if(distanceToMove < kTurnAttemptOkay) {
            turnAttempt = kTurnAttemptPoor;
            CCLOG(@"Poor!");
        }
        targetTile = nextTileCoord;
        return turnAttempt;
    }
}

-(CharacterDirection) getDirectionWithTileCoord:(CGPoint) tileCoord
{
    CharacterDirection nextDirection = kDirectionNull;
    CGPoint tileCoordSub = ccpSub(tileCoord,self.tileCoordinate );
    
    if(tileCoordSub.y <= -1) {
        nextDirection = kDirectionUp;
    }
    else if(tileCoordSub.y >= 1) {
        nextDirection = kDirectionDown;
    }
    else if(tileCoordSub.x >= 1) {
        nextDirection = kDirectionRight;
    }
    else if(tileCoordSub.x <= -1) {
        nextDirection = kDirectionLeft;
    }
    return nextDirection;
}

-(CharacterDirection) getOppositeDirectionFromDirection:(CharacterDirection) dir
{
    CharacterDirection oppositeDirection = kDirectionNull;
        switch (dir) {
            case kDirectionUp:
                oppositeDirection = kDirectionDown;
                break;
                
            case kDirectionDown:
                oppositeDirection = kDirectionUp;
                break;
                
            case kDirectionLeft:
                oppositeDirection = kDirectionRight;
                break;
                
            case kDirectionRight:
                oppositeDirection = kDirectionLeft;
                break;
                
            case kDirectionNull:
#if GRID_CHASER_DEBUG_MODE
                CCLOG(@"Warning: Attempting to get opposite direction of kNullDirection");
#endif
                oppositeDirection = kDirectionNull;
                break;
                
            default:
#if GRID_CHASER_DEBUG_MODE
                CCLOG(@"Warning: Attempting to get opposite direction of a non CharacterDirection object");
#endif                
                oppositeDirection = kDirectionNull;
                break;
        }
    return oppositeDirection;
}

-(CGPoint) getAdjacentTileCoordFromTileCoord:(CGPoint)tileCoord WithDirection:(CharacterDirection) dir
{
    CGPoint adjacentTileCoord;
    //SHERVIN: Remove code which relies on adjacentTiles[][] order to work.
    switch (dir) {
        case kDirectionUp:
        {
            adjacentTileCoord = ccp(adjacentTiles[kDirectionUp][0],adjacentTiles[kDirectionUp][1]);
            break;
        }
        case kDirectionRight:
        {
            adjacentTileCoord = ccp(adjacentTiles[kDirectionRight][0],adjacentTiles[kDirectionRight][1]);
            break;
        }
        case kDirectionDown:
        {
            adjacentTileCoord = ccp(adjacentTiles[kDirectionDown][0],adjacentTiles[kDirectionDown][1]);
            break;
        }
        case kDirectionLeft:
        {
            adjacentTileCoord = ccp(adjacentTiles[kDirectionLeft][0],adjacentTiles[kDirectionLeft][1]);
            break;
        }
        default:
        {
            CCLOG(@"Could not find adjacent tile coord, double check characterDirection given");
        }
            break;
    }
    adjacentTileCoord = ccpAdd(tileCoord,adjacentTileCoord);
    return adjacentTileCoord;
}

-(CGPoint) getNextTileCoordWithPath:(NSMutableArray *)path
{
    CGPoint nextTileCoord = ccp(-1, -1);
    
    //grab the next position from the path, get the center tile coordinate.
    CGPoint currentTileCoord = self.tileCoordinate;
    nextTileCoord = CGPointFromString([path objectAtIndex:0]);
    
    //check to see if we are not already at the first point
    if(CGPointEqualToPoint(currentTileCoord,nextTileCoord)) {
        [path removeObject:NSStringFromCGPoint(nextTileCoord)];
        
        if([path count] == 0) {
            return nextTileCoord;
        }
        else {
            nextTileCoord = CGPointFromString([path objectAtIndex:0]);
        }
    }
    return nextTileCoord;
}

-(CGPoint) getNextTileCoordWithTileCoord:(CGPoint)tileCoord andDirection:(CharacterDirection)dir
{
    CGPoint nextTileLocation = tileCoord;
    
    switch (dir) {
        case kDirectionUp:
            nextTileLocation.y -= 1;
            break;
            
        case kDirectionDown:
            nextTileLocation.y += 1;
            break;
            
        case kDirectionLeft:
            nextTileLocation.x -= 1;
            break;
            
        case kDirectionRight:
            nextTileLocation.x += 1;
            break;
            
        default:
            break;
    }
    return nextTileLocation;
}

@end
