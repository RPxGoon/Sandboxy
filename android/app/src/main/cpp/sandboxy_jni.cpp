#include <jni.h>
#include <string>
#include "sandboxy_engine.h"

extern "C" {

JNIEXPORT void JNICALL
Java_org_sandboxy_SandboxyActivity_startGame(JNIEnv* env, jobject activity) {
    // Initialize the engine
    SandboxyEngine::init();
    
    // Start main game loop
    SandboxyEngine::run();
}

} // extern "C"