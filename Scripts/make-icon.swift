#!/usr/bin/env swift
// make-icon.swift — generates Resources/AppIcon.icns from CoreGraphics primitives.
// Run from repo root: swift Scripts/make-icon.swift

import AppKit
import CoreGraphics
import Foundation

// MARK: - Color helpers

func cgColor(hex: UInt32) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255.0
    let g = CGFloat((hex >> 8)  & 0xFF) / 255.0
    let b = CGFloat(hex         & 0xFF) / 255.0
    return CGColor(red: r, green: g, blue: b, alpha: 1.0)
}

// MARK: - Master image (1024 × 1024)

let masterSize = 1024

guard let ctx = CGContext(
    data: nil,
    width: masterSize,
    height: masterSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("ERROR: could not create CGContext\n", stderr)
    exit(1)
}

// Transparent background (already zeroed — nothing to clear explicitly)

// Background rounded rect: inset 100 pt, corner radius 180
let bgRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 180, cornerHeight: 180, transform: nil)
ctx.setFillColor(cgColor(hex: 0x1E2230))
ctx.addPath(bgPath)
ctx.fillPath()

// Bars — defined in top-down screen coordinates, then flipped for CG (origin bottom-left).
// CG y = masterSize - screenY - barHeight
struct Bar {
    let screenY: Int   // top-down Y in a 1024-tall canvas
    let width: Int
    let colorHex: UInt32
}

let barHeight = 72
let barCornerRadius: CGFloat = 36
let barX = 232

let bars: [Bar] = [
    Bar(screenY: 280, width: 560, colorHex: 0xA6D189),
    Bar(screenY: 400, width: 360, colorHex: 0xA6D189),
    Bar(screenY: 520, width: 470, colorHex: 0xE5C890),
    Bar(screenY: 640, width: 220, colorHex: 0xA6D189),
]

for bar in bars {
    let cgY = masterSize - bar.screenY - barHeight
    let rect = CGRect(x: barX, y: cgY, width: bar.width, height: barHeight)
    let path = CGPath(roundedRect: rect, cornerWidth: barCornerRadius, cornerHeight: barCornerRadius, transform: nil)
    ctx.setFillColor(cgColor(hex: bar.colorHex))
    ctx.addPath(path)
    ctx.fillPath()
}

guard let masterImage = ctx.makeImage() else {
    fputs("ERROR: could not create master CGImage\n", stderr)
    exit(1)
}

// MARK: - Iconset sizes

struct IconFile {
    let filename: String
    let pixels: Int
}

let iconFiles: [IconFile] = [
    IconFile(filename: "icon_16x16.png",      pixels: 16),
    IconFile(filename: "icon_16x16@2x.png",   pixels: 32),
    IconFile(filename: "icon_32x32.png",      pixels: 32),
    IconFile(filename: "icon_32x32@2x.png",   pixels: 64),
    IconFile(filename: "icon_128x128.png",    pixels: 128),
    IconFile(filename: "icon_128x128@2x.png", pixels: 256),
    IconFile(filename: "icon_256x256.png",    pixels: 256),
    IconFile(filename: "icon_256x256@2x.png", pixels: 512),
    IconFile(filename: "icon_512x512.png",    pixels: 512),
    IconFile(filename: "icon_512x512@2x.png", pixels: 1024),
]

// MARK: - Temp iconset directory

let fm = FileManager.default
let tempDir = fm.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

for icon in iconFiles {
    guard let scaledCtx = CGContext(
        data: nil,
        width: icon.pixels,
        height: icon.pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fputs("ERROR: could not create context for \(icon.filename)\n", stderr)
        exit(1)
    }

    scaledCtx.interpolationQuality = .high
    scaledCtx.draw(masterImage, in: CGRect(x: 0, y: 0, width: icon.pixels, height: icon.pixels))

    guard let scaledImage = scaledCtx.makeImage() else {
        fputs("ERROR: could not create image for \(icon.filename)\n", stderr)
        exit(1)
    }

    let destURL = tempDir.appendingPathComponent(icon.filename)
    let nsImage = NSBitmapImageRep(cgImage: scaledImage)
    guard let pngData = nsImage.representation(using: .png, properties: [:]) else {
        fputs("ERROR: PNG encoding failed for \(icon.filename)\n", stderr)
        exit(1)
    }
    try pngData.write(to: destURL)
}

// MARK: - Run iconutil

let outputPath = "Resources/AppIcon.icns"

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tempDir.path, "-o", outputPath]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("ERROR: iconutil exited with status \(process.terminationStatus)\n", stderr)
    exit(1)
}

// Clean up temp iconset
try fm.removeItem(at: tempDir)

print("Icon written to: \(outputPath)")
