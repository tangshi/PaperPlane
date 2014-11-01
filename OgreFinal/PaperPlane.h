//
//  Plane.h
//  OgreFinal
//
//  Created by 唐 仕 on 13-10-21.
//
//

#ifndef __OgreFinal__Plane__
#define __OgreFinal__Plane__

#include "OgreFramework.h"
#include "OgreAudioPlayer.h"

using namespace Ogre;


class PaperPlane {
    
public:
    PaperPlane() { _initPaperPlane(); }
    
    ~PaperPlane();
    
    Ogre::SceneNode* getPaperPlaneNode() { return paperPlaneNode;}
    void             setPaperPlaneNode(SceneNode* node) { paperPlaneNode = node;}
    
    void             translate(const Vector3&);
    void             scale(const Vector3&);
    void             roll(const Radian& angle, Node::TransformSpace relativeTo = Node::TS_LOCAL);
    void             pitch(const Radian& angle, Node::TransformSpace relativeTo = Node::TS_LOCAL);
    void             yaw(const Radian& angle, Node::TransformSpace relativeTo = Node::TS_LOCAL);
    void             setPosition(const Vector3& vec);
    const Vector3&   getPosition();
    
    
    
    Entity*          getPaperPlaneEntity() { return paperPlaneEntity;}
    void             setPaperPlaneEntity(Entity *entity) { paperPlaneEntity = entity;}
    
    float            getHeight() { return height; }
    void             setHeight(float);
    bool             drop();
    
    float            getSpeed() { return speed;}
    void             setSpeed(float newSpeed) { speed = newSpeed;}
    
    void             windBlow();
    void             stopWindBlow();
    bool             isWindBlowing();
    AnimationState*  paperPlaneAniSta;
    
//    Vector3         lastPosition;
//    Vector3         getLastPosition() { return lastPosition; }
    
protected:
    
    SceneNode*       paperPlaneNode;
    Entity*          paperPlaneEntity;
    
    float            height;
    float            speed;
    
    OgreAudioPlayer* windBlowAudioPlayer;
    
    
private:
    
    bool             _isWindBlowing;
    void             _initPaperPlane();
};


#endif /* defined(__OgreFinal__Plane__) */
