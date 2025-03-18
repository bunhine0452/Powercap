import Cocoa
import Vision
import SwiftUI

enum CaptureMode {
    case text
    case image
    case translate
}

class ScreenCaptureManager: NSObject {
    static let shared = ScreenCaptureManager()
    
    private var captureWindow: NSWindow?
    private var currentMode: CaptureMode = .text
    private var startPoint: NSPoint = .zero
    private var currentPoint: NSPoint = .zero
    
    @AppStorage("translateLanguage") private var translateLanguage = "한국어"
    
    // 캡처 시작
    func startCapture(mode: CaptureMode) {
        self.currentMode = mode
        
        // 캡처 화면 생성
        let captureView = CaptureOverlayView()
        captureView.delegate = self
        
        let window = NSWindow(
            contentRect: NSScreen.main!.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = NSColor.black.withAlphaComponent(0.1)
        window.contentView = captureView
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        window.isOpaque = false
        window.makeKeyAndOrderFront(nil)
        
        self.captureWindow = window
    }
    
    // 캡처 종료
    func endCapture(with rect: NSRect) {
        captureWindow?.close()
        captureWindow = nil
        
        // 캡처 수행
        if !rect.isEmpty {
            let captureRect = normalizeRect(rect)
            let screenshot = takeScreenshot(of: captureRect)
            
            switch currentMode {
            case .text:
                extractText(from: screenshot)
            case .image:
                processImage(screenshot)
            case .translate:
                extractAndTranslateText(from: screenshot)
            }
        }
    }
    
    // 스크린샷 촬영
    private func takeScreenshot(of rect: NSRect) -> NSImage {
        let screenRect = NSScreen.main!.frame
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return NSImage()
        }
        
        return NSImage(cgImage: cgImage, size: rect.size)
    }
    
    // 텍스트 추출
    private func extractText(from image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else { return }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // 추출된 텍스트를 클립보드에 복사
            let text = recognizedStrings.joined(separator: "\n")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            
            // 사용자에게 알림
            self.showNotification(title: "텍스트 캡처 완료", body: "클립보드에 텍스트가 복사되었습니다.")
        }
        
        request.recognitionLevel = .accurate
        
        try? requestHandler.perform([request])
    }
    
    // 텍스트 추출 및 번역
    private func extractAndTranslateText(from image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else { return }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let text = recognizedStrings.joined(separator: "\n")
            
            // 번역 API 호출 (실제 구현 필요)
            let translatedText = self.translateText(text, to: self.translateLanguage)
            
            // 번역된 텍스트를 클립보드에 복사
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(translatedText, forType: .string)
            
            // 사용자에게 알림
            self.showNotification(title: "번역 완료", body: "번역된 텍스트가 클립보드에 복사되었습니다.")
        }
        
        request.recognitionLevel = .accurate
        
        try? requestHandler.perform([request])
    }
    
    // 간단한 번역 구현 (실제로는 번역 API 사용 필요)
    private func translateText(_ text: String, to language: String) -> String {
        // TODO: 실제 번역 API 구현
        return text + " (번역됨: \(language))"
    }
    
    // 이미지 처리 (배경 제거)
    private func processImage(_ image: NSImage) {
        // TODO: ML 기반 배경 제거 구현
        // 임시 구현: 이미지 저장
        saveImage(image)
    }
    
    // 이미지 저장
    private func saveImage(_ image: NSImage) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["png"]
        savePanel.nameFieldStringValue = "powercap_\(Int(Date().timeIntervalSince1970))"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                guard let data = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: data),
                      let pngData = rep.representation(using: .png, properties: [:]) else {
                    return
                }
                
                try? pngData.write(to: url)
                self.showNotification(title: "이미지 저장 완료", body: "이미지가 저장되었습니다.")
            }
        }
    }
    
    // 알림 표시
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // 좌표 정규화
    private func normalizeRect(_ rect: NSRect) -> NSRect {
        var normalized = rect
        if normalized.width < 0 {
            normalized.origin.x += normalized.width
            normalized.size.width = -normalized.width
        }
        if normalized.height < 0 {
            normalized.origin.y += normalized.height
            normalized.size.height = -normalized.height
        }
        return normalized
    }
}

extension ScreenCaptureManager: CaptureOverlayViewDelegate {
    func captureOverlayViewDidStartSelection(at point: NSPoint) {
        startPoint = point
    }
    
    func captureOverlayViewDidUpdateSelection(at point: NSPoint) {
        currentPoint = point
    }
    
    func captureOverlayViewDidEndSelection(with rect: NSRect) {
        endCapture(with: rect)
    }
    
    func captureOverlayViewDidCancel() {
        captureWindow?.close()
        captureWindow = nil
    }
} 