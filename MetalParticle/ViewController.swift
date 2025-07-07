import UIKit
import Metal
import MetalKit



// MARK: - View Controller
class DisintegrationViewController: UIViewController {
    
    private var testView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupTestView()
        setupUI()
    }
    
    private func setupTestView() {
        testView = UIView(frame: CGRect(x: 50, y: 200, width: 200, height: 150))
        testView.backgroundColor = .systemBlue
        testView.layer.cornerRadius = 20
        
        let label = UILabel()
        label.text = "Tap to Disintegrate!"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        testView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: testView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: testView.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(disintegrateView))
        testView.addGestureRecognizer(tapGesture)
        
        view.addSubview(testView)
    }
    
    private func setupUI() {
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset View", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        resetButton.backgroundColor = .systemGray6
        resetButton.layer.cornerRadius = 10
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetView), for: .touchUpInside)
        
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            resetButton.widthAnchor.constraint(equalToConstant: 120),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let instructionLabel = UILabel()
        instructionLabel.text = "Tap the blue view to see the Metal disintegration effect"
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func disintegrateView() {
//        let metalView = MetalDisintegrationView()
//        metalView.disintegrate(view: testView, maxTiles: 30000, inset: -40)
        let metalView = DisintegrateView()
        metalView.disintegrate(from: testView, maxTile: 50000, inset: -40)
    }
    
    @objc private func resetView() {
        // Remove any existing metal views
        view.subviews.compactMap { $0 as? DisintegrateView }.forEach { $0.removeFromSuperview() }
        
        // Recreate test view
        if testView.superview == nil {
            setupTestView()
        }
    }
}
