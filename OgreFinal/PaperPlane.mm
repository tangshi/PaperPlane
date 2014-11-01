//
//  Plane.cpp
//  OgreFinal
//
//  Created by 唐 仕 on 13-10-21.
//
//

#include "PaperPlane.h"

void PaperPlane::_initPaperPlane()
{

    paperPlaneNode = 0;
    paperPlaneEntity = 0;
    paperPlaneAniSta = 0;
    height = 1000;
    speed = 0.01;
    _isWindBlowing = false;
//    lastPosition = Vector3(0,0,0);
    
    NSString *soundPath=[[NSBundle mainBundle] pathForResource:@"windBlowAudio" ofType:@"wav"];
    NSURL *soundUrl=[[NSURL alloc] initFileURLWithPath:soundPath];
    windBlowAudioPlayer = [[OgreAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [windBlowAudioPlayer prepareToPlay];
    [soundUrl release];
    
}

PaperPlane::~PaperPlane()
{
    if (paperPlaneNode)
    {
        delete paperPlaneNode;
        paperPlaneNode = NULL;
    }
    
    if (paperPlaneEntity)
    {
        delete paperPlaneEntity;
        paperPlaneEntity = NULL;
    }
    
    if (paperPlaneAniSta)
    {
        delete paperPlaneAniSta;
        paperPlaneAniSta = NULL;
    }
    
    [windBlowAudioPlayer release];
}

void PaperPlane::setHeight(float newHeight)
{
    height = newHeight>0 ? newHeight:0;
//    lastPosition = paperPlaneNode->getPosition();
    paperPlaneNode->setPosition(Vector3(0, height, 0));
}


bool PaperPlane::drop()
{
    height -= 0.01;
    if (height <= 0) {
        //game over!!!
        return false;
    }
    paperPlaneNode->translate(Vector3(0, -speed*0.1, 0));
    return true;
}

void PaperPlane::translate(const Vector3& vec3)
{
//    lastPosition = paperPlaneNode->getPosition();
    paperPlaneNode->translate(vec3);
    height += vec3.y;
}
void PaperPlane::scale(const Vector3& vec3)
{
    paperPlaneNode->scale(vec3);
}

void PaperPlane::roll(const Radian& angle, Node::TransformSpace relativeTo)
{
    paperPlaneNode->roll(angle, relativeTo);
}

void PaperPlane::pitch(const Radian& angle, Node::TransformSpace relativeTo)
{
    paperPlaneNode->pitch(angle, relativeTo);
}

void PaperPlane::yaw(const Radian& angle, Node::TransformSpace relativeTo)
{
    paperPlaneNode->yaw(angle, relativeTo);
}

void PaperPlane::setPosition(const Vector3& vec)
{
//    lastPosition = paperPlaneNode->getPosition();
    paperPlaneNode->setPosition(vec);
    height = vec.y;
}

const Vector3& PaperPlane::getPosition()
{
    return paperPlaneNode->getPosition();
}

bool PaperPlane::isWindBlowing()
{
    _isWindBlowing = [windBlowAudioPlayer isPlaying]==YES ? true:false;
    if (!_isWindBlowing)
    {
        stopWindBlow();
    }
     return _isWindBlowing;
}

void PaperPlane::windBlow()
{
    // to be continued
    if (!paperPlaneAniSta)
    {
        paperPlaneAniSta = paperPlaneEntity->getAnimationState("WindBlow");
    }
    
    paperPlaneAniSta->setEnabled(true);
    paperPlaneAniSta->setLoop(true);
    
    [windBlowAudioPlayer play];
    windBlowAudioPlayer.numberOfLoops = 2;
    _isWindBlowing = true;
}

void PaperPlane::stopWindBlow()
{
    if (paperPlaneAniSta)
    {
        [windBlowAudioPlayer stop];
        paperPlaneAniSta->setEnabled(false);
    }
    
    _isWindBlowing = false;
    
}
