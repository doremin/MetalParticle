//
//  StressTestViewController.swift
//  MetalParticle
//
//  Created by doremin on 7/7/25.
//

import UIKit
import MetalKit

final class StressTestViewController: UIViewController {
    // MARK: - UI
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.text = "파티클: 1,000"
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let runButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Stress Test 실행", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let fpsLabel: UILabel = {
        let l = UILabel()
        l.text = "FPS: -"
        l.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        l.textColor = .systemGreen
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    
    private var disintegrateView: DisintegrateView?
    private var targetView: UIView!
    
    private var autoTestParticleCount = 1000
    private var autoTestStep = 2000
    private var autoTestMax = 200000
    private var isAutoTesting = false
    private var lastMeasuredFPS: Double = 0
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        runButton.addTarget(self, action: #selector(runAutoStressTestButtonTapped), for: .touchUpInside)
        
        setupTargetView()
        setupFPSDisplayLink()
    }
    
    private func setupUI() {
        view.addSubview(valueLabel)
        view.addSubview(runButton)
        view.addSubview(fpsLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            valueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            runButton.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 20),
            runButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            fpsLabel.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 30),
            fpsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupTargetView() {
        // 파티클 해체 대상이 될 임의의 UIView 준비 (여기선 단순한 컬러 박스)
        let box = UIView(frame: CGRect(x: 0, y: 240, width: 400, height: 500))
        box.backgroundColor = .systemBlue
        box.layer.cornerRadius = 32
        box.layer.masksToBounds = true
        view.addSubview(box)
        self.targetView = box
    }
    
    private func setupFPSDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    // 4. FPS 측정값 기록 (updateFPS 내에 추가/수정)
    @objc private func updateFPS(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            frameCount = 0
            return
        }
        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            fpsLabel.text = String(format: "FPS: %.0f", fps)
            lastTimestamp = link.timestamp
            frameCount = 0
            lastMeasuredFPS = fps // <- 추가!
        }
    }
    
    // 2. 자동 스트레스 테스트 진입 메서드
    private func startAutoStressTest() {
        isAutoTesting = true
        autoTestParticleCount = 1000
        runAutoStressTestStep()
    }
    
    @objc private func runAutoStressTestButtonTapped() {
        if !isAutoTesting {
            startAutoStressTest()
        }
    }
    
    // 3. 한 단계 실행 메서드
    private func runAutoStressTestStep() {
        guard isAutoTesting else { return }
        disintegrateView?.removeFromSuperview()
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        let disintegrateView = DisintegrateView(frame: view.bounds, device: device)
        view.addSubview(disintegrateView)
        self.disintegrateView = disintegrateView
        setupTargetView()
        valueLabel.text = "파티클: \(autoTestParticleCount.formatted())"
        disintegrateView.disintegrate(from: targetView, maxTile: autoTestParticleCount)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            let measuredFPS = self.lastMeasuredFPS
            print("Particle: \(self.autoTestParticleCount) -> FPS: \(measuredFPS)")
            if measuredFPS < 50.0 && self.autoTestParticleCount > 4000 {
                self.isAutoTesting = false
                self.fpsLabel.text = "한계치: \(self.autoTestParticleCount.formatted())개 (\(String(format: "%.1f", measuredFPS)) FPS)"
                let alert = UIAlertController(
                    title: "한계 도달",
                    message: "FPS가 50 미만으로 떨어짐!\n파티클 개수: \(self.autoTestParticleCount)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(alert, animated: true)
                return
            }
            self.autoTestParticleCount += self.autoTestStep
            if self.autoTestParticleCount > self.autoTestMax {
                self.isAutoTesting = false
                self.fpsLabel.text = "최대치까지 OK (\(measuredFPS) FPS)"
                return
            }
            self.runAutoStressTestStep()
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
