//|||||||||||||||||||||||||||||||||||||||||||||||

#ifndef OGRE_DEMO_H
#define OGRE_DEMO_H

//|||||||||||||||||||||||||||||||||||||||||||||||

#include "OgreFramework.h"
#import "OgreAudioPlayer.h"
#include "PaperPlane.h"
#include "OgreMaxScene.hpp"

using namespace Ogre;

//|||||||||||||||||||||||||||||||||||||||||||||||

enum COLOUR
{
    NIL        = 0x000,
    RED        = 0x100,
    GREEN      = 0x010,
    BLUE       = 0x001,
    RED_GREEN  = 0x110,
    RED_BLUE   = 0x101,
    GREEN_BLUE = 0x011
};

//class DemoApp : public OIS::KeyListener, public OIS::MouseListener, public FrameListener
class DemoApp : public OIS::KeyListener, public OIS::MouseListener
{
public:
	DemoApp();
	~DemoApp();
    
	void startDemo();

    
	bool keyPressed(const OIS::KeyEvent &keyEventRef);
	bool keyReleased(const OIS::KeyEvent &keyEventRef);
    bool mouseMoved(const OIS::MouseEvent &evt);
    bool mousePressed(const OIS::MouseEvent &evt, OIS::MouseButtonID id);
    bool mouseReleased(const OIS::MouseEvent &evt, OIS::MouseButtonID id);
    
    void update();
    void unbufferedInput();
    bool collidesTest(float distance);  //碰撞检测
    
    OgreAudioPlayer*            m_pAudioPlayer;
    PaperPlane*                 paperPlane;
    OgreMax::OgreMaxScene*      maxScene;
    SceneNode*                  buildingsNode;
    
private:
    void setupDemoScene();
	void runDemo();
    bool initializeRTShaderSystem(Ogre::SceneManager* sceneMgr);
    void finalizeRTShaderSystem();
    
    void createLight();
    void createCamera();
    void createViewport();
    
    bool                        gameStart;
    bool                        gameEnd;
    unsigned int                count;
    unsigned int                paperPlaneColour;
    SceneNode*                  lastShowSN;
    Ray                         updateRay;
    RaySceneQuery*              mRaySceneQuery;
    Vector3                     lastPosition;
    float                       collideDistance;
    AnimationState *            paperPlaneAniSta;
	bool					    m_bShutdown;
#ifdef USE_RTSHADER_SYSTEM
    Ogre::RTShader::ShaderGenerator*			mShaderGenerator;			// The Shader generator instance.
    ShaderGeneratorTechniqueResolverListener*	mMaterialMgrListener;		// Shader generator material manager listener.	
#endif // USE_RTSHADER_SYSTEM

};

//|||||||||||||||||||||||||||||||||||||||||||||||

#ifdef USE_RTSHADER_SYSTEM
#include "OgreRTShaderSystem.h"

/** This class demonstrates basic usage of the RTShader system.
 It sub class the material manager listener class and when a target scheme callback
 is invoked with the shader generator scheme it tries to create an equivalent shader
 based technique based on the default technique of the given material.
 */
class ShaderGeneratorTechniqueResolverListener : public Ogre::MaterialManager::Listener
{
public:
    
	ShaderGeneratorTechniqueResolverListener(Ogre::RTShader::ShaderGenerator* pShaderGenerator)
	{
		mShaderGenerator = pShaderGenerator;
	}
    
	/** This is the hook point where shader based technique will be created.
     It will be called whenever the material manager won't find appropriate technique
     that satisfy the target scheme name. If the scheme name is out target RT Shader System
     scheme name we will try to create shader generated technique for it.
     */
	virtual Ogre::Technique* handleSchemeNotFound(unsigned short schemeIndex,
                                                  const Ogre::String& schemeName, Ogre::Material* originalMaterial, unsigned short lodIndex,
                                                  const Ogre::Renderable* rend)
	{
		Ogre::Technique* generatedTech = NULL;
        
		// Case this is the default shader generator scheme.
		if (schemeName == Ogre::RTShader::ShaderGenerator::DEFAULT_SCHEME_NAME)
		{
			bool techniqueCreated;
            
			// Create shader generated technique for this material.
			techniqueCreated = mShaderGenerator->createShaderBasedTechnique(
                                                                            originalMaterial->getName(),
                                                                            Ogre::MaterialManager::DEFAULT_SCHEME_NAME,
                                                                            schemeName);
            
			// Case technique registration succeeded.
			if (techniqueCreated)
			{
				// Force creating the shaders for the generated technique.
				mShaderGenerator->validateMaterial(schemeName, originalMaterial->getName());
				
				// Grab the generated technique.
				Ogre::Material::TechniqueIterator itTech = originalMaterial->getTechniqueIterator();
                
				while (itTech.hasMoreElements())
				{
					Ogre::Technique* curTech = itTech.getNext();
                    
					if (curTech->getSchemeName() == schemeName)
					{
						generatedTech = curTech;
						break;
					}
				}
			}
		}
        
		return generatedTech;
	}
    
protected:
	Ogre::RTShader::ShaderGenerator*	mShaderGenerator;			// The shader generator instance.
};
#endif
//|||||||||||||||||||||||||||||||||||||||||||||||

#endif 

//|||||||||||||||||||||||||||||||||||||||||||||||
