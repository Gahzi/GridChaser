//
//  PlayerCar.h
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-08-12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameCharacter.h"
#import "Marker.h"
#import "Constants.h"

#define kTurnLimit 2

@interface PlayerCar : GameCharacter <CCTargetedTouchDelegate> {
    CGPoint lastTurnedTileCoord;
    BOOL hasTurnedCorrectly;
    BOOL isBraking;
    CharacterDirection attemptedTurnDirection;
    PlayerState state;
    id<GameplayLayerDelegate> gameplayLayerDelegate;

    CCMenuItem *upButton;
    CCMenuItem *leftButton;
    CCMenuItem *rightButton;
    CCMenuItem *downButton;
    CCMenuItem *lastPressedButton;
}

@property (nonatomic,readwrite,assign) CGPoint lastTurnedTileCoord;
@property (nonatomic,readwrite,assign) CharacterDirection attemptedTurnDirection;
@property (nonatomic,readwrite,assign) PlayerState state;
@property (nonatomic,readwrite,assign) id<GameplayLayerDelegate> gameplayLayerDelegate;
@property (nonatomic,readwrite,assign) CCMenuItem *upButton;
@property (nonatomic,readwrite,assign) CCMenuItem *leftButton;
@property (nonatomic,readwrite,assign) CCMenuItem *rightButton;
@property (nonatomic,readwrite,assign) CCMenuItem *downButton;
@property (nonatomic,readwrite,assign) CCMenuItem *lastPressedButton;

@end