import Cocoa
import Carbon
import SwiftUI

class ShortcutManager {
    static let shared = ShortcutManager()
    
    private var textCaptureEventHandler: EventHandlerRef?
    private var imageCaptureEventHandler: EventHandlerRef?
    private var translateCaptureEventHandler: EventHandlerRef?
    
    // 핫키 핸들러 콜백 함수 ID를 저장하는 딕셔너리
    private static var hotKeyHandlers: [UInt32: () -> Void] = [:]
    
    // 가상 키 코드 정의
    private let kVK_ANSI_T: UInt32 = 0x11 // T 키의 가상 키 코드
    private let kVK_ANSI_I: UInt32 = 0x22 // I 키의 가상 키 코드
    private let kVK_ANSI_R: UInt32 = 0x0F // R 키의 가상 키 코드
    
    // 단축키 등록
    func registerShortcuts() {
        registerTextCaptureShortcut()
        registerImageCaptureShortcut()
        registerTranslateCaptureShortcut()
    }
    
    // 텍스트 캡처 단축키 등록
    private func registerTextCaptureShortcut() {
        // 이전 핸들러 해제
        if textCaptureEventHandler != nil {
            UnregisterEventHotKey(textCaptureEventHandler!)
            textCaptureEventHandler = nil
        }
        
        // ⌘⇧T (기본값)
        let commandKey = UInt32(cmdKey)
        let shiftKey = UInt32(shiftKey)
        
        registerHotKey(
            keyCode: kVK_ANSI_T,
            modifiers: commandKey | shiftKey,
            id: 1,
            handler: { ScreenCaptureManager.shared.startCapture(mode: .text) }
        )
    }
    
    // 이미지 캡처 단축키 등록
    private func registerImageCaptureShortcut() {
        // 이전 핸들러 해제
        if imageCaptureEventHandler != nil {
            UnregisterEventHotKey(imageCaptureEventHandler!)
            imageCaptureEventHandler = nil
        }
        
        // ⌘⇧I (기본값)
        let commandKey = UInt32(cmdKey)
        let shiftKey = UInt32(shiftKey)
        
        registerHotKey(
            keyCode: kVK_ANSI_I,
            modifiers: commandKey | shiftKey,
            id: 2,
            handler: { ScreenCaptureManager.shared.startCapture(mode: .image) }
        )
    }
    
    // 번역 캡처 단축키 등록
    private func registerTranslateCaptureShortcut() {
        // 이전 핸들러 해제
        if translateCaptureEventHandler != nil {
            UnregisterEventHotKey(translateCaptureEventHandler!)
            translateCaptureEventHandler = nil
        }
        
        // ⌘⇧R (기본값)
        let commandKey = UInt32(cmdKey)
        let shiftKey = UInt32(shiftKey)
        
        registerHotKey(
            keyCode: kVK_ANSI_R,
            modifiers: commandKey | shiftKey,
            id: 3,
            handler: { ScreenCaptureManager.shared.startCapture(mode: .translate) }
        )
    }
    
    // 단축키 등록 헬퍼 함수
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, id: UInt32, handler: @escaping () -> Void) {
        var hotKeyRef: EventHotKeyRef?
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x504f5743), // 'POWC'
                                     id: id)
        
        // 핸들러 저장
        ShortcutManager.hotKeyHandlers[id] = handler
        
        // 핫키 핸들러 등록
        let eventSpec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                        eventKind: UInt32(kEventHotKeyPressed))
        ]
        
        var eventHandler: EventHandlerRef?
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            eventSpec,
            nil,
            &eventHandler
        )
        
        // 핫키 등록
        _ = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        // 핸들러 저장
        switch id {
        case 1:
            textCaptureEventHandler = eventHandler
        case 2:
            imageCaptureEventHandler = eventHandler
        case 3:
            translateCaptureEventHandler = eventHandler
        default:
            break
        }
    }
}

// C 함수 콜백 (전역 함수)
func hotKeyHandler(_ nextHandler: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let size = MemoryLayout<EventHotKeyID>.size
    let status = GetEventParameter(event!, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID), nil, size, nil, &hotKeyID)
    
    if status == noErr {
        if let handler = ShortcutManager.hotKeyHandlers[hotKeyID.id] {
            DispatchQueue.main.async {
                handler()
            }
        }
    }
    
    return noErr
} 