/*
 * cocos2d+ext for iPhone
 *
 * Copyright (c) 2011 - Ngo Duc Hiep
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "CCBlade.h"

inline float fangle(CGPoint vect){
	if (vect.x == 0.0 && vect.y == 0.0) {
		return 0;
	}
	
	if (vect.x == 0.0) {
		return vect.y > 0 ? M_PI/2 : -M_PI/2;
	}
	
	if (vect.y == 0.0 && vect.x < 0) {
		return -M_PI;
	}
	
	float angle = atan(vect.y / vect.x);
	
	return vect.x < 0 ? angle + M_PI : angle;
}

inline void f1(CGPoint p1, CGPoint p2, float d, CGPoint *o1, CGPoint *o2){
	float l = ccpDistance(p1, p2);
	float angle = fangle(ccpSub(p2, p1));// CC_DEGREES_TO_RADIANS([CCNode degree:ccpSub(p2, p1)]);
	*o1 = ccpRotateByAngle(ccp(p1.x + l,p1.y + d), p1, angle);
	*o2 = ccpRotateByAngle(ccp(p1.x + l,p1.y - d), p1, angle);
}

inline void f2(CGPoint p1, CGPoint p2, float d, CGPoint *o1, CGPoint *o2){
	float l = ccpDistance(p1, p2);
	float angle = fangle(ccpSub(p2, p1));
	*o1 = ccpRotateByAngle(ccp(p1.x + l,p1.y + d), p1, angle);
	*o2 = ccpRotateByAngle(ccp(p1.x + l,p1.y - d), p1, angle);
}

inline float lagrange2(CGPoint p1, CGPoint p2, CGPoint p3, float x){
	return 0;
}

inline float lagrange1(CGPoint p1, CGPoint p2, float x){
	return (x-p1.x)/(p2.x - p1.x)*p2.y + (x-p2.x)/(p1.x - p2.x)*p1.y ;
}

inline void CGPointSet(CGPoint *v, float x, float y){
	v->x = x;
	v->y = y;
}

@implementation CCBlade
@synthesize texture = _texture;
@synthesize pointLimit;
@synthesize width;

- (id) init{
	self = [super init];
	CGPointSet(coordinates+0, 0.00, 0.5);
	//CGPointSet(coordinates+1, 0.25, 1.0); 
	//CGPointSet(coordinates+2, 0.25, 0.0); 
	
	for (int i = 1 ; i < POINT_LIMIT - 1; i++) {
		//CGPointSet(coordinates+2*i+1, 0.5, 1.0); 
		//CGPointSet(coordinates+2*i+2, 0.5, 0.0); 
	}
	
	pointLimit = POINT_LIMIT;
	width = 6;
	
	self.texture = [[CCTextureCache sharedTextureCache] addImage:@"streak.png"];
	
	return self;
}

- (void) dealloc{
	[_texture release];
	[super dealloc];
}

- (void) populateVertices{
	list<CGPoint>::iterator it=path.begin();
	vertices[0] = *it;
	it++;
	
	//[self shift];
//	int index = 2 * pointLimit - 1;
//	for (int i = index; i > 3; i -= 2) {
//		vertices[i] = vertices[i-2];
//		vertices[i-1] = vertices[i-3];
//	}
//	
	
	CGPoint pre = vertices[0];
//	f1(pre, *it, d - i * dd , vertices+2*i+1, vertices+2*i+2);
	
	unsigned int i = 0;
	//float d = 16.;
	float dd = width / path.size();
	while (i < path.size() - 2){
		f1(pre, *it, width - i * dd , vertices+2*i+1, vertices+2*i+2);
		CGPointSet(coordinates+2*i+1, .5, 1.0);
		CGPointSet(coordinates+2*i+2, .5, 0.0);
		
		i++;
		pre = *it;
		
		it++;
	}
	
	CGPointSet(coordinates+1, 0.25, 1.0); 
	CGPointSet(coordinates+2, 0.25, 0.0);
	
	vertices[2*path.size()-3] = *it;
	CGPointSet(coordinates+2*path.size()-3, 0.75, 0.5);
}

- (void) shift{
	int index = 2 * pointLimit - 1;
	for (int i = index; i > 3; i -= 2) {
		vertices[i] = vertices[i-2];
		vertices[i-1] = vertices[i-3];
	}
}

#define DISTANCE_TO_INTERPOLATE 10

- (void) push:(CGPoint) v{
	if (reset) {
		return;
	}
#if USE_LAGRANGE
	if (path.size() == 0) {
		path.push_front(v);
		return;
	}
	CGPoint first = *path.begin();
	float d = ccpDistance(v, first);
	if (d < DISTANCE_TO_INTERPOLATE) {
		path.push_front(v);
		if (path.size() > pointLimit) {
			path.pop_back();
		}
	}else {
		int num = d / DISTANCE_TO_INTERPOLATE;
		CGPoint iv = ccpMult(ccpSub(v, first), (float)1./(num + 1));
		for (int i = 1; i <= num + 1; i++) {
			path.push_front(ccpAdd(first, ccpMult(iv, i)));
		}
		//path.push_front(v);
		while (path.size() > pointLimit) {
			path.pop_back();
		}
	}
#else
	path.push_front(v);
	if (path.size() > pointLimit) {
		path.pop_back();
	}
#endif
	
	[self populateVertices];
}

- (void) pop{
	if (path.size() > 0) {
		path.pop_back();
		[self populateVertices];
	}
}

- (void) clear{
	path.clear();
	reset = NO;
} 

- (void) reset{
	reset = TRUE;
}

- (void) dim:(BOOL) dim{
	reset = dim;
}

- (void) draw{
	if (reset) {
		[self pop];
		if (path.size() < 3) {
			[self clear];
		}
	}
	
	if (path.size() < 3) {
		return;
	}
	
	glPushMatrix();
    glDisableClientState(GL_COLOR_ARRAY);
    
    glBindTexture(GL_TEXTURE_2D, _texture.name);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 2*path.size()-2);
    
	glEnableClientState(GL_COLOR_ARRAY);
    glPopMatrix();	
}
@end
