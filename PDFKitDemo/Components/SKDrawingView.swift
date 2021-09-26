import UIKit
protocol SKDrawingViewDatasource: AnyObject {
    func numberOfItems(tabbar: SKDrawingView) -> Int
    func tab(_ tabbar: SKDrawingView, iconAt index: Int) -> Any
}
protocol SKDrawingViewDelegate: AnyObject {
    func didSelect(_ tabbar: SKDrawingView, selectedIndex: Int, deselectedIndex: Int?)
    func didDeselect(_ tabbar: SKDrawingView, index: Int)
}
enum SKDrawingMenuDirection {
    case vertical
    case horizontal
}
class SKDrawingView: UIControl {
    weak var dataSource: SKDrawingViewDatasource?
    weak var delegate: SKDrawingViewDelegate?
    var selectedItemImageArray = [UIImage?]()
    var borderLayer: CAShapeLayer?
    private let stackView = UIStackView()
    private var buttons: [UIButton] = []
    var selectedSegmentIndex: Int? = nil {
        didSet {
            self.transition(from: oldValue, to: selectedSegmentIndex)
            if oldValue == selectedSegmentIndex { selectedSegmentIndex = nil }
            sendActions(for: .valueChanged)
        }
    }
    var menuDirection: SKDrawingMenuDirection = .vertical {
        didSet {
            if menuDirection == .vertical {
                self.stackView.axis = .vertical
            } else {
                self.stackView.axis = .horizontal
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    func commonInit() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 30.0
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1.0
        // configure stackview
        self.stackView.frame = self.bounds
        self.addSubview(stackView)
        self.stackView.alignment = .fill
        self.stackView.distribution = .fillEqually
        self.stackView.axis = .vertical
        self.stackView.spacing = 8
        self.stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8,
                                                                     leading: 8,
                                                                     bottom: 8,
                                                                     trailing: 8)
    }
    func reloadData() {
        guard let dataSource = dataSource else {
            return
        }
        stackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        buttons = []
        let count = dataSource.numberOfItems(tabbar: self)
        for index in 0..<count {
            let button = createButton(forIndex: index, withDataSource: dataSource)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        self.layoutIfNeeded()
        DispatchQueue.main.async { self.selectedSegmentIndex = 0 }
    }
}
extension SKDrawingView {
    func createButton(forIndex index: Int, withDataSource dataSource: SKDrawingViewDatasource) -> UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(selectButton(_:)), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.image?.withRenderingMode(.alwaysTemplate)
        button.translatesAutoresizingMaskIntoConstraints = false
        if let image = (dataSource.tab(self, iconAt: index) as? UIImage)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(image, for: UIControl.State())
            button.heightAnchor.constraint(equalToConstant: 54.0).isActive = true
        } else if let color =  dataSource.tab(self, iconAt: index) as? UIColor {
            button.backgroundColor = color
            if menuDirection == .vertical {
                button.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
                button.layer.cornerRadius = 24.0
            } else {
                button.layer.cornerRadius = 18.0
            }
        }
        if self.selectedItemImageArray.count > 0 {
            button.setImage(selectedItemImageArray[index], for: .selected)
        }
        button.tintColor = .black
        return button
    }
    @objc
    func selectButton(_ sender: UIButton) {
        if let index = buttons.firstIndex(of: sender) {
            selectedSegmentIndex = index
        }
    }
    func deSelectButtons() {
        if selectedSegmentIndex ?? 0 <= 3 {
            let selectedButton = self.buttons[selectedSegmentIndex ?? 0]
            for button in buttons where button != selectedButton {
                button.layer.borderWidth = 0.0
            }
        }
    }
    func selectedButton() {
        let button = self.buttons[selectedSegmentIndex ?? 0]
        button.layer.cornerRadius = button.frame.size.height/2
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
    }
    func transition(from fromIndex: Int?, to toIndex: Int?) {
        var fromIcon: UIButton?
        var toIcon: UIButton?
        if fromIndex != nil { fromIcon = buttons[fromIndex ?? 0] }
        if toIndex != nil { toIcon = buttons[toIndex ?? 0] }
        let animation = {
            fromIcon?.isSelected = false
            var isNewButtonSelectecd = true
            if fromIcon == toIcon { isNewButtonSelectecd = false }
            toIcon?.isSelected = isNewButtonSelectecd
        }
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 3,
            options: [],
            animations: animation,
            completion: nil
        )
        if fromIcon == toIcon {
            self.delegate?.didDeselect(self, index: toIndex ?? 0)
        } else {
            self.delegate?.didSelect(self, selectedIndex: toIndex ?? 0, deselectedIndex: fromIndex)
        }
    }
}
