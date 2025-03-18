import Cocoa

protocol CaptureOverlayViewDelegate: AnyObject {
    func captureOverlayViewDidStartSelection(at point: NSPoint)
    func captureOverlayViewDidUpdateSelection(at point: NSPoint)
    func captureOverlayViewDidEndSelection(with rect: NSRect)
    func captureOverlayViewDidCancel()
}

class CaptureOverlayView: NSView {
    weak var delegate: CaptureOverlayViewDelegate?
    
    private var isSelecting = false
    private var startPoint: NSPoint = .zero
    private var currentPoint: NSPoint = .zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        isSelecting = true
        delegate?.captureOverlayViewDidStartSelection(at: startPoint)
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isSelecting {
            currentPoint = event.locationInWindow
            delegate?.captureOverlayViewDidUpdateSelection(at: currentPoint)
            needsDisplay = true
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if isSelecting {
            currentPoint = event.locationInWindow
            isSelecting = false
            
            let rect = selectionRect()
            delegate?.captureOverlayViewDidEndSelection(with: rect)
            needsDisplay = true
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC 키
            isSelecting = false
            delegate?.captureOverlayViewDidCancel()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard isSelecting else { return }
        
        let selRect = selectionRect()
        if !selRect.isEmpty {
            // 외부 어두운 영역 그리기
            NSColor.black.withAlphaComponent(0.3).set()
            
            // 위쪽 영역
            let topRect = NSRect(x: 0, y: selRect.maxY, width: bounds.width, height: bounds.height - selRect.maxY)
            NSBezierPath.fill(topRect)
            
            // 아래쪽 영역
            let bottomRect = NSRect(x: 0, y: 0, width: bounds.width, height: selRect.minY)
            NSBezierPath.fill(bottomRect)
            
            // 왼쪽 영역
            let leftRect = NSRect(x: 0, y: selRect.minY, width: selRect.minX, height: selRect.height)
            NSBezierPath.fill(leftRect)
            
            // 오른쪽 영역
            let rightRect = NSRect(x: selRect.maxX, y: selRect.minY, width: bounds.width - selRect.maxX, height: selRect.height)
            NSBezierPath.fill(rightRect)
            
            // 선택 영역 테두리 그리기
            NSColor.white.set()
            let bezierPath = NSBezierPath(rect: selRect)
            bezierPath.stroke()
            
            // 치수 표시
            let fontSize: CGFloat = 12.0
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize),
                .foregroundColor: NSColor.white
            ]
            
            let dimensionText = String(format: "%.0f × %.0f", selRect.width, selRect.height)
            let textSize = dimensionText.size(withAttributes: textAttributes)
            
            let textRect = NSRect(
                x: selRect.midX - textSize.width / 2,
                y: selRect.maxY + 5,
                width: textSize.width,
                height: textSize.height
            )
            
            dimensionText.draw(in: textRect, withAttributes: textAttributes)
        }
    }
    
    private func selectionRect() -> NSRect {
        return NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
} 