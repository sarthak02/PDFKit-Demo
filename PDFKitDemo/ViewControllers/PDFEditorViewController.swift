import UIKit
import PDFKit
class PDFEditorViewController: UIViewController {
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var editButton: UIButton! {
        didSet {
            editButton.layer.cornerRadius = editButton.frame.size.width/2
            editButton.backgroundColor = .white
            editButton.layer.shadowColor = UIColor.black.cgColor
            editButton.layer.shadowRadius = 5
            editButton.layer.shadowOpacity = 0.3
        }
    }
    @IBOutlet weak var drawingMenuView: SKDrawingView! {
        didSet {
            drawingMenuView.delegate = self
            drawingMenuView.dataSource = self
            let path = UIBezierPath(roundedRect: drawingMenuView.bounds,
                                    byRoundingCorners: [.topLeft, .bottomLeft],
                                    cornerRadii: CGSize(width: 12.0, height: 12.0))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            drawingMenuView.layer.mask = mask
            drawingMenuView.clipsToBounds = true
            drawingMenuView.isHidden = true
        }
    }
    let pdfDrawer = PDFDrawer()
    var pdfDrawingGestureRecognizer: DrawingGestureRecognizer?
    let drawingMenuItems = [#imageLiteral(resourceName: "pencil"), #imageLiteral(resourceName: "Highlighter"), #imageLiteral(resourceName: "Eraser"), #imageLiteral(resourceName: "Select"), UIColor.black,
                            UIColor.yellow,
                            UIColor.red,
                            UIColor.blue,
                            UIColor.green] as [Any]

    override func viewDidLoad() {
        super.viewDidLoad()
        pdfView.usePageViewController(true)
        self.configNavigationBar()
        self.setupPDFView()
    }
    func configNavigationBar() {
        self.navigationController?.navigationBar.isHidden = false
        let navigationTitleLabel = UILabel()
        let titleString = NSAttributedString(
            string: "PDFKit Demo",
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.bold),
                         NSAttributedString.Key.foregroundColor: UIColor.white])
        navigationTitleLabel.attributedText = titleString
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "background"), for: .default)
    }
    func setupPDFView() {
        self.loadLocalDocument(documentName: "SamplePDF")
        pdfView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        pdfView.displayDirection = .vertical
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
    }
    func loadLocalDocument(documentName: String) {
        let directory: URL = Contants.documentsDirectory
        do {
            let tempPath: URL = directory.appendingPathComponent(documentName)
            let fileName = "\(tempPath.path).pdf"
            if AppUtility.checkFileExists(at: fileName) {
                pdfView.document = PDFDocument(url: URL.init(fileURLWithPath: fileName))
            } else {
                try FileManager().copyfileToUserDocumentDirectory(forResource: documentName, ofType: "pdf")
                if AppUtility.checkFileExists(at: fileName) {
                    pdfView.document = PDFDocument(url: URL.init(fileURLWithPath: fileName))
                } else {
                    self.showErrorAlert("No document found")
                }
            }
        } catch {
            self.showErrorAlert("No document found")
        }
    }
    func showErrorAlert(_ message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: false)
    }
    @IBAction func editButtonClicked(sender: UIButton) {
        if let gesture = pdfDrawingGestureRecognizer {
            pdfView.removeGestureRecognizer(gesture)
            self.pdfDrawer.removeSelectiomIfAny()
        } else {
            self.drawingMenuView?.reloadData()
        }
        self.drawingMenuView?.isHidden.toggle()
    }
}
extension PDFEditorViewController: SKDrawingViewDatasource, SKDrawingViewDelegate {
    func numberOfItems(tabbar: SKDrawingView) -> Int {
        return self.drawingMenuItems.count
    }
    func tab(_ tabbar: SKDrawingView, iconAt index: Int) -> Any {
        return self.drawingMenuItems[index]
    }
    func didSelect(_ tabbar: SKDrawingView, selectedIndex: Int, deselectedIndex: Int?) {
        if let gesture = pdfDrawingGestureRecognizer {
            pdfView.removeGestureRecognizer(gesture)
            pdfDrawingGestureRecognizer = nil
        }
        tabbar.deSelectButtons()
        tabbar.selectedButton()
        pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer ?? DrawingGestureRecognizer())
        pdfDrawingGestureRecognizer?.drawingDelegate = pdfDrawer
        pdfDrawer.pdfView = pdfView
        switch selectedIndex {
        case 0:
            pdfDrawer.drawingTool = .pencil
        case 1:
            pdfDrawer.drawingTool = .highlighter
        case 2:
            pdfDrawer.drawingTool = .eraser
        case 3:
            pdfDrawer.drawingTool = .selector
        default:
            pdfDrawer.color = drawingMenuItems[selectedIndex] as? UIColor ?? UIColor.black
        }
    }
    func didDeselect(_ tabbar: SKDrawingView, index: Int) {}
}
