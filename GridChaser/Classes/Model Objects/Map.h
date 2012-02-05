//
//  Map.h
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-08-29.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Constants.h"
#import "FileConstants.h"
#import "AStarPathFinder.h"

@interface Map : CCTMXTiledMap <MapDelegate> {
    CCTMXLayer *backgroundLayer;
    CCTMXLayer *collisionLayer;
    CCTMXLayer *foregroundLayer;
    AStarPathFinder *pathFinder;
}

- (BOOL) isCollidableWithTileCoord:(CGPoint)tileCoord;
- (BOOL) isPathValid:(NSMutableArray *)path;
- (CGPoint) tileCoordForPosition:(CGPoint)position;
- (NSMutableArray*) getPathPointsFrom:(CGPoint)origTileCoord to:(CGPoint)destTileCoord withDirection:(CharacterDirection) startingDirection; 
- (CGPoint) centerPositionFromTileCoord:(CGPoint)tileCoord;

@property (nonatomic,assign) CCTMXLayer *backgroundLayer;
@property (nonatomic,assign) CCTMXLayer *collisionLayer;
@property (nonatomic,assign) CCTMXLayer *foregroundLayer;

@end

