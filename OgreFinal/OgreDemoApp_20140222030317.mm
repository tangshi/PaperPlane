#include "OgreDemoApp.h"
using namespace Ogre;

#define ENTITY_MASK 0x01



DemoApp::DemoApp()
{
	paperPlane = new PaperPlane();
    
    maxScene = new OgreMax::OgreMaxScene();
    
    mRaySceneQuery = 0;
    lastPosition = Vector3::ZERO;
    collideDistance = 1.0;
    paperPlaneColour = 0x000;
    count = 0;
    gameStart = false;
    gameEnd = false;
    
    NSString *soundPath=[[NSBundle mainBundle] pathForResource:@"bgAudio" ofType:@"mp3"];
    NSURL *soundUrl=[[NSURL alloc] initFileURLWithPath:soundPath];
    m_pAudioPlayer = [[OgreAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    [m_pAudioPlayer prepareToPlay];
    [soundUrl release];

}

//|||||||||||||||||||||||||||||||||||||||||||||||

DemoApp::~DemoApp()
{
#ifdef USE_RTSHADER_SYSTEM
    mShaderGenerator->removeSceneManager(OgreFramework::getSingletonPtr()->m_pSceneMgr);
    
    finalizeRTShaderSystem();
#endif

    if (m_pAudioPlayer) {
        [m_pAudioPlayer release];
    }
    if (paperPlane) {
        delete paperPlane;
        paperPlane = NULL;
    }
    if (maxScene) {
        delete maxScene;
        maxScene = NULL;
    }
    delete OgreFramework::getSingletonPtr();
}

//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::startDemo()
{
	new OgreFramework();
//	if(!OgreFramework::getSingletonPtr()->initOgre("DemoApp v1.0", this, 0))
    if(!OgreFramework::getSingletonPtr()->initOgre("paper plane", this, this))
		return;
    
	m_bShutdown = false;
    
	OgreFramework::getSingletonPtr()->m_pLog->logMessage("Demo initialized!");
	
#ifdef USE_RTSHADER_SYSTEM
    initializeRTShaderSystem(OgreFramework::getSingletonPtr()->m_pSceneMgr);
    Ogre::MaterialPtr baseWhite = Ogre::MaterialManager::getSingleton().getByName("BaseWhite", Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME);
    baseWhite->setLightingEnabled(false);
    mShaderGenerator->createShaderBasedTechnique(
                                                 "BaseWhite",
                                                 Ogre::MaterialManager::DEFAULT_SCHEME_NAME,
                                                 Ogre::RTShader::ShaderGenerator::DEFAULT_SCHEME_NAME);
    mShaderGenerator->validateMaterial(Ogre::RTShader::ShaderGenerator::DEFAULT_SCHEME_NAME,
                                       "BaseWhite");
    baseWhite->getTechnique(0)->getPass(0)->setVertexProgram(
                                                             baseWhite->getTechnique(1)->getPass(0)->getVertexProgram()->getName());
    baseWhite->getTechnique(0)->getPass(0)->setFragmentProgram(
                                                               baseWhite->getTechnique(1)->getPass(0)->getFragmentProgram()->getName());
    
    // creates shaders for base material BaseWhiteNoLighting using the RTSS
    mShaderGenerator->createShaderBasedTechnique(
                                                 "BaseWhiteNoLighting",
                                                 Ogre::MaterialManager::DEFAULT_SCHEME_NAME,
                                                 Ogre::RTShader::ShaderGenerator::DEFAULT_SCHEME_NAME);
    mShaderGenerator->validateMaterial(Ogre::RTShader::ShaderGenerator::DEFAULT_SCHEME_NAME,
                                       "BaseWhiteNoLighting");
    Ogre::MaterialPtr baseWhiteNoLighting = Ogre::MaterialManager::getSingleton().getByName("BaseWhiteNoLighting", Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME);
    baseWhiteNoLighting->getTechnique(0)->getPass(0)->setVertexProgram(
                                                                       baseWhiteNoLighting->getTechnique(1)->getPass(0)->getVertexProgram()->getName());
    baseWhiteNoLighting->getTechnique(0)->getPass(0)->setFragmentProgram(
                                                                         baseWhiteNoLighting->getTechnique(1)->getPass(0)->getFragmentProgram()->getName());
#endif
    
	setupDemoScene();
#if !((OGRE_PLATFORM == OGRE_PLATFORM_APPLE) && __LP64__)
	runDemo();
#endif
}

//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::setupDemoScene()
{
//	OgreFramework::getSingletonPtr()->m_pSceneMgr->setSkyBox(true, "Examples/StormySkyBox");
    OgreFramework::getSingletonPtr()->m_pSceneMgr->setSkyDome(true, "Examples/CloudySky");
    
//    createCamera();
//    createViewport();
    createLight();
    

/*-----------------创建一个平面-----------------*/
    //1. 定义一个平面
    Plane ground(Vector3::UNIT_Y, -2);
    //2. 从定义的平面创建平面模型
    MeshManager::getSingleton().createPlane("ground", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, ground, 500, 500, 20, 20, true, 1, 5, 5, Vector3::UNIT_Z);
    //3. 将平面模型绑定到场景节点
    Entity *entGround = OgreFramework::getSingletonPtr()->m_pSceneMgr->createEntity("entGround", "ground"); //创建地面实体
    entGround->setMaterialName("lambertWhite");
    OgreFramework::getSingletonPtr()->m_pSceneMgr->getRootSceneNode()->createChildSceneNode("ground")->attachObject(entGround);
/*--------------------------------------------*/
    


    //载入场景文件
    maxScene->Load("Buildings_5.scene",
                   OgreFramework::getSingletonPtr()->m_pRenderWnd,
                   OgreMax::OgreMaxScene::NO_OPTIONS,
                   OgreFramework::getSingletonPtr()->m_pSceneMgr,
                   OgreFramework::getSingletonPtr()->m_pSceneMgr->getRootSceneNode());

    if (OgreFramework::getSingletonPtr()->m_pSceneMgr->hasSceneNode("buildings")) {
        buildingsNode = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("buildings");
        buildingsNode->scale(2, 2, 2);
    }

    int cnt = buildingsNode->numChildren();
    for (int i=0; i<cnt; ++i) {
        if (SceneNode* sn = (SceneNode*)buildingsNode->getChild(i)) {
//            sn->showBoundingBox(true); //显示包围盒
            sn->getAttachedObject(0)->setQueryFlags(ENTITY_MASK); //设置掩码
        }
        else
        {
            printf("can not get child[%d]\n", i);
        }
    }
    
    
    SceneNode* m_pCubeNode;
    Entity* m_pCubeEntity;

    if (OgreFramework::getSingletonPtr()->m_pSceneMgr->hasSceneNode("pPlane1"))
    {
        SceneNode* plane = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("pPlane1");
        plane->scale(Vector3(5, 1, 5));
    }
    
    if (OgreFramework::getSingletonPtr()->m_pSceneMgr->hasSceneNode("paperPlane"))
    {
        m_pCubeNode = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("paperPlane");
        paperPlane->setPaperPlaneNode(m_pCubeNode);
        m_pCubeNode->scale(Vector3(10,10,10));
    }
    else
        printf("has no scene node named paperPlane.\n");
    
    
    if (OgreFramework::getSingletonPtr()->m_pSceneMgr->hasEntity("paperPlane"))
    {
        m_pCubeEntity = OgreFramework::getSingletonPtr()->m_pSceneMgr->getEntity("paperPlane");
        paperPlane->setPaperPlaneEntity(m_pCubeEntity);
    }
    else {
        printf("has no entity named paperPlane.\n");
    }
    //paperPlane的相关参数设置
    paperPlane->setSpeed(0.05);
    paperPlane->setHeight(paperPlane->getPaperPlaneNode()->getPosition().y);
    lastPosition = m_pCubeNode->getPosition();
/*----------------------------------------*/
    
/*--------------------摄像机设置---------------------*/
    SceneNode* cameraNode = m_pCubeNode->getParentSceneNode()->createChildSceneNode("camera");
    cameraNode->attachObject(OgreFramework::getSingletonPtr()->m_pCamera);
    
    cameraNode->setPosition(Vector3(0, 0, 0));
    cameraNode->yaw(Degree(-90));
    OgreFramework::getSingletonPtr()->m_pCamera->setAutoTracking(true, m_pCubeNode);
    
/*-------------------------------------------*/
    
//    OgreFramework::getSingletonPtr()->m_pSceneMgr->setFog(FOG_LINEAR, ColourValue(0.83, 0.83, 0.83),0.001, 1, 1000);

    OgreFramework::getSingletonPtr()->m_pSceneMgr->setShadowTechnique(SHADOWTYPE_STENCIL_ADDITIVE);
    OgreFramework::getSingletonPtr()->m_pSceneMgr->setShadowColour(ColourValue(0, 0, 0));

    
    OgreFramework::getSingletonPtr()->m_pTrayMgr->hideCursor(); //隐藏鼠标
    OgreFramework::getSingletonPtr()->m_pTrayMgr->hideLogo(); //隐藏Logo
    OgreFramework::getSingletonPtr()->m_pTrayMgr->hideFrameStats(); //隐藏帧信息
}

//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::createLight()
{
    OgreFramework::getSingletonPtr()->m_pSceneMgr->setAmbientLight(ColourValue(1, 1, 1)); //设置环境光
    
    Light *directionalLight = OgreFramework::getSingletonPtr()->m_pSceneMgr->createLight("directionalLight");
    directionalLight->setType(Light::LT_DIRECTIONAL);
    directionalLight->setDirection(Vector3(-10, -10, 0));
    directionalLight->setSpecularColour(ColourValue(1, 1, 1));  //设置镜面反射光
    directionalLight->setDiffuseColour(ColourValue(1,1,1)); //设置漫反射光

}

//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::createCamera()
{
//  相机的相关初始化操作
    //  m_pCamera = m_pSceneMgr->createCamera("Camera");
    //	m_pCamera->setPosition(Vector3(0, 60, 60));
    //	m_pCamera->lookAt(Vector3(0, 0, 0));
    //	m_pCamera->setNearClipDistance(1);
    
    Camera *cam_2 = OgreFramework::getSingletonPtr()->m_pSceneMgr->createCamera("Camera_2");
    cam_2->setPosition(Vector3(0, 280, 0));
    cam_2->lookAt(Vector3(0, 0, 0));
    cam_2->setNearClipDistance(1);
    
}

//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::createViewport()
{
    
//    画中画视口设置
    Camera *cam_2 = OgreFramework::getSingletonPtr()->m_pSceneMgr->getCamera("Camera_2");
    Viewport *smallViewport = OgreFramework::getSingletonPtr()->m_pRenderWnd->addViewport(cam_2, 1, 0.75, 0.05, 0.20, 0.20);
    smallViewport->setBackgroundColour(ColourValue::Black);
    smallViewport->setOverlaysEnabled(false);
    cam_2->setAspectRatio(Real(smallViewport->getActualWidth()) / Real(smallViewport->getActualHeight() ) );
    smallViewport->setCamera(cam_2);
    
}

//|||||||||||||||||||||||||||||||||||||||||||||||

bool DemoApp::keyPressed(const OIS::KeyEvent &keyEventRef)
{
#if !defined(OGRE_IS_IOS)
	OgreFramework::getSingletonPtr()->keyPressed(keyEventRef);
    
    switch (keyEventRef.key) {


        case OIS::KC_SPACE:
        {
            gameStart = true;
        }
        case OIS::KC_F:
        {
            paperPlane->scale(Vector3(0.10, 0.10, 0.10));
            break;
        }
        case OIS::KC_G:
        {
            paperPlane->scale(Vector3(10, 10, 10));
      
            break;
        }
        case OIS::KC_H:
        {
            lastPosition = paperPlane->getPosition();
            float hight = paperPlane->getHeight() + 2.0;
            paperPlane->getPaperPlaneNode()->getParentSceneNode()->translate(Vector3(0, 2, 0));
            break;
        }
        
        case OIS::KC_J:
        {
            collideDistance += 0.1;
            printf("collideDistance: %f\n", collideDistance);
            break;
        }
        
        case OIS::KC_K:
        {
            collideDistance -= 0.1;
            printf("collideDistance: %f\n", collideDistance);
            break;
        }
            

        default:
            break;
    }
    
    
    
#endif
	return true;
}

//|||||||||||||||||||||||||||||||||||||||||||||||

bool DemoApp::keyReleased(const OIS::KeyEvent &keyEventRef)
{
#if !defined(OGRE_IS_IOS)
	OgreFramework::getSingletonPtr()->keyReleased(keyEventRef);
#endif
    
	return true;
}

//|||||||||||||||||||||||||||||||||||||||||||||||

bool DemoApp::mouseMoved(const OIS::MouseEvent &evt)
{
//	m_pCamera->yaw(Degree(evt.state.X.rel * -0.1f));
//	m_pCamera->pitch(Degree(evt.state.Y.rel * -0.1f));
	return true;
}

//|||||||||||||||||||||||||||||||||||||||||||||||

bool DemoApp::mousePressed(const OIS::MouseEvent &evt, OIS::MouseButtonID id)
{
    if (count <= 1100)
        return false;
    
    switch (id) {
        case OIS::MB_Left:  //鼠标拾取建筑物
        {
            // do something
            updateRay = OgreFramework::getSingletonPtr()->m_pCamera->getCameraToViewportRay(evt.state.X.abs/(float)evt.state.width, evt.state.Y.abs/(float)evt.state.height);
            if (mRaySceneQuery == 0)
            {
                mRaySceneQuery = OgreFramework::getSingletonPtr()->m_pSceneMgr->createRayQuery(Ogre::Ray());
            }
            mRaySceneQuery->setRay(updateRay);
            mRaySceneQuery->setSortByDistance(true);
            mRaySceneQuery->setQueryMask(ENTITY_MASK);
            RaySceneQueryResult& result = mRaySceneQuery->execute(); //执行查询操作
            if (result.size() <= 0) {
                return false;
            }
            RaySceneQueryResult::iterator itr;
            for (itr=result.begin(); itr<result.end(); ++itr) {
                if ((itr->movable->getMovableType() == "Entity") )
                {
                    SceneNode* sn = itr->movable->getParentSceneNode();
                    if (lastShowSN != sn)
                    {
                        if (lastShowSN != NULL) {
                            lastShowSN->showBoundingBox(false);
                        }
                        lastShowSN = sn;
                        sn->showBoundingBox(true);
                        printf("%s is picked!\n", itr->movable->getName().c_str());
                        Entity* ent = (Entity*)itr->movable;
                        unsigned int flag = 0x000;
                        if (ent->getName() == "redBuilding") {
                            flag = 0x100;
                        }
                        if (ent->getName() == "greenBuilding") {
                            flag = 0x010;
                        }
                        if (ent->getName() == "blueBuilding") {
                            flag = 0x001;
                        }
                        std::string materialName = "unchanged";
                        paperPlaneColour = paperPlaneColour | flag;
                        switch (paperPlaneColour) { //根据结果为纸飞机设置材质
                            case 0x100:
                            {
                                materialName = "lambertRed";
                                break;
                            }
                            case 0x010:
                            {
                                materialName = "lambertGreen";
                                break;
                            }
                            case 0x001:
                            {
                                materialName = "lambertBlue";
                                break;
                            }
                            case 0x110:
                            {
                                materialName = "lambertRedAndGreen";
                                break;
                            }
                            case 0x101:
                            {
                                materialName = "lambertRedAndBlue";
                                break;
                            }
                            case 0x011:
                            {
                                materialName = "lambertGreenAndBlue";
                                break;
                            }
                            case 0x111:
                            {
                                materialName = "lambertWhite";
                                
                                break;
                            }
                            default:
                                break;
                        }
                        if (materialName != "unchanged") {
                            paperPlane->getPaperPlaneEntity()->setMaterialName(materialName);
                            if (materialName == "lambertWhite") {
                                gameEnd = true;
                                count = 0;
                                OgreFramework::getSingletonPtr()->m_pTrayMgr->hideCursor(); //隐藏鼠标
                            }
                        }
                        break;  //拾取成功后跳出
                    }
                }
                    
            }
            break;
        }
        
        default:
            break;
            
    }
    return true;
}

//|||||||||||||||||||||||||||||||||||||||||||||||

bool DemoApp::mouseReleased(const OIS::MouseEvent &evt, OIS::MouseButtonID id)
{
	return true;
}

//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::update()
{
    if (!gameStart) {
        return;
    }
    
    if (!gameEnd) {

        (count>10000) ? (count=10000):(++count);
        if (count <= 500) {
            OgreFramework::getSingletonPtr()->m_pCamera->moveRelative(Vector3(0.1, 0, 0.1));
        }
        else if (count <= 700) {
            OgreFramework::getSingletonPtr()->m_pCamera->moveRelative(Vector3(-0.05, 0, -0.05));
        }
        else if (count <= 900) {
            OgreFramework::getSingletonPtr()->m_pCamera->moveRelative(Vector3(-0.1, 0, -0.5));
        }
        else if (count <= 1000) {
            OgreFramework::getSingletonPtr()->m_pCamera->moveRelative(Vector3(0, 0, -0.05));
        }
        else {
            OgreFramework::getSingletonPtr()->m_pTrayMgr->showCursor(); //打开鼠标
            OgreFramework::getSingletonPtr()->m_pTrayMgr->refreshCursor(); //刷新鼠标位置
            lastPosition = paperPlane->getPosition(); //做非缓冲输入检测前，获得纸飞机上次的位置
            //非缓冲输入检测
            unbufferedInput();
            
            //碰撞检测
            collidesTest(collideDistance);
            //刮风动画
            if (paperPlane->isWindBlowing())
            {
                if (paperPlaneAniSta == NULL)
                {
                    paperPlane->paperPlaneAniSta = maxScene->GetAnimationState("WindBlow");
                    paperPlaneAniSta = paperPlane->paperPlaneAniSta;
                }
                
                paperPlaneAniSta->addTime(paperPlaneAniSta->getLength() / 60);
            }
            
        }
    }
    
    else if (gameStart&gameEnd) {
        // game end
        count++;
        if (count <= 1000) {
            OgreFramework::getSingletonPtr()->m_pCamera->moveRelative(Vector3(0.1, 0, 0.1));
            buildingsNode->translate(Vector3(0, -0.055, 0));
            SceneNode* plane = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("paperPlane");
            plane->scale(Vector3(1.001, 1.001, 1.001));
            unbufferedInput();
        }
        else {
            OgreFramework::getSingletonPtr()->setOgreToBeShutDown(true);
        }
    }
    
}


//|||||||||||||||||||||||||||||||||||||||||||||||


//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::unbufferedInput()
{
    OgreFramework::getSingletonPtr()->getInput();


    float speed = paperPlane->getSpeed();
    SceneNode* sn = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("main");
    if (OgreFramework::getSingletonPtr()->m_pKeyboard->isKeyDown(OIS::KC_UP))
    {
        sn->translate(Vector3(speed, 0, 0), Node::TS_LOCAL);
    }
    if (OgreFramework::getSingletonPtr()->m_pKeyboard->isKeyDown(OIS::KC_DOWN))
    {
        sn->translate(Vector3(-speed, 0, 0), Node::TS_LOCAL);
    }
    
    if (OgreFramework::getSingletonPtr()->m_pKeyboard->isKeyDown(OIS::KC_LEFT))
    {
        sn->yaw(Degree(speed*5));
    }
    
    if (OgreFramework::getSingletonPtr()->m_pKeyboard->isKeyDown(OIS::KC_RIGHT))
    {
        sn->yaw(Degree(-speed*5));
    }

    if (OgreFramework::getSingletonPtr()->m_pKeyboard->isKeyDown(OIS::KC_G)) {
        SceneNode* plane = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("paperPlane");
        plane->scale(Vector3(10, 10, 10));
    }
    
    if (OgreFramework::getSingletonPtr()->m_pKeyboard->isKeyDown(OIS::KC_L)) {
        SceneNode* plane = OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("paperPlane");
        plane->scale(Vector3(0.10, 0.10, 0.10));
    }
}

//|||||||||||||||||||||||||||||||||||||||||||||||


bool DemoApp::collidesTest(float distance)
{
//    if (mCollisionTools == 0) {
//        mCollisionTools = new MOC::CollisionTools(OgreFramework::getSingletonPtr()->m_pSceneMgr);
//    }
//    Vector3 position = paperPlane->getPosition();
//    
//    printf("lastPosition: %f, %f, %f\n", lastPosition.x, lastPosition.y, lastPosition.z);
//    printf("position: %f, %f, %f\n", position.x, position.y, position.z);
//    
//    updateRay.setOrigin(lastPosition);  //将上一次的位置设为射线原点
//    Vector3 dir = position - lastPosition;
//    float len = dir.length();
//    dir.x = dir.x / len;
//    dir.y = dir.y / len;
//    dir.z = dir.z / len;
//    updateRay.setDirection(dir); //射线方向为前进方向，即当前位置向量 减 上次位置向量
//    Vector3 result = Vector3::ZERO;
//    Entity* target;
//    float closest_distance;
//    if ( mCollisionTools->raycast(updateRay, result, target, closest_distance) )
//    {
//        if (closest_distance <= distance) {
//            paperPlane->getPaperPlaneNode()->getParentSceneNode()->setPosition(lastPosition);
//            return true;
//        }
//        
//    }
//    
//    return false;
    

////球体查询碰撞检测
//    SphereSceneQuery* pQuery = OgreFramework::getSingletonPtr()->m_pSceneMgr->createSphereQuery(Sphere(paperPlane->getPosition(), distance));
//    SceneQueryResult Qresult = pQuery->execute();
//    SceneQueryResultMovableList::iterator iter;
//    for (iter = Qresult.movables.begin(); iter != Qresult.movables.end(); ++iter) {
//        
//        MovableObject* pObject = static_cast<MovableObject*>(*iter);
//        
//        if (pObject) {
//            if (pObject->getMovableType() == "Entity") {
//                Entity* ent = static_cast<Entity*>(pObject);
//                if ( ent->getName() != "paperPlane" ){
//                    ent->getParentSceneNode()->showBoundingBox(true);
//                    printf("collide with %s\n", ent->getName().c_str());
//                    paperPlane->setPosition(lastPosition);
//                    break;
//                }
//            }
//        }
//    }
//    
//    if (iter == Qresult.movables.end()) {
//        return false;
//    }
//    
//    return true;
 
    Vector3 position = paperPlane->getPosition();
//    printf("lastPosition: %f, %f, %f\n", lastPosition.x, lastPosition.y, lastPosition.z);
//    printf("position: %f, %f, %f\n", position.x, position.y, position.z);
    updateRay.setOrigin(lastPosition);  //将上一次的位置设为射线原点
    Vector3 dir = position - lastPosition;
//    float len = dir.length();
//    dir.x = dir.x / len;
//    dir.y = dir.y / len;
//    dir.z = dir.z / len;
    updateRay.setDirection(dir); //射线方向为前进方向，即当前位置向量 减 上次位置向量
    if (mRaySceneQuery == 0)
    {
        mRaySceneQuery = OgreFramework::getSingletonPtr()->m_pSceneMgr->createRayQuery(Ogre::Ray());
    }
    
    if (lastPosition != position) {
        updateRay.setOrigin(lastPosition);  //将上一次的位置设为射线原点
        updateRay.setDirection(dir);
        mRaySceneQuery->setRay(updateRay);
        mRaySceneQuery->setSortByDistance(true);  //查询结果按距离排序
        mRaySceneQuery->setQueryMask(ENTITY_MASK);
        RaySceneQueryResult& result = mRaySceneQuery->execute(); //执行查询操作
        if (result.size() <= 0) {
            return false;
        }
        
        RaySceneQueryResult::iterator itr;
        for (itr=result.begin(); itr<result.end(); ++itr) {
            if ((itr->movable->getMovableType() == "Entity") && (itr->movable->getName() != "paperPlane")) {
                Vector3 movPos = itr->movable->getParentSceneNode()->getPosition();
//                printf("movPos: %f, %f, %f\n", movPos.x, movPos.y, movPos.z);
                movPos.y = 0;
                position.y = 0;
                
                if ((movPos-position).normalise() < distance)
                {
                    OgreFramework::getSingletonPtr()->m_pSceneMgr->getSceneNode("main")->setPosition(lastPosition);
                    printf("collide with %s!\n", itr->movable->getName().c_str());
                    return true;
                }
                    
            }
        }
    }
    
    return false;
}




// bool DemoApp::collidesTest(float distance)
// {
//     Vector3 position = paperPlane->getPosition();
//     if (mRaySceneQuery == 0) //若mRaySceneQuery未初始化，则初始化
//     {
//         mRaySceneQuery = OgreFramework::getSingletonPtr()->m_pSceneMgr->createRayQuery(Ogre::Ray());
//     }
//     
//     if (position != lastPosition) //若位置发生改变，则检测碰撞，否则取消检测退出
//     {
//         updateRay.setOrigin(lastPosition);  //将上一次的位置设为射线原点
//         updateRay.setDirection( position - lastPosition); //射线方向为前进方向，即当前位置向量 减 上次位置向量
//         mRaySceneQuery->setRay(updateRay);
//         mRaySceneQuery->setSortByDistance(true);  //查询结果按距离排序
//         RaySceneQueryResult& result = mRaySceneQuery->execute(); //执行查询操作
//         if (result.size() <= 0) {
//             return false;  //查询失败则退出
//         }
//     
//         RaySceneQueryResult::iterator itr;
//         for ( itr = result.begin(); itr < result.end(); itr++)
//         {
//             if ((itr->movable->getMovableType() == "Entity") && (itr->movable->getName() != "paperPlane") )
//             {
//                 Vector3 pos = itr->movable->getParentSceneNode()->getPosition();
//                 itr->movable->getParentSceneNode()->showBoundingBox(true);
//                 printf("%s pos: %f, %f, %f\n", itr->movable->getName().c_str(),pos.x, pos.y, pos.z);
//                 float dis = pos.distance(position);
//                 printf("dis: %f\n", dis);
//                 if ( dis <  distance) {
//                     paperPlane->setPosition(lastPosition);
//                     return true;
//                 }
//                 break;
//             }
//             else continue;
//        }
//     }
//     
//     return false;
// }


//|||||||||||||||||||||||||||||||||||||||||||||||

void DemoApp::runDemo()
{
	OgreFramework::getSingletonPtr()->m_pLog->logMessage("Start main loop...");
	
	double timeSinceLastFrame = 0;
	double startTime = 0;
    
    OgreFramework::getSingletonPtr()->m_pRenderWnd->resetStatistics();
    
#if (!defined(OGRE_IS_IOS)) && !((OGRE_PLATFORM == OGRE_PLATFORM_APPLE) && __LP64__)
	while(!m_bShutdown && !OgreFramework::getSingletonPtr()->isOgreToBeShutDown())
	{
		if(OgreFramework::getSingletonPtr()->m_pRenderWnd->isClosed())
            m_bShutdown = true;
        
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32 || OGRE_PLATFORM == OGRE_PLATFORM_LINUX || OGRE_PLATFORM == OGRE_PLATFORM_APPLE
		Ogre::WindowEventUtilities::messagePump();
#endif
		if(OgreFramework::getSingletonPtr()->m_pRenderWnd->isActive())
		{
			startTime = OgreFramework::getSingletonPtr()->m_pTimer->getMillisecondsCPU();
            
#if !OGRE_IS_IOS
			OgreFramework::getSingletonPtr()->m_pKeyboard->capture();
#endif
			OgreFramework::getSingletonPtr()->m_pMouse->capture();
            
			OgreFramework::getSingletonPtr()->updateOgre(timeSinceLastFrame);
			OgreFramework::getSingletonPtr()->m_pRoot->renderOneFrame();
            
			timeSinceLastFrame = OgreFramework::getSingletonPtr()->m_pTimer->getMillisecondsCPU() - startTime;
            
		}
		else
		{
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
            Sleep(1000);
#else
            sleep(1);
#endif
		}
	}
#endif
    
#if !defined(OGRE_IS_IOS)
	OgreFramework::getSingletonPtr()->m_pLog->logMessage("Main loop quit");
	OgreFramework::getSingletonPtr()->m_pLog->logMessage("Shutdown OGRE...");
#endif
}

//|||||||||||||||||||||||||||||||||||||||||||||||

#ifdef USE_RTSHADER_SYSTEM

/*-----------------------------------------------------------------------------
 | Initialize the RT Shader system.
 -----------------------------------------------------------------------------*/
bool DemoApp::initializeRTShaderSystem(Ogre::SceneManager* sceneMgr)
{
    if (Ogre::RTShader::ShaderGenerator::initialize())
    {
        mShaderGenerator = Ogre::RTShader::ShaderGenerator::getSingletonPtr();
        
        mShaderGenerator->addSceneManager(sceneMgr);
        
        // Setup core libraries and shader cache path.
        Ogre::StringVector groupVector = Ogre::ResourceGroupManager::getSingleton().getResourceGroups();
        Ogre::StringVector::iterator itGroup = groupVector.begin();
        Ogre::StringVector::iterator itGroupEnd = groupVector.end();
        Ogre::String shaderCoreLibsPath;
        Ogre::String shaderCachePath;
        
        for (; itGroup != itGroupEnd; ++itGroup)
        {
            Ogre::ResourceGroupManager::LocationList resLocationsList = Ogre::ResourceGroupManager::getSingleton().getResourceLocationList(*itGroup);
            Ogre::ResourceGroupManager::LocationList::iterator it = resLocationsList.begin();
            Ogre::ResourceGroupManager::LocationList::iterator itEnd = resLocationsList.end();
            bool coreLibsFound = false;
            
            // Try to find the location of the core shader lib functions and use it
            // as shader cache path as well - this will reduce the number of generated files
            // when running from different directories.
            for (; it != itEnd; ++it)
            {
                if ((*it)->archive->getName().find("RTShaderLib") != Ogre::String::npos)
                {
                    shaderCoreLibsPath = (*it)->archive->getName() + "/";
                    shaderCachePath = shaderCoreLibsPath;
                    coreLibsFound = true;
                    break;
                }
            }
            // Core libs path found in the current group.
            if (coreLibsFound)
                break;
        }
        
        // Core shader libs not found -> shader generating will fail.
        if (shaderCoreLibsPath.empty())
            return false;
        
        // Create and register the material manager listener.
        mMaterialMgrListener = new ShaderGeneratorTechniqueResolverListener(mShaderGenerator);
        Ogre::MaterialManager::getSingleton().addListener(mMaterialMgrListener);
    }
    
    return true;
}

/*-----------------------------------------------------------------------------
 | Finalize the RT Shader system.
 -----------------------------------------------------------------------------*/
void DemoApp::finalizeRTShaderSystem()
{
    // Restore default scheme.
    Ogre::MaterialManager::getSingleton().setActiveScheme(Ogre::MaterialManager::DEFAULT_SCHEME_NAME);
    
    // Unregister the material manager listener.
    if (mMaterialMgrListener != NULL)
    {
        Ogre::MaterialManager::getSingleton().removeListener(mMaterialMgrListener);
        delete mMaterialMgrListener;
        mMaterialMgrListener = NULL;
    }
    
    // Finalize RTShader system.
    if (mShaderGenerator != NULL)
    {
        Ogre::RTShader::ShaderGenerator::finalize();
        mShaderGenerator = NULL;
    }
}
#endif // USE_RTSHADER_SYSTEM


//bool collide(Ray mRay, Entity *mObject)
//{
//    bool collide = false;
//    Sphere sphere = mObject->getWorldBoundingSphere(); //获取实体的包围球
//    //以包围球建立场景查询，并设置查询掩码
//    SphereSceneQuery *sphereSQ = mSceneMgr->createSphereQuery(sphere, ENTITY_MASK);
//    SceneQueryResult& result = sphereSQ->execute();  //执行并获取查询结果
//    //创建一个迭代器并用第一个查询结果初始化
//    SceneQueryResultMovableList::iterator iter = result.movables.begin();
//
//    if (result.movables.empty()) //若查询结果为空，退出
//    return false;
//    else {
//        for (; iter!=result.movables.end(); iter++) { //遍历查询结果
//            if ((*iter)->getMovableType() == "Entity") {  //我们只关心实体
//                if (mObject->getName()==(*iter)->getName()) {  //排除自己
//                    continue;
//                }
//                else {
//                    collide = true;
//                    //碰撞响应
//                    //……
//                    break; //一般只需要对查询到的第一个碰撞做响应，退出遍历。
//                }
//            }
//        }
//        return collide;
//    }
//}

//bool collide = false;
//SceneNode *sphereNode = mSceneMgr->getSceneNode("sphere"); // 球
//SceneNode *cubeNode = mSceneMgr->getSceneNode("cube");     // 正方体
//Ogre::AxisAlignedBox spBox = sphereNode->_getWorldAABB();  //获得球的AABB包围盒
//Ogre::AxisAlignedBox cuBox = cubeNode->_getWorldAABB();    //获得正方体的AABB包围盒
//
//if (spBox.intersects(cuBox)) { //检测两个包围盒是否相交
//    //相交，作出碰撞响应
//    //……
//    collide = true;
//}
//
//return collide;


//bool collide=false;
//
//AxisAlignedBox AABB = mObject->getWorldBoundingBox(true);  // 获取包围盒
//// 以包围盒建立场景查询
//AxisAlignedBoxSceneQuery *mAABBSceneQuery = mSceneMgr->createAABBQuery(AABB);
//mAABBSceneQuery->setQueryMask(ENTITY_MASK); // 设置查询掩码
//SceneQueryResult& results = mAABBSceneQuery->execute();  // 获取查询结果
//SceneQueryResultMovableList::iterator iter = results.movables.begin();
//
//if(results.movables.empty())
//return false; //若查询结果为空，退出
//else {
//    for(;iter!=results.movables.end();iter++) {
//        if((*iter)->getMovableType()=="Entity") { //我们只关心实体的检测
//            if(mObject->getName()==(*iter)->getName()) //排除自己
//                continue;
//            else {
//                collide=true;
//                //碰撞响应
//                //……
//                break;
//            }
//        }
//    }
//    return collide;
//}


//bool collide = false;
//Sphere sphere = mObject->getWorldBoundingSphere(); //获取实体的包围球
////以包围球建立场景查询，并设置查询掩码
//SphereSceneQuery *sphereSQ = mSceneMgr->createSphereQuery(sphere, ENTITY_MASK);
//SceneQueryResult& result = sphereSQ->execute();  //执行并获取查询结果
////创建一个迭代器并用第一个查询结果初始化
//SceneQueryResultMovableList::iterator iter = result.movables.begin();
//
//if (result.movables.empty()) //若查询结果为空，退出
//return false;
//else {
//    for (; iter!=result.movables.end(); iter++) { //遍历查询结果
//        if (mObject->getName()==(*iter)->getName()) {  //排除自己
//            continue;
//        }
//        else {
//            collide = true;
//            //碰撞响应
//            //……
//            break; //一般只需要对查询到的第一个碰撞做响应，退出遍历。
//        }
//    }
//    return collide;
//}

//bool collide = false;
////以射线建立场景查询并设置查询掩码
//Ogre::RaySceneQuery* RaySQ = mSceneMgr->createRayQuery(mRay, ENTITY_MASK);
//RaySQ->setSortByDistance(true, 2); //将查询结果按距离排序，仅保留2个查询结果
//RaySceneQueryResult& result = RaySQ->execute(); //执行查询并返回结果

//if (result.empty()) { //若查询结果为空，退出
//    return false;
//}
//else {
//    RaySceneQueryResult::iterator itr = result.begin();
//    for (; itr!=result.end(); ++itr) {  //遍历查询结果
//        if (itr->movable->getMovableType() == "Entity") {  //我们只关心实体
//            if (mObject->getName() == itr->movable->getName()) { //排除自己
//                continue;
//            }
//            else {
//                collide = true;
//                //碰撞响应
                //……
//                break;  //一般只需要对查询到的第一个碰撞做响应，退出遍历
//            }
//        }
//    }
//}