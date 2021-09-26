import UIKit
protocol DrawingGestureRecognizerDelegate: AnyObject {
    func gestureRecognizerBegan(_ location: CGPoint)
    func gestureRecognizerMoved(_ location: CGPoint)
    func gestureRecognizerEnded(_ location: CGPoint)
}

class DrawingGestureRecognizer: UIGestureRecognizer {
    weak var drawingDelegate: DrawingGestureRecognizerDelegate?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first,
            let numberOfTouches = event?.allTouches?.count,
            numberOfTouches == 1 {
            if touch.type == .pencil || touch.type == .direct {
                state = .began
                let location = touch.location(in: self.view)
                drawingDelegate?.gestureRecognizerBegan(location)
            }
        } else {
            state = .failed
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .changed
        guard let location = touches.first?.location(in: self.view) else { return }
        drawingDelegate?.gestureRecognizerMoved(location)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self.view) else {
            state = .ended
            return
        }
        drawingDelegate?.gestureRecognizerEnded(location)
        state = .ended
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }
}
