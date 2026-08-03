import AppKit
import ImageIO
import SceneKit

// Geometry and material values are ported from hayashiii-ghub/ipod@c3ce323.
// The generated PNGs contain only hardware layers; live UI and input stay native.

private struct AssetSpec {
    enum Grade {
        case chassis
        case wheel
        case center
    }

    let filename: String
    let size: CGSize
    let verticalSpan: CGFloat
    let grade: Grade
    let makeNodes: () -> [SCNNode]
}

private enum RenderError: Error {
    case invalidArguments
    case invalidExistingAssetDimensions(String, expected: CGSize, actual: CGSize)
    case pngEncodingFailed(String)
}

private let outputDirectory: URL = {
    guard CommandLine.arguments.count == 2 ||
            (CommandLine.arguments.count == 3 &&
                ["--grade-existing", "--repair-alpha"].contains(CommandLine.arguments[2])) else {
        fputs("usage: generate_kurukuru_hybrid_assets.swift <output-directory> [--grade-existing|--repair-alpha]\n", stderr)
        exit(2)
    }
    return URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
}()

private let aluminumTexture = makeBrushedAluminumTexture(size: 1_024)

private let specs = [
    AssetSpec(
        filename: "KurukuruChassisFront.png",
        size: CGSize(width: 1_088, height: 1_448),
        verticalSpan: 69.8,
        grade: .chassis,
        makeNodes: makeChassisNodes
    ),
    AssetSpec(
        filename: "KurukuruWheelRing.png",
        size: CGSize(width: 568, height: 568),
        verticalSpan: 27.4,
        grade: .wheel,
        makeNodes: { [makeWheelRingNode()] }
    ),
    AssetSpec(
        filename: "KurukuruCenterButton.png",
        size: CGSize(width: 280, height: 280),
        verticalSpan: 12.4,
        grade: .center,
        makeNodes: { [makeCenterButtonNode()] }
    )
]

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
let existingAssetMode = CommandLine.arguments.count == 3 ? CommandLine.arguments[2] : nil

for spec in specs {
    let outputURL = outputDirectory.appendingPathComponent(spec.filename)
    let sourceImage: CGImage
    if existingAssetMode != nil {
        guard let imageSource = CGImageSourceCreateWithURL(outputURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let pixelWidth = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let pixelHeight = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
            throw RenderError.pngEncodingFailed(spec.filename)
        }
        let actualSize = CGSize(width: pixelWidth.intValue, height: pixelHeight.intValue)
        guard actualSize == spec.size else {
            throw RenderError.invalidExistingAssetDimensions(
                spec.filename,
                expected: spec.size,
                actual: actualSize
            )
        }
        guard let existingImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw RenderError.pngEncodingFailed(spec.filename)
        }
        sourceImage = existingImage
    } else {
        let image = render(spec: spec)
        var proposedRect = NSRect(origin: .zero, size: spec.size)
        guard let renderedImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            throw RenderError.pngEncodingFailed(spec.filename)
        }
        sourceImage = renderedImage
    }
    let outputImage: CGImage?
    if existingAssetMode == "--repair-alpha" {
        switch spec.grade {
        case .chassis:
            outputImage = sourceImage
        case .wheel:
            outputImage = clippedToCircle(sourceImage, innerRadiusRatio: 6.3 / 13.7)
        case .center:
            outputImage = clippedToCircle(sourceImage)
        }
    } else {
        outputImage = grade(sourceImage, as: spec.grade)
    }
    guard let cgImage = outputImage,
          hasTransparentCorner(cgImage),
          let png = pngData(for: cgImage) else {
        throw RenderError.pngEncodingFailed(spec.filename)
    }
    try (png as Data).write(to: outputURL, options: .atomic)
    print(outputURL.path)
}

private func hasTransparentCorner(_ image: CGImage) -> Bool {
    let bitmap = NSBitmapImageRep(cgImage: image)
    return (bitmap.colorAt(x: 0, y: 0)?.alphaComponent ?? 1) < 0.02
}

private func clippedToCircle(_ source: CGImage, innerRadiusRatio: CGFloat? = nil) -> CGImage? {
    let width = source.width
    let height = source.height
    guard let (bytesPerRow, _) = rgbaLayout(width: width, height: height) else { return nil }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let bounds = CGRect(x: 0.5, y: 0.5, width: CGFloat(width) - 1, height: CGFloat(height) - 1)
    let path = CGMutablePath()
    path.addEllipse(in: bounds)
    if let innerRadiusRatio {
        let diameter = min(bounds.width, bounds.height) * innerRadiusRatio
        path.addEllipse(
            in: CGRect(
                x: bounds.midX - diameter / 2,
                y: bounds.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
        )
    }
    context.addPath(path)
    context.clip(using: innerRadiusRatio == nil ? .winding : .evenOdd)
    context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()
}

private func pngData(for image: CGImage) -> CFData? {
    let data = CFDataCreateMutable(nil, 0)!
    guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
        return nil
    }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination) ? data : nil
}

private func grade(_ source: CGImage, as grade: AssetSpec.Grade) -> CGImage? {
    let bitmap = NSBitmapImageRep(cgImage: source)
    guard bitmap.pixelsWide == source.width, bitmap.pixelsHigh == source.height else { return nil }

    for y in 0..<bitmap.pixelsHigh {
        for x in 0..<bitmap.pixelsWide {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            let alpha = color.alphaComponent
            guard alpha > 0 else { continue }
            let outputRGB = adjusted(
                [color.redComponent, color.greenComponent, color.blueComponent],
                for: grade
            )
            bitmap.setColor(
                NSColor(
                    deviceRed: max(0, min(1, outputRGB[0])),
                    green: max(0, min(1, outputRGB[1])),
                    blue: max(0, min(1, outputRGB[2])),
                    alpha: alpha
                ),
                atX: x,
                y: y
            )
        }
    }

    return bitmap.cgImage
}

private func rgbaLayout(width: Int, height: Int) -> (bytesPerRow: Int, byteCount: Int)? {
    guard width > 0, height > 0 else { return nil }
    let row = width.multipliedReportingOverflow(by: 4)
    guard !row.overflow else { return nil }
    let total = row.partialValue.multipliedReportingOverflow(by: height)
    guard !total.overflow else { return nil }
    return (row.partialValue, total.partialValue)
}

private func adjusted(_ rgb: [Double], for grade: AssetSpec.Grade) -> [Double] {
    switch grade {
    case .chassis:
        return rgb.map { $0 * 0.88 - 0.16 }
    case .wheel:
        return [rgb[0] * 0.40 + 0.66, rgb[1] * 0.40 + 0.65, rgb[2] * 0.38 + 0.62]
    case .center:
        return [rgb[0] * 0.62 + 0.015, rgb[1] * 0.62 + 0.015, rgb[2] * 0.62 + 0.01]
    }
}

private func render(spec: AssetSpec) -> NSImage {
    let scene = SCNScene()
    scene.background.contents = NSColor.clear
    scene.lightingEnvironment.contents = makeEnvironmentTexture()
    scene.lightingEnvironment.intensity = 1.0

    for node in spec.makeNodes() {
        scene.rootNode.addChildNode(node)
    }
    addLighting(to: scene)

    let camera = SCNCamera()
    camera.usesOrthographicProjection = true
    camera.orthographicScale = spec.verticalSpan / 2
    camera.zNear = 0.1
    camera.zFar = 250

    let cameraNode = SCNNode()
    cameraNode.camera = camera
    cameraNode.position = SCNVector3(0, 0, 100)
    scene.rootNode.addChildNode(cameraNode)

    let renderer = SCNRenderer(device: nil, options: nil)
    renderer.scene = scene
    renderer.pointOfView = cameraNode
    renderer.autoenablesDefaultLighting = false
    renderer.isJitteringEnabled = true
    return renderer.snapshot(
        atTime: 0,
        with: spec.size,
        antialiasingMode: .multisampling4X
    )
}

private func makeChassisNodes() -> [SCNNode] {
    let shellPath = NSBezierPath(
        roundedRect: NSRect(x: -26.15, y: -34.9, width: 52.3, height: 69.8),
        xRadius: 4.4,
        yRadius: 4.4
    )
    shellPath.flatness = 0.01
    let shellGeometry = SCNShape(path: shellPath, extrusionDepth: 4.2)
    shellGeometry.chamferRadius = 1.15
    shellGeometry.chamferMode = .both
    shellGeometry.materials = [makeFrontAluminumMaterial()]

    let shell = SCNNode(geometry: shellGeometry)
    shell.position.z = -2.1

    let bezelGeometry = SCNBox(
        width: 43.3,
        height: 32.8,
        length: 0.68,
        chamferRadius: 1.15
    )
    bezelGeometry.chamferSegmentCount = 8
    bezelGeometry.materials = [makeBezelMaterial()]
    let bezel = SCNNode(geometry: bezelGeometry)
    bezel.position = SCNVector3(0, 14.15, 3.36)

    return [shell, bezel]
}

private func makeWheelRingNode() -> SCNNode {
    let geometry = makeAnnulusGeometry(
        outerRadius: 13.7,
        innerRadius: 6.3,
        depth: 0.42,
        bevel: 0.13,
        segments: 128
    )
    geometry.materials = [makeWheelMaterial()]
    return SCNNode(geometry: geometry)
}

private func makeCenterButtonNode() -> SCNNode {
    let geometry = SCNCylinder(radius: 6.2, height: 0.46)
    geometry.radialSegmentCount = 128
    geometry.heightSegmentCount = 1
    geometry.materials = [makeCenterMaterial()]

    let node = SCNNode(geometry: geometry)
    node.eulerAngles.x = .pi / 2
    return node
}

private func makeAnnulusGeometry(
    outerRadius: CGFloat,
    innerRadius: CGFloat,
    depth: CGFloat,
    bevel: CGFloat,
    segments: Int
) -> SCNGeometry {
    typealias Surface = (r0: CGFloat, z0: CGFloat, r1: CGFloat, z1: CGFloat, nr: CGFloat, nz: CGFloat)
    let front = depth / 2
    let back = -front
    let diagonal = CGFloat(1 / sqrt(2.0))
    let surfaces: [Surface] = [
        (outerRadius - bevel, front, outerRadius, front - bevel, diagonal, diagonal),
        (outerRadius, front - bevel, outerRadius, back + bevel, 1, 0),
        (outerRadius, back + bevel, outerRadius - bevel, back, diagonal, -diagonal),
        (outerRadius - bevel, back, innerRadius + bevel, back, 0, -1),
        (innerRadius + bevel, back, innerRadius, back + bevel, -diagonal, -diagonal),
        (innerRadius, back + bevel, innerRadius, front - bevel, -1, 0),
        (innerRadius, front - bevel, innerRadius + bevel, front, -diagonal, diagonal),
        (innerRadius + bevel, front, outerRadius - bevel, front, 0, 1)
    ]

    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var indices: [Int32] = []

    for surface in surfaces {
        for segment in 0..<segments {
            let angle0 = CGFloat(segment) / CGFloat(segments) * 2 * .pi
            let angle1 = CGFloat(segment + 1) / CGFloat(segments) * 2 * .pi
            let base = Int32(vertices.count)

            vertices.append(contentsOf: [
                SCNVector3(surface.r0 * cos(angle0), surface.r0 * sin(angle0), surface.z0),
                SCNVector3(surface.r0 * cos(angle1), surface.r0 * sin(angle1), surface.z0),
                SCNVector3(surface.r1 * cos(angle1), surface.r1 * sin(angle1), surface.z1),
                SCNVector3(surface.r1 * cos(angle0), surface.r1 * sin(angle0), surface.z1)
            ])
            normals.append(contentsOf: [
                SCNVector3(surface.nr * cos(angle0), surface.nr * sin(angle0), surface.nz),
                SCNVector3(surface.nr * cos(angle1), surface.nr * sin(angle1), surface.nz),
                SCNVector3(surface.nr * cos(angle1), surface.nr * sin(angle1), surface.nz),
                SCNVector3(surface.nr * cos(angle0), surface.nr * sin(angle0), surface.nz)
            ])
            indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])
        }
    }

    return SCNGeometry(
        sources: [
            SCNGeometrySource(vertices: vertices),
            SCNGeometrySource(normals: normals)
        ],
        elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
    )
}

private func makeFrontAluminumMaterial() -> SCNMaterial {
    let material = makePBRMaterial(
        color: NSColor(calibratedRed: 0.827, green: 0.831, blue: 0.831, alpha: 1),
        metalness: 0.86,
        roughness: 0.46,
        clearCoat: 0.12,
        clearCoatRoughness: 0.34
    )
    material.diffuse.contents = aluminumTexture
    material.diffuse.wrapS = .repeat
    material.diffuse.wrapT = .repeat
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(1.4, 2.2, 1)
    return material
}

private func makeBezelMaterial() -> SCNMaterial {
    makePBRMaterial(
        color: NSColor(calibratedRed: 0.012, green: 0.016, blue: 0.031, alpha: 1),
        metalness: 0.05,
        roughness: 0.12,
        clearCoat: 0.8,
        clearCoatRoughness: 0.08
    )
}

private func makeWheelMaterial() -> SCNMaterial {
    makePBRMaterial(
        color: NSColor(calibratedRed: 0.945, green: 0.945, blue: 0.937, alpha: 1),
        metalness: 0,
        roughness: 0.72,
        clearCoat: 0.1,
        clearCoatRoughness: 0.66
    )
}

private func makeCenterMaterial() -> SCNMaterial {
    makePBRMaterial(
        color: NSColor(calibratedRed: 0.537, green: 0.541, blue: 0.529, alpha: 1),
        metalness: 0,
        roughness: 0.68,
        clearCoat: 0.08,
        clearCoatRoughness: 0.7
    )
}

private func makePBRMaterial(
    color: NSColor,
    metalness: CGFloat,
    roughness: CGFloat,
    clearCoat: CGFloat,
    clearCoatRoughness: CGFloat
) -> SCNMaterial {
    let material = SCNMaterial()
    material.lightingModel = .physicallyBased
    material.diffuse.contents = color
    material.metalness.contents = metalness
    material.roughness.contents = roughness
    material.clearCoat.contents = clearCoat
    material.clearCoatRoughness.contents = clearCoatRoughness
    material.isDoubleSided = true
    return material
}

private func addLighting(to scene: SCNScene) {
    let ambient = SCNLight()
    ambient.type = .ambient
    ambient.color = NSColor(calibratedWhite: 0.72, alpha: 1)
    ambient.intensity = 260
    let ambientNode = SCNNode()
    ambientNode.light = ambient
    scene.rootNode.addChildNode(ambientNode)

    let key = SCNLight()
    key.type = .directional
    key.color = NSColor(calibratedWhite: 1, alpha: 1)
    key.intensity = 1_050
    let keyNode = SCNNode()
    keyNode.light = key
    keyNode.eulerAngles = SCNVector3(-0.32, -0.42, 0)
    scene.rootNode.addChildNode(keyNode)

    let fill = SCNLight()
    fill.type = .directional
    fill.color = NSColor(calibratedRed: 0.75, green: 0.83, blue: 1, alpha: 1)
    fill.intensity = 430
    let fillNode = SCNNode()
    fillNode.light = fill
    fillNode.eulerAngles = SCNVector3(0.18, 0.55, 0)
    scene.rootNode.addChildNode(fillNode)
}

private func makeEnvironmentTexture() -> NSImage {
    let image = NSImage(size: NSSize(width: 512, height: 256))
    image.lockFocus()
    NSGradient(colors: [
        NSColor(calibratedWhite: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.72, green: 0.78, blue: 0.88, alpha: 1),
        NSColor(calibratedWhite: 0.36, alpha: 1)
    ])?.draw(in: NSRect(x: 0, y: 0, width: 512, height: 256), angle: -18)
    image.unlockFocus()
    return image
}

private func makeBrushedAluminumTexture(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSColor(calibratedRed: 0.827, green: 0.831, blue: 0.835, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    var seed: UInt64 = 112_552
    func random() -> CGFloat {
        seed = (seed &* 1_664_525 &+ 1_013_904_223) & 0xffff_ffff
        return CGFloat(seed) / CGFloat(UInt64(1) << 32)
    }

    for y in 0..<size {
        let delta = (random() - 0.5) * 0.028
        NSColor(calibratedWhite: 0.83 + delta, alpha: 0.16).setFill()
        NSRect(x: 0, y: CGFloat(y), width: CGFloat(size), height: 1).fill()
    }

    for _ in 0..<220 {
        let y = Int(random() * CGFloat(size))
        let length = 80 + random() * 520
        let x = random() * max(1, CGFloat(size) - length)
        let white = random() > 0.5
        NSColor(calibratedWhite: white ? 1 : 0, alpha: 0.07).setFill()
        NSRect(x: x, y: CGFloat(y), width: length, height: 1).fill()
    }

    image.unlockFocus()
    return image
}
