//
//  OpenFile.swift
//  Created for Sharktopoda on 10/4/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import SwiftUI

struct OpenFileView: View {

  var body: some View {
    Button("Open file...") {
      let dialog = NSOpenPanel()
      
      dialog.showsResizeIndicator    = true
      dialog.showsHiddenFiles        = false
      dialog.allowsMultipleSelection = false
      dialog.canChooseDirectories    = false
      dialog.isFloatingPanel         = true
      
      guard dialog.runModal() == NSApplication.ModalResponse.OK else { return }

      // CxInc
//      guard let fileUrl = dialog.url else { return }

//      if let error = VideoWindow.open(path: fileUrl.path) as? OpenVideoError {
//        let openAlert = OpenAlert(path: fileUrl.path, error: error)
//        openAlert.show()
//        return
//      }
      return
    }
  }
}

struct OpenFile_Previews: PreviewProvider {
  static var previews: some View {
    OpenFileView()
  }
}
