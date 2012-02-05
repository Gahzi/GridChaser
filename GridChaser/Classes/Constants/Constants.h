//
//  Constants.h
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-07-30.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef GridChaser_Constants_h
#define GridChaser_Constants_h

#ifndef GRID_CHASER_DEBUG_MODE
#define GRID_CHASER_DEBUG_MODE 0
#endif

#define kPlayerCarTag 1
#define kEnemyCarTag 2
#define kMarkerTag 3

#define kGameObjectZValue 100

#pragma mark -
#pragma mark MapLayers

#define kMapForegroundLayer @"Foreground"
#define kMapBackgroundLayer @"Background"
#define kMapObjectLayer @"Objects"
#define kMapCollisionLayer @"Collision"

#pragma mark - 
#pragma mark MapProperties

#define kMapCollidableProperty @"Collidable"

#pragma mark -
#pragma mark MapPropertyValues
#define kMapTrue @"True"
#define kMapFalse @"False"

#pragma mark - 
#pragma mark MapObjects

#define kMapObjectSpawnPoint1 @"SpawnPoint1"
#define kMapObjectSpawnPoint2 @"SpawnPoint2"

#pragma mark -
#pragma mark CharacterStates

typedef enum {
    kStateIdle,
    kStateMoving,
} PlayerState; 

typedef enum {
    kStatePatrolling,
    kStateCautiousPatrolling,
    kStateCreeping,
    kStateChasing,
    kStateAlarmed,
} EnemyState; 


//SHERVIN: redesign turn attempt so that it is merged with SuccessRate;
#pragma TurnAttempt
typedef enum {
    kTurnAttemptPerfect = 5,
    kTurnAttemptGood = 10,
    kTurnAttemptOkay = 20,
    kTurnAttemptPoor = 30,
    kTurnAttemptTerrible = 40,
    kTurnAttemptSuccess,
    kTurnAttemptFailed,
    kTurnNotAttempted
} CharacterTurnAttempt;

#define kSuccessRatePerfect 100

#pragma mark -
#pragma mark CharacterDirection
typedef enum {
    kDirectionUp = 0,
    kDirectionRight = 1,
    kDirectionDown = 2,
    kDirectionLeft = 3,
    kDirectionNull
} CharacterDirection; 

#pragma mark -
#pragma mark GameObjectTypes
typedef enum {
    kGameObjectMarker,
    kGameObjectEnemyCar
} GameObjectType;

#pragma mark -
#pragma mark AdjacentTiles
static const int numAdjacentTiles = 4;

//SHERVIN: Add a const CGPoint representing ccp(-1,-1) and remove all ccp(-1,-1) calls.

//SHERVIN: adjacent tiles must be defined in correct order
// Up,Right,Down,Left otherwise pathing will not work correctly.
// Changes will also have to be made to AStarPathFinder.m ~line 75
static const int adjacentTiles[4][2] = { 0,-1, 1,0, 0,1, -1,0 };

#pragma mark -
#pragma mark GameplayLayerDelegate
@protocol GameplayLayerDelegate
- (void) addGameObjectWithType:(GameObjectType)type withTileCoord:(CGPoint)tileCoord;
@end

#pragma mark - 
#pragma mark MapDelegate
@protocol MapDelegate
- (CGPoint)tileCoordForPosition:(CGPoint)position;
- (CGPoint) centerPositionFromTileCoord:(CGPoint)tileCoord;
- (NSMutableArray*) getPathPointsFrom:(CGPoint)origTileCoord to:(CGPoint)destTileCoord withDirection:(CharacterDirection) startingDirection;;
- (BOOL) isPathValid:(NSMutableArray*)path;
- (BOOL) isCollidableWithTileCoord:(CGPoint)tileCoord;
- (CGSize) getMapSize;
- (CGSize) getTileSize;
@end

#endif
