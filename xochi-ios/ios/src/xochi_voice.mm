#include "xochi_voice.h"
#include "core/config/engine.h"
#include "core/object/message_queue.h"
#import "XochiVoice-Swift.h"
static XochiVoice *instance = nullptr;
void XochiVoice::_bind_methods() {
    ClassDB::bind_method(D_METHOD("supported"), &XochiVoice::supported);
    ClassDB::bind_method(D_METHOD("begin_listening", "locale", "checkpoint", "attempt", "session"), &XochiVoice::begin_listening);
    ClassDB::bind_method(D_METHOD("stop_listening"), &XochiVoice::stop_listening);
    ClassDB::bind_method(D_METHOD("deliver_cheer", "checkpoint", "attempt", "session"), &XochiVoice::deliver_cheer);
    ClassDB::bind_method(D_METHOD("deliver_status", "state", "message", "checkpoint", "attempt", "session"), &XochiVoice::deliver_status);
    ADD_SIGNAL(MethodInfo("cheer", PropertyInfo(Variant::INT, "checkpoint"), PropertyInfo(Variant::INT, "attempt"), PropertyInfo(Variant::INT, "session")));
    ADD_SIGNAL(MethodInfo("status", PropertyInfo(Variant::INT, "state"), PropertyInfo(Variant::STRING, "message"), PropertyInfo(Variant::INT, "checkpoint"), PropertyInfo(Variant::INT, "attempt"), PropertyInfo(Variant::INT, "session")));
}
XochiVoice::XochiVoice() {
    [XochiVoiceService shared].onCheer = ^(NSInteger checkpoint, NSInteger attempt, NSInteger session) {
        if (instance) instance->call_deferred("deliver_cheer", int(checkpoint), int(attempt), int(session));
    };
    [XochiVoiceService shared].onStatus = ^(NSInteger state, NSString *message, NSInteger checkpoint, NSInteger attempt, NSInteger session) {
        if (instance) instance->call_deferred("deliver_status", int(state), String::utf8([message UTF8String]), int(checkpoint), int(attempt), int(session));
    };
}
XochiVoice::~XochiVoice() { [[XochiVoiceService shared] stopListening]; [XochiVoiceService shared].onCheer = nil; [XochiVoiceService shared].onStatus = nil; }
bool XochiVoice::supported() { return [[XochiVoiceService shared] supported]; }
void XochiVoice::begin_listening(const String &locale, int checkpoint, int attempt, int session) {
    NSString *language = [NSString stringWithUTF8String:locale.utf8().get_data()];
    dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] beginListening:language checkpoint:checkpoint attempt:attempt session:session]; });
}
void XochiVoice::stop_listening() { dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] stopListening]; }); }
void XochiVoice::deliver_cheer(int checkpoint, int attempt, int session) { emit_signal("cheer", checkpoint, attempt, session); }
void XochiVoice::deliver_status(int state, const String &message, int checkpoint, int attempt, int session) { emit_signal("status", state, message, checkpoint, attempt, session); }
void initialize_xochi_voice() { ClassDB::register_class<XochiVoice>(); instance = memnew(XochiVoice); Engine::get_singleton()->add_singleton(Engine::Singleton("XochiVoice", instance)); }
void deinitialize_xochi_voice() { if (instance) { Engine::get_singleton()->remove_singleton("XochiVoice"); memdelete(instance); instance = nullptr; } }
