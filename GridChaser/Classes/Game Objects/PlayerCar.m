//
//  PlayerCar.m
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-08-12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlayerCar.h"

@interface PlayerCar (Private)
- (void) updateInput;
@end

@implementation PlayerCar

#define kBaseVelocity 50

@synthesize gameplayLayerDelegate;
@synthesize attemptedTurnDirection,state,isLaneChanging;
@synthesize upButton,leftButton,rightButton,downButton,lastPressedButton;

-(id) init
{
    if(self = [super init]) {
        attemptedTurnDirection = kDirectionNull;
        velocity = kBaseVelocity;
        acceleration = 40;
        topSpeed = 200;
        direction = kDirectionRight;
        lastPressedButton = nil;
        isLaneChanging = NO;
        turnLimit = 3;
    }
    return self;
}

- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
    gameplayLayerDelegate = nil;
}


#pragma mark -
#pragma TurnDirection
- (CharacterTurnAttempt) attemptTurnWithDirection:(CharacterDirection)newDirection andDeltaTime:(ccTime)deltaTime
{
    CharacterTurnAttempt turnAttempt = [super attemptTurnWithDirection:newDirection andDeltaTime:deltaTime];
    
    switch (turnAttempt) {
        case kTurnAttemptPerfect: {
            velocity = velocity + 100 * deltaTime;
            break; 
        }
        case kTurnAttemptGood: {
            velocity = velocity + 50 * deltaTime;
            break;
        }
        case kTurnAttemptOkay: {
            break;
        }
        case kTurnAttemptPoor: {
            velocity = velocity - 50 * deltaTime;
            break;
        }
        case kTurnAttemptFailed: {
            velocity = kBaseVelocity;
            break;
        }
            
        default:
            break;
    }
    return turnAttempt;
}

- (void)setState:(PlayerState)newState
{
    switch (newState) {
        case kStateIdle:
            velocity = kBaseVelocity;
            break;
            
        case kStateMoving:
            break;
            
        default:
            break;
    }
    state = newState;
}

-(void)updateWithDeltaTime:(ccTime)deltaTime andArrayOfGameObjects:(CCArray *)arrayOfGameObjects
{
    [self updateInput];
    
    //SHERVIN:Abstract out velocity addition to be in GameCharacter.m
    float newVelocity = velocity + acceleration * deltaTime;
    
    if (newVelocity > topSpeed) {
        velocity = topSpeed;
    }
    else if (newVelocity < kBaseVelocity) {
        velocity = kBaseVelocity;
    }
    else {
        velocity = newVelocity;
    }
    
    CGPoint nextTileCoord = ccp(-1, -1);
    CharacterDirection nextDirection = kDirectionNull;
    
    GameObject *marker = nil;
    for (GameObject *tempObj in arrayOfGameObjects) {
        if(tempObj.tag == kMarkerTag) {
            marker = (Marker*)tempObj; 
        }
    }
    
    if(marker != nil) {
        CGRect markerBoundingBox = [marker boundingBox];
        CGRect boundingBox = [self boundingBox];
        
        if(CGRectIntersectsRect(boundingBox, markerBoundingBox)) {
            [marker setVisible:NO];
            [marker removeFromParentAndCleanup:YES];
            [gameplayLayerDelegate addGameObjectWithType:kGameObjectMarker withTileCoord:ccp(-1, -1)];
        }
    }
    
    switch (state) 
    {
        case kStateIdle:
        {
            velocity = kBaseVelocity;
            if (attemptedTurnDirection != kDirectionNull) {
                nextTileCoord = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:attemptedTurnDirection];
                attemptedTurnDirection = kDirectionNull;
                nextDirection = [self getDirectionWithTileCoord:nextTileCoord];
                if (nextDirection != self.direction && nextDirection != kDirectionNull && nextDirection != [self getOppositeDirectionFromDirection:self.direction]) {
                    if ([self attemptTurnWithDirection:nextDirection andDeltaTime:deltaTime] == kTurnAttemptFailed) {
                        targetTile = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:self.direction];
                        break;
                    }
                    else {
                        self.targetPath = [mapDelegate getPathPointsFrom:self.tileCoordinate to:targetTile withDirection:direction];
                        targetTile = [self getNextTileCoordWithPath:targetPath];
                        self.state = kStateMoving;
                        break;

                    }
                }
            }
            break;
        } 
        case kStateMoving:
        {
            if (attemptedTurnDirection != kDirectionNull) {
                nextTileCoord = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:attemptedTurnDirection];
                attemptedTurnDirection = kDirectionNull;
                nextDirection = [self getDirectionWithTileCoord:nextTileCoord];
                if (nextDirection != self.direction && nextDirection != kDirectionNull && nextDirection != [self getOppositeDirectionFromDirection:self.direction]) {
                    if (!([self attemptTurnWithDirection:nextDirection andDeltaTime:deltaTime] == kTurnAttemptFailed)) {
                        self.targetPath = [mapDelegate getPathPointsFrom:self.tileCoordinate to:targetTile withDirection:direction];
                        break;
                    }
                }
            }
            else if(isLaneChanging) {
                if(CGPointEqualToPoint(self.tileCoordinate, targetTile)) {
                    isLaneChanging = NO;
                }
            }
        }
    }
    
    if(targetPath.count > 0) {
        targetTile = [self getNextTileCoordWithPath:targetPath];
    }
    else {
        if (!isLaneChanging) {
            targetTile = [self getNextTileCoordWithTileCoord:self.tileCoordinate andDirection:direction];
        }
    }
    
    if([mapDelegate isCollidableWithTileCoord:targetTile] && self.state != kStateIdle) {
        self.state = kStateIdle;
    }
    else {
        //if we need to change the direction because we turned, then turn;
        nextDirection = [self getDirectionWithTileCoord:targetTile];
        if(nextDirection != self.direction && nextDirection != kDirectionNull && !isLaneChanging) {
            self.direction = nextDirection;
        }
        [self updateSprite];
        [self moveToTileCoord:targetTile withDeltaTime:deltaTime];
    }
}

- (void)updateSprite
{
    if (direction == 0) {
        [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kPlayerCarVerticalImage]];
        self.flipY = NO;
    }
    else if(direction == 1) {
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kPlayerCarImage];
        [self setDisplayFrame:frame];
        self.flipX = YES;
    }
    else if(direction == 2) {
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kPlayerCarVerticalImage];
        [self setDisplayFrame:frame];
        self.flipY = YES;
    }
    else if(direction == 3) {
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:kPlayerCarImage];
        [self setDisplayFrame:frame];
        self.flipX = NO;
    }
}

- (void) updateInput
{
    BOOL isButtonSelected = upButton.isSelected || leftButton.isSelected || rightButton.isSelected || downButton.isSelected;
    
    if (isButtonSelected && lastPressedButton == nil) {
        //start braking
        if(upButton.isSelected == YES)
        {
            lastPressedButton = upButton;
        }
        else if(leftButton.isSelected == YES)
        {
            lastPressedButton = leftButton;
        }
        else if(rightButton.isSelected == YES)
        {
            lastPressedButton = rightButton;
        }
        else if(downButton.isSelected == YES)
        {
            lastPressedButton = downButton;
        }
        acceleration = -30;
    }
    else if(!isButtonSelected && lastPressedButton != nil) {
        
        if(lastPressedButton == upButton)
        {
            isLaneChanging = [self attemptLaneChangeWithDirection:kDirectionUp];
            
            if (!isLaneChanging) {
                self.attemptedTurnDirection = kDirectionUp;
            }
        }
        else if(lastPressedButton == leftButton)
        {
            isLaneChanging = [self attemptLaneChangeWithDirection:kDirectionLeft];
            
            if (!isLaneChanging) {
                self.attemptedTurnDirection = kDirectionLeft;
            }
        }
        else if(lastPressedButton == rightButton)
        {
            isLaneChanging = [self attemptLaneChangeWithDirection:kDirectionRight];
            
            if (!isLaneChanging) {
                self.attemptedTurnDirection = kDirectionRight;
            }
        }
        else if(lastPressedButton == downButton)
        {
            isLaneChanging = [self attemptLaneChangeWithDirection:kDirectionDown];
            
            if (!isLaneChanging) {
                self.attemptedTurnDirection = kDirectionDown;
            }
        }
        lastPressedButton = nil;
        acceleration = 10;
    }
}

#pragma mark CCTargetedTouch Methods
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    location = [self.parent convertToNodeSpace:location];
    
    CGRect boundingBox = [self boundingBox];
    
    if(CGRectContainsPoint(boundingBox, location)) {
        CCLOG(@"Touching Player!");
        isTouched = YES;
        return YES;
    }
    else {
        //Assume player is attempting to use their active ability
        //active ability code;
    }
        return YES;
}
@end
