#!/usr/bin/env python3
"""Optional real Apple-model smoke probe on macOS 26 with Apple Intelligence.

Extracts the production enums, prompt and input guard; no expected answer enters
the model. Runs no microphone or game. This is not an iPhone latency benchmark.
Run: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer python3 tests/native_companion_model_probe.py
All cases share one process, with fresh model sessions and independently canceled
request deadlines. The default 5s deadline matches native interpretation. --timeout 15 permits
semantic diagnosis of slow results without changing the app's fixed deadline.
--prewarm-seconds 5 simulates preparation while the player speaks or types.
--guard-only checks anchored request/negation/sequence rejection without any model call.
Unavailable Apple Intelligence exits 77; any mismatch/deadline exits 1.
"""

import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile
import time


CASES = [
    ("¿Puedes saltar hasta la otra orilla?", "jump", "es"),
    ("Quédate aquí un momentito", "wait", "es"),
    ("Could you hop onto the little boat?", "boat", "en"),
    ("Walk over to the bridge, please", "bridge", "en"),
    ("Ven cerquita de mí, por favor", "come", "es"),
    ("No saltes, espera", "", "unknown"),
    ("Should I jump or wait?", "", "unknown"),
    ("Espera y luego salta", "", "unknown"),
    ("The bridge looks beautiful", "", "unknown"),
    ("I love jumping", "", "unknown"),
    ("Move somewhere nice", "", "unknown"),
    ("He said jump", "", "unknown"),
    ("Could you explain how to jump?", "", "unknown"),
    ("Me encanta saltar", "", "unknown"),
    ("¿Puedes contar un cuento sobre saltar?", "", "unknown"),
]


def swift_probe(source):
    enums = source.split("@available(iOS 26.0, *)\n@Generable\nprivate enum CompanionIntent", 1)[1]
    enums = "@available(iOS 26.0, *)\n@Generable\nprivate enum CompanionIntent" + enums.split("/// All mutable state", 1)[0]
    factory = source.split("    private func makeCompanionSession", 1)[1].split("    private func acceptsInterpretationInput", 1)[0]
    factory = "    static func makeCompanionSession" + factory
    guard = source.split("    private func acceptsInterpretationInput", 1)[1].split("    private func finishInterpretation", 1)[0]
    guard = "    static func acceptsInterpretationInput" + guard
    options = source.split("options: GenerationOptions(", 1)[1].split(")", 1)[0]
    return '''import Foundation
import FoundationModels
import Darwin
''' + enums + '''
struct ProbeResult {
    var intent = ""
    var language = "unknown"
    var status = "result"
}
@MainActor final class Attempt {
    private var continuation: CheckedContinuation<ProbeResult, Never>?
    private var inference: Task<Void, Never>?
    private var deadline: Task<Void, Never>?
    func run(_ text: String, model: LanguageModelSession, timeout: Double) async -> ProbeResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            inference = Task { @MainActor [weak self] in
                let result = await Probe.classify(text, model: model)
                guard !Task.isCancelled else { return }
                self?.finish(result)
            }
            deadline = Task { @MainActor [weak self] in
                do { try await Task.sleep(for: .seconds(timeout)) }
                catch { return }
                self?.finish(ProbeResult(status: "timeout"))
            }
        }
    }
    private func finish(_ result: ProbeResult) {
        guard let reply = continuation else { return }
        continuation = nil
        inference?.cancel()
        inference = nil
        deadline?.cancel()
        deadline = nil
        reply.resume(returning: result)
    }
}
@main struct Probe {
''' + guard + factory + '''
    @MainActor static func classify(_ text: String, model: LanguageModelSession) async -> ProbeResult {
        guard acceptsInterpretationInput(text) else { return ProbeResult() }
        do {
            let data = try JSONSerialization.data(withJSONObject: ["utterance": text], options: [.sortedKeys])
            let response = try await model.respond(to: String(data: data, encoding: .utf8)!,
                generating: CompanionDecision.self, options: GenerationOptions(''' + options + '''))
            if response.content.intent != .reject, response.content.language != .unknown {
                return ProbeResult(intent: response.content.intent.rawValue, language: response.content.language.rawValue)
            }
            return ProbeResult()
        } catch {
            return ProbeResult(status: "model_error: " + String(describing: error))
        }
    }
    @MainActor static func main() async {
        setbuf(stdout, nil)
        let data = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let texts = try! JSONDecoder().decode([String].self, from: data)
        let timeout = Double(CommandLine.arguments[2])!
        let guardOnly = CommandLine.arguments[3] == "guard"
        let prewarmSeconds = Double(CommandLine.arguments[4])!
        if !guardOnly {
            guard case .available = SystemLanguageModel.default.availability else {
                print("UNAVAILABLE", SystemLanguageModel.default.availability)
                exit(77)
            }
        }
        for (index, text) in texts.enumerated() {
            if guardOnly {
                let output = try! JSONSerialization.data(withJSONObject: ["index": index, "accepted": acceptsInterpretationInput(text)], options: [.sortedKeys])
                print("RESULT", String(data: output, encoding: .utf8)!)
                continue
            }
            let model = makeCompanionSession()
            if prewarmSeconds > 0 && acceptsInterpretationInput(text) {
                model.prewarm(promptPrefix: Prompt("{\\"utterance\\":"))
                try? await Task.sleep(for: .seconds(prewarmSeconds))
            }
            let started = ProcessInfo.processInfo.systemUptime
            let result = await Attempt().run(text, model: model, timeout: timeout)
            let output = try! JSONSerialization.data(withJSONObject: ["index": index, "intent": result.intent,
                "language": result.language, "status": result.status,
                "seconds": ProcessInfo.processInfo.systemUptime - started], options: [.sortedKeys])
            print("RESULT", String(data: output, encoding: .utf8)!)
        }
    }
}
'''



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--guard-only", action="store_true")
    parser.add_argument("--prewarm-seconds", type=float, default=0.0)
    args = parser.parse_args()
    if platform.system() != "Darwin":
        print("SKIP: requires macOS 26 and its local Apple model")
        return 77
    project = Path(__file__).resolve().parents[1]
    source = (project / "ios/src/XochiVoice.swift").read_text()
    env = os.environ.copy()
    env.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
    failures = 0
    with tempfile.TemporaryDirectory(prefix="xochi-model-probe-") as directory:
        directory = Path(directory)
        swift_file, binary = directory / "Probe.swift", directory / "probe"
        swift_file.write_text(swift_probe(source))
        subprocess.run(["xcrun", "swiftc", "-swift-version", "5", "-parse-as-library", "-target",
                        platform.machine() + "-apple-macos26.0", "-module-cache-path", str(directory / "modules"),
                        str(swift_file), "-o", str(binary)], env=env, check=True)
        cases_file = directory / "utterances.json"
        cases_file.write_text(json.dumps([case[0] for case in CASES]))
        started = time.monotonic()
        try:
            result = subprocess.run([str(binary), str(cases_file), str(args.timeout), "guard" if args.guard_only else "model", str(args.prewarm_seconds)], env=env,
                                    capture_output=True, text=True, timeout=len(CASES) * (args.timeout + args.prewarm_seconds + 2) + 15)
        except subprocess.TimeoutExpired as error:
            print("FAIL: probe process exceeded total deadline", error.stdout or "", flush=True)
            return 1
        if result.returncode == 77:
            print("SKIP:", result.stdout.strip())
            return 77
        outputs = [json.loads(line[7:]) for line in result.stdout.splitlines() if line.startswith("RESULT ")]
        for index, (text, expected, expected_language) in enumerate(CASES):
            output = next((item for item in outputs if item.get("index") == index), {})
            if args.guard_only:
                # The gate checks request grammar; an unknown destination still
                # needs the model to reject it semantically.
                expected_shape = bool(expected) or text == "Move somewhere nice"
                passed = output.get("accepted") == expected_shape
            else:
                passed = output.get("status") == "result" and output.get("intent") == expected and output.get("language") == expected_language
            print("PASS" if passed else "FAIL", repr(text), output, flush=True)
            if not passed:
                failures += 1
        if result.stderr.strip():
            print(result.stderr.strip(), flush=True)
        print(f"One process; total {time.monotonic() - started:.2f}s", flush=True)
    print(f"[NativeCompanionModelProbe] {len(CASES) - failures}/{len(CASES)} passed; {"request guard only" if args.guard_only else "host model only"}, no microphone")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
