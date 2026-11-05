// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist



#if os(macOS)
#if hasFeature(InternalImportsByDefault)
public import AppKit
#else
import AppKit
#endif
#else
#if hasFeature(InternalImportsByDefault)
public import UIKit
#else
import UIKit
#endif
#endif

#if canImport(SwiftUI)
#if hasFeature(InternalImportsByDefault)
public import SwiftUI
#else
import SwiftUI
#endif
#endif

// MARK: - Asset Catalogs

public enum PresentationAsset: Sendable {
  public static let accentColor = PresentationColors(name: "AccentColor")
  public enum Icon: Sendable {
  public static let accent = PresentationColors(name: "Icon/Accent")
  }
  public enum Logo: Sendable {
  public enum Muted: Sendable {
    public static let blue = PresentationColors(name: "Logo/Muted/Blue")
      public static let green = PresentationColors(name: "Logo/Muted/Green")
      public static let red = PresentationColors(name: "Logo/Muted/Red")
    }
    public enum Prominent: Sendable {
    public static let blue = PresentationColors(name: "Logo/Prominent/Blue")
      public static let green = PresentationColors(name: "Logo/Prominent/Green")
      public static let red = PresentationColors(name: "Logo/Prominent/Red")
    }
  }
  public enum Surface: Sendable {
  public enum Background: Sendable {
    public static let grouped = PresentationColors(name: "Surface/Background/Grouped")
      public static let primary = PresentationColors(name: "Surface/Background/Primary")
      public static let secondary = PresentationColors(name: "Surface/Background/Secondary")
    }
    public enum Recorder: Sendable {
    public static let muted = PresentationColors(name: "Surface/Recorder/Muted")
      public static let prominent = PresentationColors(name: "Surface/Recorder/Prominent")
    }
  }
  public enum Launch: Sendable {
  public static let background = PresentationImages(name: "Launch/Background")
  }
  public enum Onboarding: Sendable {
  public static let page0 = PresentationImages(name: "Onboarding/Page0")
    public static let page1 = PresentationImages(name: "Onboarding/Page1")
    public static let page2 = PresentationImages(name: "Onboarding/Page2")
    public static let page3 = PresentationImages(name: "Onboarding/Page3")
    public static let page4 = PresentationImages(name: "Onboarding/Page4")
  }
}

// MARK: - Implementation Details

public final class PresentationColors: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  public var color: Color {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIColor: SwiftUI.Color {
      return SwiftUI.Color(asset: self)
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension PresentationColors.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  convenience init?(asset: PresentationColors) {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
  init(asset: PresentationColors) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct PresentationImages: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
  init(asset: PresentationImages) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }

  init(asset: PresentationImages, label: Text) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: PresentationImages) {
    let bundle = Bundle.module
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftformat:enable all
// swiftlint:enable all
