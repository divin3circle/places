
import SwiftUI
import SpriteKit
import CoreMotion

// MARK: - Public SwiftUI wrapper

struct GravityContainer: View {
    let items: [TravelInterest]
    @Binding var selectedItems: Set<TravelInterest>
    let maxSelections: Int
    var gravity: CGFloat = 1.0
    var bounce: CGFloat = 0.35

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // A single scene instance, created once and kept stable across re-renders.
    @State private var scene = ChipScene(size: CGSize(width: 1, height: 1))
    // Snapshot the items once so a caller that reshuffles on every render
    // (e.g. `EastAfricaInterestsDataset.shuffled()`) can't churn the scene.
    @State private var stableItems: [TravelInterest] = []
    @State private var configured = false

    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: scene, options: [.allowsTransparency])
                .background(Color.clear)
                .onAppear { configure(size: proxy.size) }
                .onChange(of: proxy.size) { _, newSize in
                    if newSize.width > 1, newSize.height > 1 { scene.size = newSize }
                }
                .onChange(of: selectedItems) { _, newValue in
                    scene.applyExternalSelection(Set(newValue.map(\.id)))
                }
        }
    }

    private func configure(size: CGSize) {
        let source = stableItems.isEmpty ? items : stableItems
        stableItems = source

        scene.scaleMode = .resizeFill
        scene.reduceMotion = reduceMotion
        scene.maxSelections = maxSelections
        scene.gravityScale = gravity
        scene.bounceScale = bounce
        scene.interests = source
        scene.onSelectionChanged = { ids in
            let newSelection = Set(source.filter { ids.contains($0.id) })
            if newSelection != selectedItems { selectedItems = newSelection }
        }
        if size.width > 1, size.height > 1 { scene.size = size }
        scene.applyExternalSelection(Set(selectedItems.map(\.id)))
        configured = true
    }
}

// MARK: - Physics categories

private enum PhysicsCategory {
    static let chip: UInt32 = 0x1 << 0
    static let edge: UInt32 = 0x1 << 1
}

// MARK: - Scene

final class ChipScene: SKScene, SKPhysicsContactDelegate {

    // Configuration (set by the SwiftUI wrapper before/at first layout).
    var interests: [TravelInterest] = []
    var maxSelections: Int = 5
    var reduceMotion: Bool = false
    var gravityScale: CGFloat = 1.0
    var bounceScale: CGFloat = 0.35
    var onSelectionChanged: ((Set<UUID>) -> Void)?

    // State
    private var chips: [UUID: ChipNode] = [:]
    private var selectedIDs: Set<UUID> = []
    private var didBuild = false
    private var chipDiameter: CGFloat = 66

    // Haptics
    private let selectHaptic = UIImpactFeedbackGenerator(style: .light)
    private let denyHaptic = UINotificationFeedbackGenerator()
    private let knockHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private var lastKnockTime: TimeInterval = 0

    // Device tilt
    private let motionManager = CMMotionManager()

    private var baseGravity: CGVector { CGVector(dx: 0, dy: -11.0 * gravityScale) }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 120          // ProMotion
        view.ignoresSiblingOrder = true
        scaleMode = .resizeFill

        physicsWorld.gravity = reduceMotion ? .zero : baseGravity
        physicsWorld.contactDelegate = self

        selectHaptic.prepare()
        denyHaptic.prepare()
        rebuildEdges()
        startTiltIfAvailable()
    }

    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        rebuildEdges()
    }

    override func update(_ currentTime: TimeInterval) {
        // Build lazily the first time we have a real size AND data. This is
        // robust to SwiftUI's makeUIView/onAppear ordering (the old bug).
        if !didBuild, size.width > 1, size.height > 1, !interests.isEmpty {
            buildChips()
            didBuild = true
        }
    }

    // MARK: Build

    private func rebuildEdges() {
        let border = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        border.categoryBitMask = PhysicsCategory.edge
        border.friction = 0.3
        border.restitution = 0.15 + bounceScale * 0.2
        physicsBody = border
    }

    private func buildChips() {
        chipDiameter = min(max(size.width / 5.6, 58), 76)

        if reduceMotion {
            buildStaticGrid()
            return
        }

        let margin = chipDiameter * 0.6
        for (index, interest) in interests.enumerated() {
            let chip = ChipNode(interest: interest, diameter: chipDiameter)
            chip.isSelectedChip = selectedIDs.contains(interest.id)
            // Drop in from just under the ceiling so they pour into a pile.
            // (The edge loop is a closed box; spawning above size.height would
            //  trap them outside the ceiling.)
            let x = CGFloat.random(in: margin ... max(margin, size.width - margin))
            let y = size.height - chipDiameter * CGFloat.random(in: 0.55 ... 0.9)
            chip.position = CGPoint(x: x, y: y)
            chip.attachPhysics(restitution: 0.28 + bounceScale * 0.35)
            chip.physicsBody?.velocity = CGVector(dx: .random(in: -30 ... 30), dy: .random(in: -70 ... -20))
            chips[interest.id] = chip

            // Staggered "pour" so they arrive one-by-one, not as one clump.
            // NOTE: run the timer on `self` (the scene), which is in the graph —
            // actions on a not-yet-added node never tick.
            chip.alpha = 0
            let delay = Double(index) * 0.07
            run(.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in
                    guard let self else { return }
                    self.addChild(chip)
                    chip.run(.fadeIn(withDuration: 0.18))
                    if self.selectedIDs.contains(interest.id) { self.rise(chip) }
                }
            ]))
        }
    }

    private func buildStaticGrid() {
        let d = chipDiameter
        let spacing: CGFloat = 12
        let cols = max(1, Int(size.width / (d + spacing)))
        let rows = Int(ceil(Double(interests.count) / Double(cols)))
        let totalW = CGFloat(cols) * (d + spacing) - spacing
        let startX = (size.width - totalW) / 2 + d / 2
        let startY = size.height / 2 + CGFloat(rows) / 2 * (d + spacing)

        for (index, interest) in interests.enumerated() {
            let chip = ChipNode(interest: interest, diameter: d)
            chip.isSelectedChip = selectedIDs.contains(interest.id)
            let col = index % cols
            let row = index / cols
            chip.position = CGPoint(
                x: startX + CGFloat(col) * (d + spacing),
                y: startY - CGFloat(row) * (d + spacing)
            )
            chip.attachPhysics(restitution: 0)
            chip.physicsBody?.isDynamic = false     // no falling under Reduce Motion
            chips[interest.id] = chip
            addChild(chip)
        }
    }

    // MARK: Interaction

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for node in nodes(at: location) {
            if let chip = node as? ChipNode ?? node.parent as? ChipNode {
                toggle(chip)
                return
            }
        }
    }

    private func toggle(_ chip: ChipNode) {
        if chip.isSelectedChip {
            chip.isSelectedChip = false
            selectedIDs.remove(chip.id)
            chip.setSelected(false)
            sink(chip)
            selectHaptic.impactOccurred(intensity: 0.7)
            notify()
        } else {
            guard selectedIDs.count < maxSelections else {
                chip.shake()
                denyHaptic.notificationOccurred(.warning)
                return
            }
            chip.isSelectedChip = true
            selectedIDs.insert(chip.id)
            chip.setSelected(true)
            rise(chip)
            chip.emitSparkle()
            selectHaptic.impactOccurred()
            notify()
        }
    }

    private func notify() { onSelectionChanged?(selectedIDs) }

    /// Selected chips float up and cluster against the ceiling.
    private func rise(_ chip: ChipNode) {
        guard !reduceMotion, let body = chip.physicsBody else { return }
        body.affectedByGravity = false
        body.linearDamping = 3.6
        body.velocity = CGVector(dx: body.velocity.dx * 0.3, dy: size.height * 1.15)
    }

    /// Deselected chips drop back into the pile.
    private func sink(_ chip: ChipNode) {
        guard !reduceMotion, let body = chip.physicsBody else { return }
        body.affectedByGravity = true
        body.linearDamping = 0.55
    }

    /// Sync selection coming from SwiftUI (e.g. programmatic clear) without
    /// bouncing an event back through onSelectionChanged.
    func applyExternalSelection(_ ids: Set<UUID>) {
        guard didBuild else { selectedIDs = ids; return }
        guard ids != selectedIDs else { return }
        for (id, chip) in chips {
            let shouldSelect = ids.contains(id)
            if chip.isSelectedChip != shouldSelect {
                chip.isSelectedChip = shouldSelect
                chip.setSelected(shouldSelect)
                shouldSelect ? rise(chip) : sink(chip)
            }
        }
        selectedIDs = ids
    }

    // MARK: Contact haptics

    func didBegin(_ contact: SKPhysicsContact) {
        // Light tick when chips knock together, throttled and gated on impact.
        guard !reduceMotion else { return }
        let now = CACurrentMediaTime()
        guard now - lastKnockTime > 0.06 else { return }
        let speed = hypot(contact.bodyA.velocity.dx - contact.bodyB.velocity.dx,
                          contact.bodyA.velocity.dy - contact.bodyB.velocity.dy)
        guard speed > 120 else { return }
        lastKnockTime = now
        knockHaptic.impactOccurred(intensity: min(1, speed / 900))
    }

    // MARK: Device tilt

    private func startTiltIfAvailable() {
        guard !reduceMotion, motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let g = motion?.gravity else { return }
            let mag = 11.0 * self.gravityScale
            // Device gravity is a unit-ish vector; map x/y into the scene plane.
            self.physicsWorld.gravity = CGVector(dx: g.x * mag, dy: g.y * mag)
        }
    }
}

// MARK: - Chip node

final class ChipNode: SKSpriteNode {
    let id: UUID
    let interest: TravelInterest
    private let diameter: CGFloat
    var isSelectedChip: Bool = false

    private let unselectedTexture: SKTexture
    private let selectedTexture: SKTexture

    init(interest: TravelInterest, diameter: CGFloat) {
        self.id = interest.id
        self.interest = interest
        self.diameter = diameter
        self.unselectedTexture = ChipRenderer.texture(for: interest, diameter: diameter, selected: false)
        self.selectedTexture = ChipRenderer.texture(for: interest, diameter: diameter, selected: true)
        super.init(texture: unselectedTexture, color: .clear, size: CGSize(width: diameter, height: diameter))
        zPosition = 1
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func attachPhysics(restitution: CGFloat) {
        let body = SKPhysicsBody(circleOfRadius: diameter / 2)
        body.categoryBitMask = PhysicsCategory.chip
        body.collisionBitMask = PhysicsCategory.chip | PhysicsCategory.edge
        body.contactTestBitMask = PhysicsCategory.chip
        body.restitution = restitution
        body.friction = 0.5
        body.linearDamping = 0.55
        body.angularDamping = 1.0
        body.allowsRotation = false           // keep the label upright
        body.density = 1.0
        texture = isSelectedChip ? selectedTexture : unselectedTexture
        physicsBody = body
    }

    func setSelected(_ selected: Bool) {
        texture = selected ? selectedTexture : unselectedTexture
        removeAction(forKey: "pulse")
        let up = SKAction.scale(to: 1.16, duration: 0.11)
        up.timingMode = .easeOut
        let down = SKAction.scale(to: 1.0, duration: 0.24)
        down.timingMode = .easeInEaseOut
        run(.sequence([up, down]), withKey: "pulse")
    }

    func shake() {
        removeAction(forKey: "shake")
        let dx: CGFloat = 7
        let seq = SKAction.sequence([
            .moveBy(x: -dx, y: 0, duration: 0.04),
            .moveBy(x: dx * 2, y: 0, duration: 0.08),
            .moveBy(x: -dx * 2, y: 0, duration: 0.08),
            .moveBy(x: dx, y: 0, duration: 0.04)
        ])
        run(seq, withKey: "shake")
    }

    func emitSparkle() {
        let emitter = ChipRenderer.sparkle(color: ChipRenderer.accent, diameter: diameter)
        emitter.zPosition = 5
        emitter.position = .zero
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.7), .removeFromParent()]))
    }
}

// MARK: - Rendering helpers

private enum ChipRenderer {
    static let accent = UIColor(named: "AccentColor") ?? .systemRed

    /// Pre-render the whole chip face (circle + icon + label) into a crisp
    /// @3x texture. Swapping textures on select is cheap and pixel-perfect.
    static func texture(for interest: TravelInterest, diameter: CGFloat, selected: Bool) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 3
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let bg: UIColor = selected ? accent : .systemGray6
        let fg: UIColor = selected ? .white : .darkGray

        let image = renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            bg.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            // Icon
            let iconConfig = UIImage.SymbolConfiguration(pointSize: diameter * 0.3, weight: .semibold)
            if let icon = UIImage(systemName: interest.icon, withConfiguration: iconConfig)?
                .withTintColor(fg, renderingMode: .alwaysOriginal) {
                let iconRect = CGRect(
                    x: (diameter - icon.size.width) / 2,
                    y: diameter * 0.22,
                    width: icon.size.width,
                    height: icon.size.height
                )
                icon.draw(in: iconRect)
            }

            // Label
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: roundedFont(diameter * 0.16, .semibold),
                .foregroundColor: fg,
                .paragraphStyle: paragraph,
            ]
            let textRect = CGRect(x: 3, y: diameter * 0.60, width: diameter - 6, height: diameter * 0.30)
            (interest.label as NSString).draw(in: textRect, withAttributes: attrs)
        }

        return SKTexture(image: image)
    }

    static func roundedFont(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    // Small shared white dot used by the selection sparkle burst.
    static let sparkTexture: SKTexture = {
        let d: CGFloat = 6
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 3
        let image = UIGraphicsImageRenderer(size: CGSize(width: d, height: d), format: format).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: d, height: d)).fill()
        }
        return SKTexture(image: image)
    }()

    static func sparkle(color: UIColor, diameter: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = sparkTexture
        e.particleBirthRate = 800
        e.numParticlesToEmit = 14
        e.particleLifetime = 0.45
        e.particleLifetimeRange = 0.15
        e.emissionAngle = 0
        e.emissionAngleRange = .pi * 2
        e.particleSpeed = diameter * 1.7
        e.particleSpeedRange = diameter * 0.7
        e.particleAlpha = 0.9
        e.particleAlphaSpeed = -2.0
        e.particleScale = 0.30
        e.particleScaleRange = 0.12
        e.particleScaleSpeed = -0.45
        e.particleColor = color
        e.particleColorBlendFactor = 1.0
        e.particleBlendMode = .add
        return e
    }
}

#Preview {
    SecondOnboarding()
}
