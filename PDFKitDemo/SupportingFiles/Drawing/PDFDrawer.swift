import Foundation
import PDFKit
import UIKit
public typealias ButtonEventHandler = () -> Void
enum DrawingTool: Int {
    case eraser = 0
    case pencil = 1
    case pen = 2
    case highlighter = 3
    case selector = 4
    var width: CGFloat {
        switch self {
        case .pencil:
            return 1
        case .pen:
            return 5
        case .highlighter:
            return 10
        default:
            return 0
        }
    }
    var alpha: CGFloat {
        switch self {
        case .highlighter:
            return 0.3 //0,5
        default:
            return 1
        }
    }
}
protocol PDFDrawerDelegate: AnyObject {
    func selectedAnnotation(annotation: PDFAnnotation, withFrane: CGRect, on page: PDFPage)
    func removeAnnotationSelection()
    func removeSelectedAnnotation(annotation: PDFAnnotation, page: PDFPage)
    func currentAnnoatation(annotation: PDFAnnotation, page: PDFPage)
}
class PDFDrawer {
    weak var pdfView: PDFView?
    private var path: UIBezierPath?
    private var currentAnnotation: DrawingAnnotation?
    private var currentPage: PDFPage?
    weak var delegate: PDFDrawerDelegate?
    var color = UIColor.black
    var actionButtonEventHandler: ButtonEventHandler?
    var drawingTool = DrawingTool.pen {
        didSet {
            if drawingTool  != .selector {
                removeSelectiomIfAny()
            }
        }
    }
    var annotation: PDFAnnotation?
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    func removeSelectiomIfAny() {
        // Remove selection of amnotstion if any.
        if annotation != nil {
            currentPage?.removeAnnotation(annotation ?? PDFAnnotation())
            annotation = nil
            self.delegate?.removeAnnotationSelection()
        }
    }
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView?.page(for: location, nearest: true) else { return }
        currentPage = page
        if let convertedPoint = pdfView?.convert(location, to: currentPage ?? PDFPage()) {
            if drawingTool == .selector {
                selectAnnotationAtPoint(point: convertedPoint, page: page)
                return
            }
            path = UIBezierPath()
            path?.move(to: convertedPoint)
        }
    }
    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let page = currentPage else { return }
        if let convertedPoint = pdfView?.convert(location, to: page) {
            if drawingTool == .selector {
                return
            }
            if drawingTool == .eraser {
                removeAnnotationAtPoint(point: convertedPoint, page: page)
                return
            }
            path?.addLine(to: convertedPoint)
            path?.move(to: convertedPoint)
            drawAnnotation(onPage: page)
        }
    }
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        if let convertedPoint = pdfView?.convert(location, to: page) {
            if drawingTool == .selector {
                return
            }
            // Erasing.
            if drawingTool == .eraser {
                removeAnnotationAtPoint(point: convertedPoint, page: page)
                return
            }
            // Drawing
            guard let annotation = currentAnnotation else { return }
            path?.addLine(to: convertedPoint)
            path?.move(to: convertedPoint)
            // Final annotation
            page.removeAnnotation(annotation)
            let finalAnnotation = createFinalAnnotation(path: path ?? UIBezierPath(), page: page)
            self.delegate?.currentAnnoatation(annotation: finalAnnotation, page: page)
            currentAnnotation = nil
        }
    }
    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        guard let view = pdfView else {
            return DrawingAnnotation()
        }
        let annotation = DrawingAnnotation(bounds: page.bounds(for: view.displayBox), forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        return annotation
    }
    private func drawAnnotation(onPage: PDFPage) {
        guard let path = path else { return }
        if currentAnnotation == nil {
            currentAnnotation = createAnnotation(path: path, page: onPage)
        }
        if let annotation = currentAnnotation {
            annotation.path = path
            forceRedraw(annotation: annotation, onPage: onPage)
        }
    }
    private func createFinalAnnotation(path: UIBezierPath, page: PDFPage) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        let bounds = CGRect(x: path.bounds.origin.x - 5,
                            y: path.bounds.origin.y - 5,
                            width: path.bounds.size.width + 10,
                            height: path.bounds.size.height + 10)
        let signingPathCentered = UIBezierPath()
        signingPathCentered.cgPath = path.cgPath
        signingPathCentered.moveCenter(to: bounds.center)
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        annotation.add(signingPathCentered)
        page.addAnnotation(annotation)
        return annotation
    }
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        if let selectedAnnotation = page.annotation(at: point) {
            self.delegate?.removeSelectedAnnotation(annotation: selectedAnnotation,
                                                    page: page)
        }
    }
    private func selectAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        if let selectedAnnotation = page.annotation(at: point) {
            if annotation != nil {
                page.removeAnnotation(annotation ?? PDFAnnotation())
                annotation = nil
                self.delegate?.removeAnnotationSelection()
            } else {
                annotation = PDFAnnotation(bounds: selectedAnnotation.bounds,
                                           forType: .highlight,
                                           withProperties: nil)
                annotation?.color = UIColor.lightGray.withAlphaComponent(0.5)
                annotation?.border?.lineWidth = 1.0
                annotation?.border?.style = .dashed
                page.addAnnotation(annotation ?? PDFAnnotation())
                self.delegate?.selectedAnnotation(annotation: selectedAnnotation, withFrane: annotation?.bounds ?? CGRect(), on: page)
            }
        } else {
            self.removeSelectiomIfAny()
        }
    }
    func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
}
