#include "xochi_voice.h"
#include "core/config/engine.h"
#include "core/object/message_queue.h"
#import "XochiVoice-Swift.h"
static XochiVoice *instance = nullptr;
void XochiVoice::_bind_methods() {
    ClassDB::bind_method(D_METHOD("supported"), &XochiVoice::supported);
    ClassDB::bind_method(D_METHOD("supported_locale", "locale"), &XochiVoice::supported_locale);
    ClassDB::bind_method(D_METHOD("intelligence_status", "locale"), &XochiVoice::intelligence_status);
    ClassDB::bind_method(D_METHOD("prepare_intelligence", "locale"), &XochiVoice::prepare_intelligence);
    ClassDB::bind_method(D_METHOD("interpret_intent", "text", "locale", "checkpoint", "attempt", "session"), &XochiVoice::interpret_intent);
    ClassDB::bind_method(D_METHOD("deliver_interpretation", "intent", "language", "checkpoint", "attempt", "session"), &XochiVoice::deliver_interpretation);
    ADD_SIGNAL(MethodInfo("interpretation", PropertyInfo(Variant::STRING, "intent"), PropertyInfo(Variant::STRING, "language"), PropertyInfo(Variant::INT, "checkpoint"), PropertyInfo(Variant::INT, "attempt"), PropertyInfo(Variant::INT, "session")));
    ClassDB::bind_method(D_METHOD("begin_transcribing", "locale", "checkpoint", "attempt", "session"), &XochiVoice::begin_transcribing);
    ClassDB::bind_method(D_METHOD("speak_example", "text"), &XochiVoice::speak_example);
    ClassDB::bind_method(D_METHOD("deliver_transcript", "text", "language", "final", "checkpoint", "attempt", "session"), &XochiVoice::deliver_transcript);
    ADD_SIGNAL(MethodInfo("transcript", PropertyInfo(Variant::STRING, "text"), PropertyInfo(Variant::STRING, "language"), PropertyInfo(Variant::BOOL, "final"), PropertyInfo(Variant::INT, "checkpoint"), PropertyInfo(Variant::INT, "attempt"), PropertyInfo(Variant::INT, "session")));
    ClassDB::bind_method(D_METHOD("begin_listening", "locale", "checkpoint", "attempt", "session"), &XochiVoice::begin_listening);
    ClassDB::bind_method(D_METHOD("stop_listening"), &XochiVoice::stop_listening);
    ClassDB::bind_method(D_METHOD("deliver_cheer", "checkpoint", "attempt", "session"), &XochiVoice::deliver_cheer);
    ClassDB::bind_method(D_METHOD("deliver_status", "state", "message", "checkpoint", "attempt", "session"), &XochiVoice::deliver_status);
    ADD_SIGNAL(MethodInfo("cheer", PropertyInfo(Variant::INT, "checkpoint"), PropertyInfo(Variant::INT, "attempt"), PropertyInfo(Variant::INT, "session")));
    ADD_SIGNAL(MethodInfo("status", PropertyInfo(Variant::INT, "state"), PropertyInfo(Variant::STRING, "message"), PropertyInfo(Variant::INT, "checkpoint"), PropertyInfo(Variant::INT, "attempt"), PropertyInfo(Variant::INT, "session")));
}
XochiVoice::XochiVoice() {
    [XochiVoiceService shared].onInterpretation = ^(NSString *intent, NSString *language, NSInteger checkpoint, NSInteger attempt, NSInteger session) {
        if (instance) instance->call_deferred("deliver_interpretation", String::utf8([intent UTF8String]), String::utf8([language UTF8String]), int(checkpoint), int(attempt), int(session));
    };
    [XochiVoiceService shared].onTranscript = ^(NSString *text, NSString *language, BOOL final, NSInteger checkpoint, NSInteger attempt, NSInteger session) {
        if (instance) instance->call_deferred("deliver_transcript", String::utf8([text UTF8String]), String::utf8([language UTF8String]), bool(final), int(checkpoint), int(attempt), int(session));
    };
    [XochiVoiceService shared].onCheer = ^(NSInteger checkpoint, NSInteger attempt, NSInteger session) {
        if (instance) instance->call_deferred("deliver_cheer", int(checkpoint), int(attempt), int(session));
    };
    [XochiVoiceService shared].onStatus = ^(NSInteger state, NSString *message, NSInteger checkpoint, NSInteger attempt, NSInteger session) {
        if (instance) instance->call_deferred("deliver_status", int(state), String::utf8([message UTF8String]), int(checkpoint), int(attempt), int(session));
    };
}
XochiVoice::~XochiVoice() { [[XochiVoiceService shared] stopListening]; [XochiVoiceService shared].onCheer = nil; [XochiVoiceService shared].onStatus = nil; [XochiVoiceService shared].onTranscript = nil; [XochiVoiceService shared].onInterpretation = nil; }
bool XochiVoice::supported() { return [[XochiVoiceService shared] supported]; }
String XochiVoice::intelligence_status(const String &locale) {
    NSString *language = [NSString stringWithUTF8String:locale.utf8().get_data()];
    __block NSString *status;
    if ([NSThread isMainThread]) {
        status = [[XochiVoiceService shared] intelligenceStatus:language];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{ status = [[XochiVoiceService shared] intelligenceStatus:language]; });
    }
    return String::utf8([status UTF8String]);
}
void XochiVoice::interpret_intent(const String &text, const String &locale, int checkpoint, int attempt, int session) {
    NSString *utterance = [NSString stringWithUTF8String:text.utf8().get_data()];
    NSString *language = [NSString stringWithUTF8String:locale.utf8().get_data()];
    dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] interpretIntent:utterance locale:language checkpoint:checkpoint attempt:attempt session:session]; });
}
void XochiVoice::prepare_intelligence(const String &locale) {
    NSString *language = [NSString stringWithUTF8String:locale.utf8().get_data()];
    dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] prepareIntelligence:language]; });
}
void XochiVoice::deliver_interpretation(const String &intent, const String &language, int checkpoint, int attempt, int session) { emit_signal("interpretation", intent, language, checkpoint, attempt, session); }
void XochiVoice::begin_listening(const String &locale, int checkpoint, int attempt, int session) {
    NSString *language = [NSString stringWithUTF8String:locale.utf8().get_data()];
    dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] beginListening:language checkpoint:checkpoint attempt:attempt session:session]; });
}
bool XochiVoice::supported_locale(const String &locale) { return [[XochiVoiceService shared] supportedLocale:[NSString stringWithUTF8String:locale.utf8().get_data()]]; }
void XochiVoice::begin_transcribing(const String &locale, int checkpoint, int attempt, int session) {
    NSString *language = [NSString stringWithUTF8String:locale.utf8().get_data()];
    dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] beginTranscribing:language checkpoint:checkpoint attempt:attempt session:session]; });
}
void XochiVoice::speak_example(const String &text) {
    NSString *phrase = [NSString stringWithUTF8String:text.utf8().get_data()];
    dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] speakExample:phrase]; });
}
void XochiVoice::deliver_transcript(const String &text, const String &language, bool final, int checkpoint, int attempt, int session) { emit_signal("transcript", text, language, final, checkpoint, attempt, session); }
void XochiVoice::stop_listening() { dispatch_async(dispatch_get_main_queue(), ^{ [[XochiVoiceService shared] stopListening]; }); }
void XochiVoice::deliver_cheer(int checkpoint, int attempt, int session) { emit_signal("cheer", checkpoint, attempt, session); }
void XochiVoice::deliver_status(int state, const String &message, int checkpoint, int attempt, int session) { emit_signal("status", state, message, checkpoint, attempt, session); }
void initialize_xochi_voice() { ClassDB::register_class<XochiVoice>(); instance = memnew(XochiVoice); Engine::get_singleton()->add_singleton(Engine::Singleton("XochiVoice", instance)); }
void deinitialize_xochi_voice() { if (instance) { Engine::get_singleton()->remove_singleton("XochiVoice"); memdelete(instance); instance = nullptr; } }
