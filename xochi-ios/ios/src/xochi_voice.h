#pragma once
#include "core/object/object.h"
#include "core/object/class_db.h"
class XochiVoice : public Object {
    GDCLASS(XochiVoice, Object);
protected:
    static void _bind_methods();
public:
    XochiVoice();
    ~XochiVoice();
    bool supported();
    bool supported_locale(const String &locale);
    String intelligence_status(const String &locale);
    void prepare_intelligence(const String &locale);
    void interpret_intent(const String &text, const String &locale, int checkpoint, int attempt, int session);
    void deliver_interpretation(const String &intent, const String &language, int checkpoint, int attempt, int session);
    void begin_transcribing(const String &locale, int checkpoint, int attempt, int session);
    void speak_example(const String &text);
    void deliver_transcript(const String &text, const String &language, bool final, int checkpoint, int attempt, int session);
    void begin_listening(const String &locale, int checkpoint, int attempt, int session);
    void stop_listening();
    void deliver_cheer(int checkpoint, int attempt, int session);
    void deliver_status(int state, const String &message, int checkpoint, int attempt, int session);
};
void initialize_xochi_voice();
void deinitialize_xochi_voice();
