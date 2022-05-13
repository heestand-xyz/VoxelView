#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

#if os(macOS)
public typealias MPView = NSView
public typealias MPViewRepresentable = NSViewRepresentable
#else
public typealias MPView = UIView
public typealias MPViewRepresentable = UIViewRepresentable
#endif

public protocol ViewRepresentable: MPViewRepresentable {
    associatedtype V: MPView
    func makeView(context: Self.Context) -> V
    func updateView(_ view: V, context: Self.Context)
}

#if os(macOS)
extension ViewRepresentable {
    public func makeNSView(context: Self.Context) -> V {
        makeView(context: context)
    }
    public func updateNSView(_ nsView: V, context: Self.Context) {
        updateView(nsView, context: context)
    }
}
#else
extension ViewRepresentable {
    public func makeUIView(context: Self.Context) -> V {
        makeView(context: context)
    }
    public func updateUIView(_ uiView: V, context: Self.Context) {
        updateView(uiView, context: context)
    }
}
#endif
