//
//  SharktopodaAppDelegate.swift
//  Created for Sharktopoda on 11/17/22.
//
//  Apache License 2.0 — See project LICENSE file
//
import AppKit

class SharktopodaAppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    // CxTBD This seems fragile
    UDP.sharktopodaData.mainViewWindow = NSApp.windows.last
  }
}
