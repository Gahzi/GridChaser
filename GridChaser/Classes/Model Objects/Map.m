//
//  Map.m
//  GridChaser
//
//  Created by Shervin Ghazazani on 11-08-29.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Map.h"


@implementation Map

@synthesize backgroundLayer,collisionLayer,foregroundLayer;

- (id)init
{
    self = [super initWithTMXFile:kMapTestLevel4TMX];
    if (self) {
        backgroundLayer = [self layerNamed:kMapBackgroundLayer];
        foregroundLayer = [self layerNamed:kMapForegroundLayer];
        collisionLayer = [self layerNamed:kMapCollisionLayer];
        collisionLayer.visible = NO;
        pathFinder = [[AStarPathFinder alloc] initWithTiledMap:self withCollisionLayer:collisionLayer];
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
    [pathFinder release];
    backgroundLayer = nil;
    foregroundLayer = nil;
    collisionLayer = nil;
}

- (CGPoint) tileCoordForPosition:(CGPoint)position
{
    int x = position.x / self.tileSize.width;
    int y = ((self.mapSize.height * self.tileSize.height) - position.y) / self.tileSize.height;
    return ccp(x, y);
}

- (CGPoint) centerPositionFromTileCoord:(CGPoint)tileCoord
{
    CGPoint newPosition = [collisionLayer positionAt:tileCoord];
    newPosition.x += self.tileSize.width * 0.5;
    newPosition.y += self.tileSize.height * 0.5;
    return newPosition;
}

- (CGSize) getMapSize
{
    return self.mapSize;
}

- (CGSize) getTileSize
{
    return self.tileSize;
}

- (NSMutableArray*) getPathPointsFrom:(CGPoint)origTileCoord to:(CGPoint)destTileCoord withDirection:(CharacterDirection) startingDirection
{
    return [pathFinder getPathPointsFrom:origTileCoord to:destTileCoord withDirection:startingDirection];
}

- (BOOL) isCollidableWithTileCoord:(CGPoint)tileCoord
{
    return [pathFinder isCollidableWithTileCoord:tileCoord];
}

- (BOOL) isPathValid:(NSMutableArray *)path
{
    return [pathFinder isPathValid:path];
}

@end
